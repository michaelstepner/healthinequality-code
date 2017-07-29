program define generate_le_with_raceadj

	/* Given:
		0. A list of By-Vars, which are the level at which LE will be calculated.
		1. Race shares file identified by By-Vars x Age OR Age Bin
		2. Gompertz parameters file identified by By-Vars (x Bootstrap Sample Num)
		3. Race shifters file identified by Gender (x Bootstrap Sample Num)
		4. Reference race share file identified by Gender
		5. Uniform mortality rates from CDC, identified by Gender x Age
		
	   Computes and saves a dataset with:
		- Unadjusted life expectancy
		- Race-adjusted life expectancy
		- Race-specific life expectancies
		
	   This program follows the procedure described in the Appendix section
	   "Race and Ethnicity Adjustments", "Step 3: Constructing Race-Specific
	   Mortality Rates and Life Expectancies".
	   
	   Options:
	   
		- The minimum age for the Gompertz relationship is always set to be 40.
		
			- maxage_gomp_parameterfit() specifies the maximum age at which the
			  Gompertz parameters were estimated. This controls the set of ages
			  at which we generate predicted mortality rates, for the aggregate
			  group and then for whites. We then fit a new Gompertz curve to the
			  white predicted values. The default maximum age is 76.
			  
			- maxage_gomp_LEextrap() specifies the maximum age at which the
			  Gompertz parameters will be used for calculating life expectancies.
			  After that age, we switch to using the external data source of
			  mortality rates specified in cdc_mortrates().
			  The default maximum age is 90.
			
		- 'continuous' specifies whether the Gompertz integral will be done using
			an analytic continuous integral or a discrete trapezoidal approximation
			(we use the discrete method as our baseline)
			
		- 'returngompertz' saves a dataset of Gompertz parameters for each race,
			without computing the associated life expectancies.
		  
		- 'original' specifies that datasets loaded were not created in this
			project build, and is used when this program is called outside
			the data generation pipeline.
			
		- 'gomporiginal' specifies that the Gompertz parameters were not created
			in this	project build.
	*/

	syntax , by(namelist) [bootstrap_samplevar(name)] ///
		raceshares(string) gompparameters(string) saving(string) ///
		[ raceshifters(string) reference_raceshares(string) cdc_mortrates(string) ///
		maxage_gomp_parameterfit(integer 76) maxage_gomp_LEextrap(integer 90) ///
		safe continuous returngompertz ///
		original gomporiginal ]
	if ("`original'"=="") local uses uses
	else local uses original

	*** Use default datasets if unspecified
	if (`"`raceshifters'"'=="") local raceshifters "${root}/data/derived/NLMS/raceshifters/raceshifters_v5A_BYsex.dta"
	if (`"`reference_raceshares'"'=="") local reference_raceshares "${root}/data/derived/raceshares/national_2000age40_racesharesBY_gnd.dta"
	if (`"`cdc_mortrates'"'=="") local cdc_mortrates "${root}/data/derived/Mortality Rates/CDC-SSA Life Table/national_CDC_SSA_mortratesBY_gnd_age.dta"
		
	*** Split LE task into multiple parts if processing large bootstrap Gompertz parameter file (otherwise might exceed available memory)
	if ("`bootstrap_samplevar'"!="" & "${splitobs}"!="" & !regexm(`"`: subinstr local gompparameters "\" "/", all'"',`"^`=subinstr(c(tmpdir),"\","/",.)'"')) {
	
		if !regexm(`"`: subinstr local gompparameters "\" "/", all'"',`"^`=subinstr(c(tmpdir),"\","/",.)'"') project, `uses'(`"`gompparameters'"')
		describe using `"`gompparameters'"'
		local split = ceil(`r(N)'/${splitobs})
		
		if (`split'>1) {
		
			di "Automatically splitting LE calculation into `split' parts."

			* Determine how many values of bootstrap_samplevar to include in each split
			use `bootstrap_samplevar' using `"`gompparameters'"', clear
			sum `bootstrap_samplevar', meanonly
			local sample_increment = ceil(r(max)/`split')
			
			* Generate LEs for each *split* of Gompertz parameters
			local splitcounter=0
			forvalues o=1(`sample_increment')`r(max)' {
			
				local ++splitcounter
				di "{bf}Estimating bootstrap LE by '`by'': split `splitcounter'/`split'"
				
				use if inrange(`bootstrap_samplevar', `o', `=`o'+`sample_increment'-1') ///
					using `"`gompparameters'"'
					
				tempfile gomp`splitcounter'
				save `gomp`splitcounter''
				
				tempfile leresults`splitcounter'
				generate_le_with_raceadj, by(`by') bootstrap_samplevar(`bootstrap_samplevar') ///
					raceshares(`raceshares') reference_raceshares(`reference_raceshares') ///
					raceshifters(`raceshifters') cdc_mortrates(`cdc_mortrates') ///
					gompparameters(`gomp`splitcounter'') saving(`leresults`splitcounter'') ///
					maxage_gomp_parameterfit(`maxage_gomp_parameterfit') maxage_gomp_LEextrap(`maxage_gomp_LEextrap') ///
					`safe' `continuous' `returngompertz' `original'
	
			}
			
			* Append results together
			clear
			forvalues s=1/`split' {
				append using `leresults`s''
			}
			
			* Output
			sort `by' `bootstrap_samplevar'
			if ("`safe'"=="safe") isid `by' `bootstrap_samplevar'
			save13 `"`saving'"', replace
			project, creates(`"`saving'"')
			
			exit  // otherwise will re-run a second time without split()!
			
		}

	}
		
	*** Project build commands
	project, original("$root/code/ado/fastregby.ado")
	project, `uses'(`"`raceshares'"')
	if !regexm(`"`: subinstr local gompparameters "\" "/", all'"',`"^`=subinstr(c(tmpdir),"\","/",.)'"') {
		if ("`gomporiginal'"=="gomporiginal") project, original(`"`gompparameters'"')
		else project, `uses'(`"`gompparameters'"')
	}
	project, `uses'(`"`raceshifters'"')
	project, `uses'(`"`reference_raceshares'"')
	if !regexm(`"`: subinstr local cdc_mortrates "\" "/", all'"',`"^`=subinstr(c(tmpdir),"\","/",.)'"') project, `uses'(`"`cdc_mortrates'"')
	
	*** Load uniform mortality rates to matrices
	use if age>=`maxage_gomp_LEextrap' using `"`cdc_mortrates'"', clear
	sort gnd age
	
	tempname uniform_mort_M uniform_mort_F
	mkmat cdc_mort if gnd=="M", matrix(`uniform_mort_M')
	mkmat cdc_mort if gnd=="F", matrix(`uniform_mort_F')
	
	*** Load Data 
	load_racesh_gomppar_gompshift, by(`by') bootstrap_samplevar(`bootstrap_samplevar') ///
		raceshares(`raceshares') gompparameters(`gompparameters') raceshifters(`raceshifters') ///
		maxage_gomp_parameterfit(`maxage_gomp_parameterfit') `safe'
	
	*** Estimate racial Gompertz parameters
	estimate_gomppar_allraces, by(`by') bootstrap_samplevar(`bootstrap_samplevar') ///
		gompparameters(`gompparameters') raceshifters(`raceshifters')
		
	if ("`returngompertz'"=="returngompertz") {
		* Save dataset of racial Gompertz parameters, without calculating LE
		save13 `"`saving'"', replace
		if !regexm(`"`: subinstr local saving "\" "/", all'"',`"^`=subinstr(c(tmpdir),"\","/",.)'"') project, creates(`"`saving'"')
		exit
	}

	*** Compute expected age at death at age 40
	foreach r in "agg" "w" "b" "a" "h" {
	
		rename (gomp_int_`r' gomp_slope_`r') (gomp_int gomp_slope)
	
		if ("`continuous'"=="continuous") {
			replace gomp_int = gomp_int - 0.5 * gomp_slope  // since "age 40" in IRS estimation is actually age [40,41)
			gen_gomp_lifeyears_cont, startage(40) endage(`maxage_gomp_LEextrap')
			gen surv_endgomp = exp( 1 / gomp_slope * ( exp(gomp_int + gomp_slope * 40) - exp(gomp_int + gomp_slope * `maxage_gomp_LEextrap') ) )
		}
		else mata: gen_gomp_lifeyears_disc(40, `maxage_gomp_LEextrap')		
		
		mata: gen_uniform_lifeyears(`maxage_gomp_LEextrap', "`uniform_mort_M'", "`uniform_mort_F'")
	
		gen le_`r' = 40 + expectedLY_gomp + expectedLY_uniform
		drop gomp_int gomp_slope expectedLY_gomp surv_endgomp expectedLY_uniform
		
	}
	
	*** Compute race-adjusted expected age at death
	merge m:1 gnd using `"`reference_raceshares'"', ///
		keepusing(raceshare_*) ///
		assert(match) nogen

	gen le_raceadj =  raceshare_black * le_b ///
					+ raceshare_asian * le_a ///
					+ raceshare_hispanic * le_h ///
					+ raceshare_other * le_w
	drop raceshare*
	
	*** Output
	sort `by' `bootstrap_samplevar'
	if ("`safe'"=="safe") isid `by' `bootstrap_samplevar'
	
	save13 `"`saving'"', replace
	if !regexm(`"`: subinstr local saving "\" "/", all'"',`"^`=subinstr(c(tmpdir),"\","/",.)'"') {  // not a temporary file
		project, creates(`"`saving'"')
	}

end

program load_racesh_gomppar_gompshift
	/*** Given 3 datasets:
			- Race shares: `by' x Age OR Age Bin
			- Gompertz parameters: `by' (x Bootstrap Sample Num)
			- Gompertz shifters: gnd (x Bootstrap Sample Num)
			
		 Creates a dataset identified at the level of
			By-Vars x Age (x Bootstrap Sample Num),
			with ages 40 to `maxage_gomp_parameterfit' (often 76),
			containing Gompertz parameters, Gompertz shifters and race shares.
			
		 The resulting dataset is ready to be used to estimate racial mortality rates.
	***/

	syntax , by(namelist) [ bootstrap_samplevar(name) ] ///
		raceshares(string) gompparameters(string) raceshifters(string) ///
		maxage_gomp_parameterfit(integer) [ safe ]

	
	*** Load race shares
	use `"`raceshares'"', clear
	
	* Check age type; duplicate within agebin to get exact age if necessary
	novarabbrev {
	
		cap confirm var age
		
		if (_rc!=0) {  // no age, check for agebin
			cap confirm var agebin
			if (_rc==0) {  // agebin exists
				* Convert agebin to exact age
				assert floor(agebin/5)==agebin/5  // 5-year age bins
				expand 5
				bys `by' agebin: gen age=agebin+_n-1
				order `by' age
				drop agebin
			}
			else {  // neither age nor agebin exists
				di as error "Race shares dataset must contain age or agebin variable"
				exit 1
			}
		}
		
	}
	
	if ("`safe'"=="safe") isid `by' age
	keep `by' age raceshare_*
		
	* Keep only ages at which the Gompertz parameters were estimated (default: until 76)
	keep if inrange(age,40,`maxage_gomp_parameterfit')
	qui tab age
	assert r(r)==`=`maxage_gomp_parameterfit'-40+1'  // all ages 40 to max are present
	
	*** Merge in Gompertz parameters
	if ("`bootstrap_samplevar'"=="") {
		merge m:1 `by' using `"`gompparameters'"', ///
			keepusing(gomp_int gomp_slope) ///
			assert(1 3) keep(3) nogen  // What isn't matched? Local areas that are censored from Gompertz estimation due to small pop
	}
	else {
		/*  Race shares identifed by: By-Vars x Age
			Gompertz parameters identified by: By-Vars x Sample-Var
			
			We'll form all the pairwise combinations of age with the
			bootstrap sample var, so each sample gets the full set of ages.
		*/
	
		joinby `by' using `"`gompparameters'"'
		order `bootstrap_samplevar'
	}

	*** Merge in Gompertz shifters and reset intercept from 40 to 0
	merge m:1 gnd `bootstrap_samplevar' using `"`raceshifters'"', ///
		assert(2 3) keep(3) nogen keepusing(diff_gomp_*)  // _merge==2 comes from $splitobs option which means master doesn't have all bootstrap_samplevar values

	foreach var of varlist diff_gomp_int_* {
		replace `var' = `var' - 40 * `=subinstr("`var'","int","slope",1)'
	}
	
end

program define estimate_gomppar_allraces
	/*** Input:
			- Loaded dataset with Gompertz parameters, Gompertz shifters and race shares,
			  identified by: By-Vars x Age (x Bootstrap Sample Num) 
			  
		 Output:
			- Loaded dataset with Gompertz parameters for aggregate and for each race,
			  identified by: By-Vars (x Bootstrap Sample Num)
	***/
	
	syntax , by(namelist) [bootstrap_samplevar(name)] ///
		gompparameters(string) raceshifters(string)

	***********************************************
	*** Estimate Gompertz parameters for whites ***
	***********************************************
	
	* Generate predicted aggregate mortality rates
	gen double agg_mort = exp(gomp_int + gomp_slope * age)
	assert agg_mort>0  // otherwise log(agg_mort) is missing. mortality rates larger than 1 fine in this step, since we're just shifting Gompertz parameters.
		
	* Generate white mortality rates
	gen double log_whitemort = log(agg_mort) ///
								- raceshare_black * (diff_gomp_int_black + diff_gomp_slope_black * age) ///
								- raceshare_asian * (diff_gomp_int_asian + diff_gomp_slope_asian * age) ///
								- raceshare_hispanic * (diff_gomp_int_hisp + diff_gomp_slope_hisp * age)
	
	* Estimate white Gompertz parameters
	fastregby log_whitemort age, by(`by' `bootstrap_samplevar') clear
	rename (_b_cons _b_age) (gomp_int_w gomp_slope_w)

	***************************************************
	*** Calculate Gompertz parameters for each race ***
	***************************************************
	
	* Merge in aggregate Gompertz parameters
	merge 1:1 `by' `bootstrap_samplevar' using `"`gompparameters'"', ///
		keepusing(gomp_int gomp_slope) ///
		keep(match) nogen
	/* The unmatched groups are the same as in previous Gompertz parameter merge
	   in -merge_racesh_gomppar_gompshift- since no by-groups are dropped since then.
	*/
	rename (gomp_int gomp_slope) (gomp_int_agg gomp_slope_agg)
	
	* Merge in Gompertz shifters and reset intercept from 40 to 0
	merge m:1 gnd `bootstrap_samplevar' using `"`raceshifters'"', ///
		assert(2 3) keep(3) nogen keepusing(diff_gomp_*)  // _merge==2 comes from $splitobs option which means master doesn't have all bootstrap_samplevar values

	foreach var of varlist diff_gomp_int_* {
		replace `var'=`var' - 40 * `=subinstr("`var'","int","slope",1)'
	}
		
	* Generate Gompertz parameters for other races
	foreach r in black asian hisp {
		gen gomp_int_`=substr("`r'",1,1)' = gomp_int_w + diff_gomp_int_`r'
		gen gomp_slope_`=substr("`r'",1,1)' = gomp_slope_w + diff_gomp_slope_`r'
		drop diff_gomp_int_`r' diff_gomp_slope_`r'
	}

end

program gen_gomp_lifeyears_cont
	/*** Inputs:
			- loaded dataset with an observation for each set of Gompertz parameters,
				with those parameters stored as "gomp_int" and "gomp_slope"
			- startage and endage, to compute expected life years between those ages
				for a person alive at startage
				
		 Output:
			- add a variable "expectedLY_gomp" to loaded dataset
				with expected life years between startage and endage
				for a person alive at startage
	***/

	syntax , startage(integer) endage(integer)

    tempfile gomppar lifeyears
    export delim gomp_int gomp_slope using `gomppar', novarnames delimiter(",")
    !python "$root/code/ado/gompertz_LYbetween.py" --startage `startage' --endage `endage' -i `gomppar' -o `lifeyears'
    
    preserve
    import delim using `lifeyears', clear
    rename v1 expectedLY_gomp
    label var expectedLY_gomp "Expected Life Years Between `startage' and `endage'"
    save `lifeyears', replace
    restore

    merge 1:1 _n using `lifeyears', assert(3) nogen
	confirm numeric var expectedLY_gomp
    
end

version 13.1
mata:
mata set matastrict on

real scalar gompertz_surv(real scalar a, real scalar b, real scalar startage, real scalar age) {
	// Inputs:
	//	- Gompertz intercept and slope
	//	- startage: age at which survival = 1
	//	- age: age at which survival will be calculated
	//
	// Returns probability of survival to specified age.

	return( exp(1 / b * ( exp(a + b * startage) - exp(a + b * age) ) ) )

}

void gen_uniform_lifeyears(real scalar startage, string scalar uniform_mort_M, string scalar uniform_mort_F) {
	// Inputs:
	//  - a loaded dataset with variables: gnd, surv_endgomp
	//  - the age at which we start using uniform mortality rates for expected life years
	//	- Stata matrices containing uniform mortality rates for men and women,
	//		starting at [startage, startage+1) and ending at an advanced age no one lives past
	// Output:
	//  - adds a variable "expectedLY_uniform" to the loaded dataset,
	//	  containing the expected number of life years from "startage" onward
	//		- using "surv_endgomp" as the survival rate to the startage
	//		- using the uniform mortality rates to calculate survival past "startage"
	//		- using the trapezoidal rule to approximate the area under the survival curve
	
	// Create variable to contain expected life year results
	real scalar lycol
	lycol = st_addvar("float", "expectedLY_uniform")
	
	// Get column indices
	real scalar survcol
	real scalar gndcol
	survcol = st_varindex("surv_endgomp")
	gndcol = st_varindex("gnd")
	
	// Get uniform survival rates
	real colvector survM
	real colvector survF
	real scalar survrows
	survM = 1 :- st_matrix(uniform_mort_M)
	survF = 1 :- st_matrix(uniform_mort_F)
	survrows = rows(survM)
	assert(rows(survF)==survrows)

	// Initialize looped variables
	real colvector survivalcurve
	survivalcurve = J(survrows,1,.)
	
	real scalar obs
	real scalar surv_init
	real scalar i
	
	// For each observation, compute and store expected life years
	for (obs=1; obs<=st_nobs(); obs++) {
	
		// Fetch survival at "startage"
		surv_init = _st_data(obs,survcol)
		
		// Compute survival at {startage+1, ..., startage+survrows} using uniform mortality rates
		if (_st_sdata(obs,gndcol)=="M") {
			survivalcurve[1] = surv_init * survM[1]
			for (i=2; i<=survrows; i++) {
				survivalcurve[i] = survivalcurve[i-1] * survM[i]
			}
		}
		else {  // gnd=="F"
			survivalcurve[1] = surv_init * survF[1]
			for (i=2; i<=survrows; i++) {
				survivalcurve[i] = survivalcurve[i-1] * survF[i]
			}
		}
		
		// Compute life expectancy using trapezoidal rule
		_st_store(obs, lycol, surv_init / 2 + sum(survivalcurve) )
		
	}
	
}

void gen_gomp_lifeyears_disc(real scalar startage, real scalar endage) {
	// Inputs:
	//	- loaded dataset with an observation for each set of Gompertz parameters,
	//		with those parameters stored as "gomp_int" and "gomp_slope"
	//	- startage and endage, to compute expected life years between those ages
	//		for a person alive at startage			
	// Output:
	//	- add a variable "expectedLY_gomp" to loaded dataset
	//	  with expected life years between startage and endage
	//	  for a person alive at startage
	//		- using Euler method to construct survival curve from discrete mortality rates
	//		- using the trapezoidal rule to approximate the area under the survival curve
	//	- add a variable "surv_endgomp" to loaded dataset
	//	  with probability of survival to endage

	
	// Create variables to contain results
	real scalar lycol
	lycol = st_addvar("float", "expectedLY_gomp")
	real scalar survcol
	survcol = st_addvar("float", "surv_endgomp")
	
	// Get column indices
	real scalar intcol
	real scalar slopecol
	intcol = st_varindex("gomp_int")
	slopecol = st_varindex("gomp_slope")
	
	// Create vector of ages
	real colvector ages
	real scalar agerows
	ages = range(startage+1, endage, 1)
	agerows = rows(ages)
	
	// Initialize looped variables
	real colvector survivalcurve
	survivalcurve = J(agerows,1,.)
	
	real scalar a  // Gompertz intercept
	real scalar b  // Gompertz slope
	
	real scalar obs
	real scalar i
	
	// For each observation, compute and store expected life years
	for (obs=1; obs<=st_nobs(); obs++) {
	
		a = _st_data(obs,intcol)
		b = _st_data(obs,slopecol)
		
		// Compute survival at {startage+1, ..., endage} using Gompertz mortality rates
		survivalcurve[1] = 1 - min( (1, exp( a + b * startage )) )
		for (i=2; i<agerows; i++) {
			survivalcurve[i] = survivalcurve[i-1] * ( 1 - min( (1, exp( a + b * ages[i-1] )) ) )
		}
		survivalcurve[agerows] = survivalcurve[agerows-1] * ( 1 - min( (1, exp( a + b * ages[agerows-1] )) ) ) / 2  // trapezoid places half weight on last point
		
		// Compute life expectancy using trapezoidal rule
		_st_store(obs, lycol, 1/2 + sum(survivalcurve) )
		
		// Store survival at endage
		_st_store(obs, survcol, survivalcurve[agerows]*2 )
		
	}
	
}

end
