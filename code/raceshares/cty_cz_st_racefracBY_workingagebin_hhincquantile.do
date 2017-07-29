* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

/*** Use quantiles by agebin from national income distribution
	 to generate racial income distributions in each Geo x Age Bin
***/

****************

project, relies_on("$root/code/ado/compute_racefracs.ado")

cap program drop pop_to_frac_dta
program define pop_to_frac_dta

	/*** From a file containing race populations identified by 
		 Geo x Income Quantile x Age Bin (x Another Dimension possibly),
		 
		 1. Collapse away extra dimensions
		 2. Compute race fractions in each quantile within each Geo x Age Bin
		 3. Save the file
	***/


	syntax , geo(varname) qvar(varname) saving(string)

	* Aggregate populations to Geo x Income Quantile x Age Bin
	collapse (sum) pop*, by(`geo' `qvar' agebin)
	
	* Generate quantile race fractions by Geo x Age Bin
	*   (sum of fraction across quantiles = 1 for each race in each Geo x Age Bin cell)
	compute_racefracs, by(`geo' agebin) incomevar(`qvar') racelist(total black asian hispanic other)
	
	* Output
	save13 `"`saving'"', replace
	project, creates(`"`saving'"')
		
end

cap program drop produce_cty_racefractions
program define produce_cty_racefractions

	/*** Generates race fractions by County x Income Quantile x Age Bin
		 by distributing the populations of the 16 income bins into quantiles.
	***/

	syntax using/, nq(integer) qvar(name) saving(string)
	
	project, uses(`"`using'"')
	
	* Load population data
	project, uses("$root/data/derived/raceshares/cty_racepopBY_workingagebin_hhincbin.dta")
	use "$root/data/derived/raceshares/cty_racepopBY_workingagebin_hhincbin.dta", clear
	
	* Generate income quantile dimension
	isid cty agebin hh_inc_bin
	expand `nq'
	bys cty agebin hh_inc_bin: gen byte `qvar'=_n
	order cty agebin `qvar'
	
	* Merge in bin weights for each quantile
	merge m:1 agebin `qvar' hh_inc_bin using `"`using'"', ///
		assert(3) nogen
	
	* Apply bin weights to adjust counts
	foreach var of varlist pop_* {
		replace `var'=`var'*binweight
	}
	drop binweight
	
	* Aggregate to income quantiles; compute race fractions; save
	pop_to_frac_dta, geo(cty) qvar(`qvar') saving(`saving')
	
	*tab `qvar' [aw=pop_total]  // checks that quantiles have correct size
	
end

cap program drop produce_cz_st_racefractions
program define produce_cz_st_racefractions

	/*** Generates race fractions by CZ/State x Income Quantile x Age Bin
		 by aggregating up from county populations.
	***/

	syntax using/, geo(name) qvar(name) saving(string)

	project, uses("$root/data/derived/final_covariates/cty_full_covariates.dta")
	
	* Load county data
	project, uses(`"`using'"')
	use `"`using'"', clear
	drop frac*
	
	* Merge on IDs of higher level geo
	if "`geo'"=="cz" {
		qui merge m:1 cty using "$root/data/derived/final_covariates/cty_full_covariates.dta", ///
			assert(2 3) keepus(cz)
	}
	else if "`geo'"=="st" {
		qui merge m:1 cty using "$root/data/derived/final_covariates/cty_full_covariates.dta", ///
			assert(2 3) keepus(state_id)
		rename state_id st
	}
	else {
		error 198
	}
	assert cty==51560 if _merge==2  // county 51560 was merged into 51005 in 2001
	qui drop if _merge==2
	drop _merge
	
	* Aggregate pop across counties; compute race fractions; save
	pop_to_frac_dta, geo(`geo') qvar(`qvar') saving(`saving')
	
end

	
******************************************
*** Race fractions by County x Age Bin ***
******************************************

produce_cty_racefractions using "$root/data/derived/raceshares/Bin weights on SF3 income bins for local quantiles/binweights_quartiles.dta", ///
	nq(4) qvar(hh_inc_q) ///
	saving("$root/data/derived/raceshares/cty_racefractionsBY_workingagebin_hhincquartile.dta")

produce_cty_racefractions using "$root/data/derived/raceshares/Bin weights on SF3 income bins for local quantiles/binweights_ventiles.dta", ///
	nq(20) qvar(hh_inc_v) ///
	saving("$root/data/derived/raceshares/cty_racefractionsBY_workingagebin_hhincventile.dta")



**************************************
*** Race fractions by CZ x Age Bin ***
**************************************
*****************************************
*** Race fractions by State x Age Bin ***
*****************************************

foreach geo in cz st {

	produce_cz_st_racefractions ///
		using "$root/data/derived/raceshares/cty_racefractionsBY_workingagebin_hhincquartile.dta", ///
		geo(`geo') qvar(hh_inc_q) ///
		saving("$root/data/derived/raceshares/`geo'_racefractionsBY_workingagebin_hhincquartile.dta")
	
	produce_cz_st_racefractions ///
		using "$root/data/derived/raceshares/cty_racefractionsBY_workingagebin_hhincventile.dta", ///
		geo(`geo') qvar(hh_inc_v) ///
		saving("$root/data/derived/raceshares/`geo'_racefractionsBY_workingagebin_hhincventile.dta")
	
}
