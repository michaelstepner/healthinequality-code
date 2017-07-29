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
cap mkdir "${root}/data/derived/le_trends"
cap mkdir "${root}/data/derived/le_trends/bootstrap"


/*** Compute life expectancy trends estimates.
***/


****************
*** Programs ***
****************

cap program drop compute_LE_trends
program define compute_LE_trends

	syntax using/, by(namelist) saving(string)
	
	project, uses(`"`using'"')
	
	* Calculate trends
	foreach var in le_raceadj le_agg {
	
		use `"`using'"', clear
		
		isid `by' year
		fastregby `var' year, by(`by') clear
		rename _b* `var'_b*
		
		tempfile trend_`var'
		qui save `trend_`var''
	}
	qui merge 1:1 `by' using `trend_le_raceadj', assert(3) nogen
		
	* Output
	label data "Annual trend in unadjusted and race-adjusted LE"
	sort `by'
	save13 `"`saving'"', replace
	project, creates(`"`saving'"')
	
end


***************************************
*** Compute Trends: Point Estimates ***
***************************************

* CZ Trends by Gender x Income Quartile
compute_LE_trends using "$derived/le_estimates/cz_leBY_year_gnd_hhincquartile.dta", ///
	by(cz gnd hh_inc_q) ///
	saving("${derived}/le_trends/cz_letrendsBY_gnd_hhincquartile.dta")


* State Trends by Gender x Income Quartile
compute_LE_trends using "$derived/le_estimates/st_leBY_year_gnd_hhincquartile.dta", ///
	by(st gnd hh_inc_q) ///
	saving("${derived}/le_trends/st_letrendsBY_gnd_hhincquartile.dta")


************************************
*** Compute Trends: Bootstrapped ***
************************************

* CZ Trends by Gender x Income Quartile
compute_LE_trends using "$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile_year.dta", ///
	by(cz gnd hh_inc_q sample_num) ///
	saving("${derived}/le_trends/bootstrap/bootstrap_cz_letrendsBY_gnd_hhincquartile.dta")


* State Trends by Gender x Income Quartile
compute_LE_trends using "$derived/le_estimates/bootstrap/bootstrap_st_leBY_gnd_hhincquartile_year.dta", ///
	by(st gnd hh_inc_q sample_num) ///
	saving("${derived}/le_trends/bootstrap/bootstrap_st_letrendsBY_gnd_hhincquartile.dta")
