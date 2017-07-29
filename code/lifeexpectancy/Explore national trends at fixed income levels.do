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
cap mkdir "${root}/scratch/National LE Trends at fixed income levels or ranks"



********************


*** Estimate National LE Trend by Gender x Income Quartile, controlling for income levels

* Load mean household income level data
project, original("${root}/data/derived/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use "${root}/data/derived/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear
isid gnd pctile age_at_d yod
drop mortrate count

* Keep only incomes at age 40
keep if age_at_d - lag == 40  // income measured at 40
drop age_at_d lag

rename yod year
isid gnd pctile year
rename hh_inc hh_inc40

* Merge in annual national LE
project, original("$derived/le_estimates/national_leBY_year_gnd_hhincpctile.dta") preserve
merge 1:1 gnd pctile year using "$derived/le_estimates/national_leBY_year_gnd_hhincpctile.dta", ///
	assert(3) nogen

* Estimate trends by Gender x Income Quartile; controlling for income level at age 40 in each percentile in each year
g quartile = ceil(pctile/25)
statsby _b _se, by(gnd quartile) clear : reg le_raceadj year hh_inc40, vce(cl year)
keep gnd quartile _b_year _se_year

* Compute upper & lower 95% confidence interval
gen ci_h = _b_year + 1.96*_se_year
gen ci_l = _b_year - 1.96*_se_year
gen ci_str = "(" + string(ci_l,"%03.2f") + ", " + string(ci_h,"%03.2f") + ")"
keep gnd quartile _b_year ci_str

* Reshape wide on quartile
rename (_b_year ci_str) (le_raceadj_tr_q CI_le_raceadj_tr_q)
reshape wide le_raceadj_tr_q CI_le_raceadj_tr_q, i(gnd) j(quartile)

* Output
gsort - gnd
export delim using "${root}/scratch/National LE Trends at fixed income levels or ranks/National LE trend by Quartile Controlling for Income.csv", replace
project, creates("${root}/scratch/National LE Trends at fixed income levels or ranks/National LE trend by Quartile Controlling for Income.csv") preserve

