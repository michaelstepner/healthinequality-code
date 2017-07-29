program define estimate_gompertz2

	/*** Calculate Gompertz parameters from mortality rates by age, within by-groups.
	
		 Use Julia to estimate GLM regressions quickly if it is configured,
		 otherwise use -statsby- in Stata.
	
	***/

	syntax varlist(min=1), age(varname) mort(varname) [ n(varname) ///
		collapsefrom(varlist) vce(name) ///
		type(string) ///
		cz_popmsk(integer 0) cty_popmsk(integer 0) force ]
	local group `varlist'
	if !inlist("`type'","mle","ols") {
		di as error "type() must be 'mle' or 'ols'"
		exit 198
	}
	if ("`n'"=="") {
		if ("`type'"=="mle") {
			di as error "n() required with type(mle)"
			exit 198
		}
		if ("`collapsefrom'"!="") {
			di as error "n() required with collapsefrom()"
			exit 198
		}
	}
	
	*** Collapse dataset if requested
	if ("`collapsefrom'"!="") {
		isid `collapsefrom' `age'
		collapse (mean) `mort' (rawsum) `n' [aw=`n'], by(`group' `age') fast
		qui compress
	}
	else isid `group' `age'

	*** Check dataset has expected structure
	assert inrange(`age', 40, 76)  // only expected ages for this project
	if ("`n'"!="") {
		cap confirm long variable `n'  // integer number of individuals
		if (_rc==7) confirm int variable `n'
		else confirm long variable `n'
		assert reldif(`mort'*`n', round(`mort'*`n')) < 2e-6  // integer number of deaths
	}
		
	*** Mask Gompertz parameters for small CZs or counties
	if (`cz_popmsk'!=0) { 
		project, original("${root}/data/raw/Covariate Data/cz_characteristics.dta") preserve
		merge m:1 cz using "${root}/data/raw/Covariate Data/cz_characteristics.dta", keepusing(pop2000) ///
			assert(2 3) keep(3) nogen
		drop if pop2000 < `cz_popmsk'
		drop pop2000
	}

	if (`cty_popmsk'!=0) {
		project, original("${root}/data/raw/Covariate Data/cty_covariates.dta") preserve
		merge m:1 cty using "${root}/data/raw/Covariate Data/cty_covariates.dta", keepus(cty_pop2000) ///
			assert(2 3) keep(3) nogen
		drop if cty_pop2000 < `cty_popmsk'
		drop cty_pop2000
	}
	
	*** Estimate Gompertz parameters for each group
	if ("`type'"=="mle") {
	
		* "Reshape" from mortality rates into counts of deaths and non-deaths
		/* After reshape:
			- `mort' variable = 0 or 1.
			- `n' variable = count of deaths or non-deaths
			
		   Note:
			- Already confirmed unique by `group' `age' above.
			- Already confirmed number of deaths is an integer above.
		
		*/
		quietly {
			expand 2
			bys `group' `age': replace `n' = cond(_n == 1, round(`mort'*`n'), round(`n' - `mort'*`n'))
			by `group' `age': replace `mort' = (_n == 1)
		}
		recast byte `mort'
	
		* Estimate Gompertz parameters (coefficients and covariance matrix)
		if ("$juliapath"=="") {
			statsby A_slope_1 = r(A_slope_1) A_int_1 = r(A_int_1) A_int_2 = r(A_int_2) gomp_int = r(gomp_int) gomp_slope = r(gomp_slope), ///
				by(`group') clear: mle_gomp_est, age(`age') mort(`mort') n(`n') vce(`vce')
				
			sort `group'
		}
		else fastregby_gompMLE_julia `mort' `age', count(`n') by(`group') vce(`vce') clear `force'
		
	}
	else if ("`type'"=="ols") {
	
		* Generate log mortality rates
		qui count if `mort'==0
		if (r(N)>0) di as error "warning: `r(N)'/`=_N' mortality rates are 0, so their log mortality rates are missing."
		
		tempvar l_mort
		gen `l_mort' = log(`mort')
		
		* Estimate Gompertz parameters (coefficients only)
		fastregby `l_mort' `age', by(`group') clear
		rename (_b_cons _b_`age') (gomp_int gomp_slope)
	
	}
	
	* Check for groups that had errors, prevent disclosure of missingness
	qui count if mi(gomp_int, gomp_slope)
	if (r(N)>0 & "`force'"=="force") {
		qui drop if mi(gomp_int, gomp_slope)
		di as error "warning: dropped `r(N)' group(s) that had an error in Gompertz estimation"
	}
	else if r(N)>0 {
		di as error "`r(N)' group(s) had an error in Gompertz estimation. use 'force' option to drop groups with errors."
		exit 2000
	}

end

