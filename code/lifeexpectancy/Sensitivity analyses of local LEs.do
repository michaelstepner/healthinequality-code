* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global derived "${root}/data/derived"

* Create required folders
cap mkdir "${root}/scratch/Sensitivity analyses of local LE"

/*** Check the correlation between various versions of the
		CZ x Gender x Income Quartile estimates and our baseline
		race-adjusted estimates.
***/


*****************
*** Load data ***
*****************

* Load various life expectancies
project, original("$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta")
use "$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta", clear
keep cz gnd hh_inc_q le_agg le_raceadj
rename le_raceadj le_Baseline
rename le_agg le_NoRaceAdj
order cz gnd hh_inc_q le_Baseline

project, original("$derived/le_estimates/Expected life years until 77/cz_leBY_gnd_hhincquartile_GompertzTo77.dta") preserve
merge 1:1 cz gnd hh_inc_q using "$derived/le_estimates/Expected life years until 77/cz_leBY_gnd_hhincquartile_GompertzTo77.dta", ///
	assert(3) nogen keepusing(le_raceadj)
rename le_raceadj le_LYuntil77

project, original("$derived/le_estimates/Gompertz extrapolation to 100/cz_leBY_gnd_hhincquartile_GompertzTo100.dta") preserve
merge 1:1 cz gnd hh_inc_q using "$derived/le_estimates/Gompertz extrapolation to 100/cz_leBY_gnd_hhincquartile_GompertzTo100.dta", ///
	assert(3) nogen keepusing(le_raceadj)
rename le_raceadj le_GompertzTo100

project, original("$derived/le_estimates/OLS Gompertz estimation/cz_leBY_gnd_hhincquartile_OLS.dta") preserve
merge 1:1 cz gnd hh_inc_q using "$derived/le_estimates/OLS Gompertz estimation/cz_leBY_gnd_hhincquartile_OLS.dta", ///
	assert(3) nogen keepusing(le_raceadj)
rename le_raceadj le_OLS

project, original("$derived/le_estimates/OLS Gompertz estimation/cz_leBY_gnd_hhincquartile_OLSIncomeControl.dta") preserve
merge 1:1 cz gnd hh_inc_q using "$derived/le_estimates/OLS Gompertz estimation/cz_leBY_gnd_hhincquartile_OLSIncomeControl.dta", ///
	assert(1 3) nogen keepusing(le_raceadj) // many CZs don't have income controlled LEs due to missing a percentile of data
rename le_raceadj le_IncomeControl

project, original("$derived/le_estimates/Cost of Living Adjusted/cz_leBY_gnd_hhincquartile_COLIadjusted.dta") preserve
merge 1:1 cz gnd hh_inc_q using "$derived/le_estimates/Cost of Living Adjusted/cz_leBY_gnd_hhincquartile_COLIadjusted.dta", ///
	assert(3) nogen keepusing(le_raceadj)
rename le_raceadj le_COLI

* Load population counts
project, original("${derived}/final_covariates/cz_pop.dta") preserve
merge m:1 cz using "${derived}/final_covariates/cz_pop.dta", nogen assert(2 3) keep(3)

* Check structure
assert !mi(cz,gnd,hh_inc_q,pop2000) & inrange(hh_inc_q,1,4)

************************************
*** Count number of observations ***
************************************

preserve

* Collapse to counts of CZs
collapse (count) le*, by(gnd hh_inc_q)

* Ensure that counts are constant across gender and income quartile
foreach var of varlist le* {
	assert `var'==`var'[_n-1] if _n>2
}

* Collapse dataset of counts to gender
collapse (mean) le*, by(gnd)

* Output
rename le* czN_le*
export delim using "${root}/scratch/Sensitivity analyses of local LE/Counts of CZs in each sensitivity correlation.csv", replace
project, creates("${root}/scratch/Sensitivity analyses of local LE/Counts of CZs in each sensitivity correlation.csv")

restore

****************************
*** Compute correlations ***
****************************

* Store correlations in matrices
tempname corrM corrF tempcorr
forvalues q=1/4 {

	foreach g in "M" "F" {
		
		corr le_Baseline le_NoRaceAdj le_LYuntil77 le_GompertzTo100 le_OLS le_IncomeControl le_COLI ///
			if gnd=="`g'" & hh_inc_q==`q' [w=pop2000]
		
		matrix `tempcorr'=r(C)
		matrix `corr`g''=nullmat(`corr`g'') \ (`tempcorr'[1,2..7])
	}
	
}

* Store correlations in dataset
clear

svmat `corrM', names(col)
rename le* M_le*

svmat `corrF', names(col)
rename le* F_le*

gen hh_inc_q=_n
order hh_inc_q

* Reformat correlations to 3 decimals
foreach var of varlist M_le* F_le* {
	gen rho_`var'=string(`var',"%9.3f")
}

* Export tables of correlations
export delim hh_inc_q rho_M* ///
	using "${root}/scratch/Sensitivity analyses of local LE/CZ correlations of baseline raceadj LE with alternatives - Male.csv", ///
	replace
	
export delim hh_inc_q rho_F* ///
	using "${root}/scratch/Sensitivity analyses of local LE/CZ correlations of baseline raceadj LE with alternatives - Female.csv", ///
	replace
	
project, creates("${root}/scratch/Sensitivity analyses of local LE/CZ correlations of baseline raceadj LE with alternatives - Male.csv")
project, creates("${root}/scratch/Sensitivity analyses of local LE/CZ correlations of baseline raceadj LE with alternatives - Female.csv")
