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
cap mkdir "${root}/data/derived/le_estimates_stderr"
cap mkdir "${root}/data/derived/le_trends_stderr"

/*** Generates bootstrap standard errors and confidence intervals for LE levels and trends,
	using point estimates and bootstraps which have already been calculated.
***/

****************
*** Programs ***
****************

project, original("${root}/code/ado/compute_ci_percentiles.ado")

cap program drop generate_bootstrap_confidence
program define generate_bootstrap_confidence
	
	syntax, by(namelist) bootstrap_est(string) point_est(string) saving(string)
	
	project, uses(`"`bootstrap_est'"')
	project, uses(`"`point_est'"')

	* Compute bootstrap 2.5th and 97.5th percentiles
	use `"`bootstrap_est'"', clear
	
	isid `by' sample_num
	compute_ci_percentiles le*, by(`by') gen(p)
	
	rename le_* le_*_p
	replace p=p*10
	qui ds le*
	reshape wide `r(varlist)', i(`by') j(p)
	rename (*_p25 *_p975) (p25_* p975_*)
	
	tempfile bootstrap_percentiles
	save `bootstrap_percentiles'
	
	* Compute bootstrap mean and SD
	use `"`bootstrap_est'"', clear
	
	foreach var of varlist le* {
		local mean_le `mean_le' mean_`var'=`var'
		local sd_le `sd_le' sd_`var'=`var'
	}
	
	collapse (mean) `mean_le' (sd) `sd_le', by(`by')
	
	* Merge in point estimates
	merge 1:1 `by' using `"`point_est'"', assert(3) nogen
	order `by' le_*
	
	* Merge in bootstrap percentiles
	merge 1:1 `by' using `bootstrap_percentiles', assert(3) nogen
	
	* Generate bootstrap CIs
	foreach v of varlist le_* {
		gen ciL_`v' = 2*`v' - p975_`v'
		gen ciH_`v' = 2*`v' - p25_`v'
	}
	
	* Output
	save13 `"`saving'"', replace
	project, creates(`"`saving'"')
	
end

*************************************
*** LE Levels: bootstrap SDs, CIs ***
*************************************

*** National LE levels, by Gender x Income Percentile
generate_bootstrap_confidence, by(gnd pctile) ///
	point_est("$derived/le_estimates/national_leBY_gnd_hhincpctile.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile.dta") ///
	saving("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta")  // formerly national_LE_SE.dta

*** National LE levels, by Gender x Income Percentile x Year
generate_bootstrap_confidence, by(gnd pctile year) ///
	point_est("$derived/le_estimates/national_leBY_year_gnd_hhincpctile.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile_year.dta") ///
	saving("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile_year.dta")


*** CZ LE levels, by Gender (positive income only)
generate_bootstrap_confidence, by(cz gnd) ///
	point_est("$derived/le_estimates/cz_leBY_gnd.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd.dta") ///
	saving("$derived/le_estimates_stderr/cz_SEleBY_gnd.dta")
	
*** CZ LE levels, by Gender x Income Quartile
generate_bootstrap_confidence, by(cz gnd hh_inc_q) ///
	point_est("$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile.dta")  // formerly cz_le_quartile_SE.dta

*** CZ LE levels, by Gender x Income Quartile x Year
generate_bootstrap_confidence, by(cz gnd hh_inc_q year) ///
	point_est("$derived/le_estimates/cz_leBY_year_gnd_hhincquartile.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile_year.dta") ///
	saving("$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile_year.dta")  // formerly cz_le_quartile_yod_SE.dta

*** CZ LE levels, by Gender x Income Ventile
generate_bootstrap_confidence, by(cz gnd hh_inc_v) ///
	point_est("$derived/le_estimates/Largest CZs by ventile/cz_leBY_gnd_hhincventile.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincventile.dta") ///
	saving("$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincventile.dta")


*** County LE levels, by Gender x Income Quartile
generate_bootstrap_confidence, by(cty gnd hh_inc_q) ///
	point_est("$derived/le_estimates/cty_leBY_gnd_hhincquartile.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_cty_leBY_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates_stderr/cty_SEleBY_gnd_hhincquartile.dta")  // formerly cty_le_quartile_SE.dta


*** State LE levels, by Gender x Income Quartile
generate_bootstrap_confidence, by(st gnd hh_inc_q) ///
	point_est("$derived/le_estimates/st_leBY_gnd_hhincquartile.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_st_leBY_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates_stderr/st_SEleBY_gnd_hhincquartile.dta")
	
*** State LE levels, by Gender x Income Quartile x Year
generate_bootstrap_confidence, by(st gnd hh_inc_q year) ///
	point_est("$derived/le_estimates/st_leBY_year_gnd_hhincquartile.dta") ///
	bootstrap_est("$derived/le_estimates/bootstrap/bootstrap_st_leBY_gnd_hhincquartile_year.dta") ///
	saving("$derived/le_estimates_stderr/st_SEleBY_gnd_hhincquartile_year.dta")  // formerly st_le_quartile_yod_SE.dta


*************************************
*** LE Trends: bootstrap SDs, CIs ***
*************************************

*** CZ LE trends, by Gender x Income Quartile
generate_bootstrap_confidence, by(cz gnd hh_inc_q) ///
	point_est("${derived}/le_trends/cz_letrendsBY_gnd_hhincquartile.dta") ///
	bootstrap_est("${derived}/le_trends/bootstrap/bootstrap_cz_letrendsBY_gnd_hhincquartile.dta") ///
	saving("$derived/le_trends_stderr/cz_SEletrendsBY_gnd_hhincquartile.dta")  // formerly quartile_slopes_bycz_SE.dta

*** State LE trends, by Gender x Income Quartile
generate_bootstrap_confidence, by(st gnd hh_inc_q) ///
	point_est("${derived}/le_trends/st_letrendsBY_gnd_hhincquartile.dta") ///
	bootstrap_est("${derived}/le_trends/bootstrap/bootstrap_st_letrendsBY_gnd_hhincquartile.dta") ///
	saving("$derived/le_trends_stderr/st_SEletrendsBY_gnd_hhincquartile.dta")  // formerly quartile_slopes_byst_SE.dta

