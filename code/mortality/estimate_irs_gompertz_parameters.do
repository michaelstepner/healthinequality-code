* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global raw_data "${root}/data/raw"
global derived "${root}/data/derived"

* Check for Julia configuration
cap confirm file "${root}/code/set_julia.do"
if (_rc==0) include "${root}/code/set_julia.do"

* Create required folders
cap mkdir "${root}/data/derived/Gompertz Parameters"
cap mkdir "${root}/data/derived/Gompertz Parameters/Fixed income levels"
cap mkdir "${root}/data/derived/Gompertz Parameters/OLS"
cap mkdir "${root}/data/derived/Gompertz Parameters/Individual income"
cap mkdir "${root}/data/derived/Gompertz Parameters/Cost of Living Adjusted"
cap mkdir "${root}/data/derived/Gompertz Parameters/With zero incomes"

* Add ado files to project
project, original("${root}/code/ado/estimate_gompertz2.ado")
project, original("${root}/code/ado/mle_gomp_est.ado")
project, original("${root}/code/ado/fastregby_gompMLE_julia.ado")
project, original("${root}/code/ado/estimate_gompertz.jl")
project, original("${root}/code/ado/fastregby.ado")

************************
******* National *******
************************

*******
*** National, by Gender x Income Percentile
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta")
use "${derived}/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta", clear
keep if age_at_d >= 40

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 gnd pctile, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(gnd pctile age_at_d yod) type(mle)

* Output
save13 "${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta", replace // formerly national_gomp_race_pctile.dta
project, creates("${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta")


*******
*** National, by Gender x Income Percentile x Year
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta")
use "${derived}/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta", clear
rename yod year
keep if age_at_d >= 40
keep if age_at_d <= 63  // keep only ages that appear in all years 2001-2014
keep gnd pctile year age_at_d mortrate count  // keep only vars needed for Gompertz estimation

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 gnd pctile year, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	type(mle)

* Output
save13 "${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile_year.dta", replace // formerly national_gomp_race_pctile_year.dta
project, creates("${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile_year.dta")


*******
*** National, by Gender x Income Percentile; Individual Income
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/Individual income/national_mortratesBY_gnd_INDincpctile_age_year.dta")
use "${derived}/Mortality Rates/Individual income/national_mortratesBY_gnd_INDincpctile_age_year.dta", clear
keep if age_at_d >= 40

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 gnd indv_earn_pctile, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(gnd indv_earn_pctile age_at_d yod) type(mle)

* Output
save13 "${derived}/Gompertz Parameters/Individual income/national_gompBY_gnd_INDincpctile.dta", replace // formerly national_gomp_race_indvpctile.dta
project, creates("${derived}/Gompertz Parameters/Individual income/national_gompBY_gnd_INDincpctile.dta")


*******
*** National, by Gender x Income Percentile x Year; Fixed income levels
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/Fixed income levels/national_mortratesBY_gnd_hhincpctile_age_year_FixedIncomeLevels.dta")
use "${derived}/Mortality Rates/Fixed income levels/national_mortratesBY_gnd_hhincpctile_age_year_FixedIncomeLevels.dta", clear
rename yod year
keep if age_at_d >= 40
keep if age_at_d <= 63  // keep only ages that appear in all years 2001-2014
keep gnd pctile year age_at_d mortrate count  // keep only vars needed for Gompertz estimation

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 gnd pctile year, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	type(mle)

* Output
save13 "${derived}/Gompertz Parameters/Fixed income levels/national_gompBY_gnd_hhincpctile_year_FixedIncomeLevels.dta", replace // formerly fixed_income_national_gomp_race_pctile_year.dta
project, creates("${derived}/Gompertz Parameters/Fixed income levels/national_gompBY_gnd_hhincpctile_year_FixedIncomeLevels.dta")


*******
*** National, by Gender x Income Percentile x Year; Bins in 1999 percentiles
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/Fixed income levels/national_mortratesBY_gnd_hhincpctile_age_year_BinsIn1999Percentiles.dta")
use "${derived}/Mortality Rates/Fixed income levels/national_mortratesBY_gnd_hhincpctile_age_year_BinsIn1999Percentiles.dta", clear
rename yod year
keep if age_at_d >= 40
keep if age_at_d <= 63  // keep only ages that appear in all years 2001-2014
keep gnd pctile year age_at_d mortrate count  // keep only vars needed for Gompertz estimation

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 gnd pctile year, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	type(mle)

* Output
save13 "${derived}/Gompertz Parameters/Fixed income levels/national_gompBY_gnd_hhincpctile_year_BinsIn1999Percentiles.dta", replace // formerly national_gomp_race_pctile_year_BinsIn1999Percentiles.dta
project, creates("${derived}/Gompertz Parameters/Fixed income levels/national_gompBY_gnd_hhincpctile_year_BinsIn1999Percentiles.dta")


******************************
******* Commuting Zone *******
******************************

*******
*** CZ, by Gender (positive AND ZERO incomes)
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/With zero incomes/cz_with0mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/With zero incomes/cz_with0mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d>=40
assert inlist(hh_inc_q, 0, 1, 2, 3, 4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cz gnd, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(cz gnd hh_inc_q yod age_at_d) ///
	cz_popmsk(25000) type(mle)

* Output
save13 "${derived}/Gompertz Parameters/With zero incomes/cz_gompBY_gnd_With0Inc.dta", replace
project, creates("${derived}/Gompertz Parameters/With zero incomes/cz_gompBY_gnd_With0Inc.dta")


*******
*** CZ, by Gender (positive income only)
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d>=40
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cz gnd, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(cz gnd hh_inc_q yod age_at_d) ///
	cz_popmsk(25000) type(mle)

* Output
save13 "${derived}/Gompertz Parameters/cz_gompBY_gnd.dta", replace // formerly cz_gomp_race.dta
project, creates("${derived}/Gompertz Parameters/cz_gompBY_gnd.dta")


*******
*** CZ, by Gender x Income Quartile
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d>=40
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cz gnd hh_inc_q, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(cz gnd hh_inc_q yod age_at_d) ///
	cz_popmsk(25000) type(mle)

* Output
save13 "${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincquartile.dta", replace // formerly cz_gomp_race_quartile.dta
project, creates("${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincquartile.dta")


*******
*** CZ, by Gender x Income Quartile x Year
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta", clear
rename yod year
keep if age_at_d >= 40
keep if age_at_d <= 63  // keep only ages that appear in all years 2001-2014
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cz gnd hh_inc_q year, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	cz_popmsk(590000) type(mle)  // 590k population corresponds to top 100 CZs

* Output
save13 "${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincquartile_year.dta", replace // formerly cz_gomp_race_quartile_year.dta
project, creates("${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincquartile_year.dta")


*******
*** CZ, by Gender x Income Quartile: OLS Gompertz estimation
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d>=40
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cz gnd hh_inc_q, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(cz gnd hh_inc_q yod age_at_d) ///
	cz_popmsk(25000) type(ols)

* Output
save13 "${derived}/Gompertz Parameters/OLS/cz_gompBY_gnd_hhincquartile_OLS.dta", replace // formerly cz_gomp_race_quartile_OLS.dta
project, creates("${derived}/Gompertz Parameters/OLS/cz_gompBY_gnd_hhincquartile_OLS.dta")


*******
*** CZ, by Gender x Income Quartile: Income Control, OLS Gompertz estimation
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/czLARGE_mortratesBY_gnd_hhincpctile_agebin_year.dta")
use "${derived}/Mortality Rates/czLARGE_mortratesBY_gnd_hhincpctile_agebin_year.dta", clear
keep if age_at_d >= 40

* Collapse over years
isid cz gnd hh_inc_pctile age_at_d yod
collapse (mean) mortrate [w=count], by(cz gnd hh_inc_pctile age_at_d) fast
compress

* Determine appropriate weights, in order to weight each percentile equally
gen weight = 1 if age_at_d <= 63  // panel has equal weight on each percentile up until retirement, by the construction of the percentiles
bys cz gnd hh_inc_pctile (age_at_d): replace weight = weight[_n-1] * (1-mortrate[_n-1])^(age_at_d-age_at_d[_n-1]) if age_at_d > 63  // reduce the weight in each percentile based on the mortality rates
assert !mi(weight)

* Collapse from percentiles to quartiles, using weights to control for income
g byte hh_inc_q = ceil(hh_inc_pctile/25)
isid cz gnd hh_inc_pctile age_at_d
collapse (mean) mortrate (count) num_pctiles=hh_inc_pctile [aw=weight], by(cz gnd hh_inc_q age_at_d)

* Drop any CZ that was missing a percentile observation (for any gender & quartile)
egen min_num_pctiles = min(num_pctiles), by(cz)
tab cz if min_num_pctiles<25
drop if min_num_pctiles<25
drop num_pctiles min_num_pctiles

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cz gnd hh_inc_q, gnd(gnd) age(age_at_d) mort(mortrate) ///
	cz_popmsk(25000) type(ols)
	
* Output
save13 "${derived}/Gompertz Parameters/OLS/cz_gompBY_gnd_hhincquartile_IncomeControl.dta", replace // formerly cz_gomp_race_quartile_IncomeControl.dta
project, creates("${derived}/Gompertz Parameters/OLS/cz_gompBY_gnd_hhincquartile_IncomeControl.dta")


*******
*** CZ, by Gender x Income Ventile
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/czLARGE_mortratesBY_gnd_hhincpctile_agebin_year.dta")
use "${derived}/Mortality Rates/czLARGE_mortratesBY_gnd_hhincpctile_agebin_year.dta", clear
keep if age_at_d >= 40
	
* Collapse away year, and collapse percentiles -> ventiles
isid cz gnd hh_inc_pctile age_at_d yod
g byte hh_inc_v = ceil(hh_inc_pctile/5)
collapse (mean) mortrate (rawsum) count [w=count], by(cz gnd hh_inc_v age_at_d) fast
compress

* Use estimate_gompertz.ado to calculate Gompertz parameters from mortality rates
estimate_gompertz2 cz gnd hh_inc_v, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	type(mle) /*mortality rates file already masked*/
	
* Output
isid cz gnd hh_inc_v
sort cz gnd hh_inc_v
save13 "${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincventile.dta", replace  // formerly cz_gomp_race_ventile.dta
project, creates("${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincventile.dta")


*******
*** CZ, by Gender x Income Quartile; Cost of Living Adjusted
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/Cost of Living Adjusted/cz_mortratesBY_gnd_hhincquartile_age_year_COLIadjusted.dta")
use "${derived}/Mortality Rates/Cost of Living Adjusted/cz_mortratesBY_gnd_hhincquartile_age_year_COLIadjusted.dta", clear
keep if age_at_d>=40

rename hh_inc_coli_q hh_inc_q
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cz gnd hh_inc_q, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(cz gnd hh_inc_q yod age_at_d) ///
	cz_popmsk(25000) type(mle)

* Output
save13 "${derived}/Gompertz Parameters/Cost of Living Adjusted/cz_gompBY_gnd_hhincquartile_COLIadjusted.dta", replace // formerly cz_gomp_race_quartile_year_coli.dta
project, creates("${derived}/Gompertz Parameters/Cost of Living Adjusted/cz_gompBY_gnd_hhincquartile_COLIadjusted.dta")


**********************
******* County *******
**********************

*******
*** County, by Gender (positive income only)
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/cty_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/cty_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d>=40
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cty gnd, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(cty gnd hh_inc_q yod age_at_d) ///
	cty_popmsk(25000) type(mle)

* Output
save13 "${derived}/Gompertz Parameters/cty_gompBY_gnd.dta", replace // formerly cty_gomp_race.dta
project, creates("${derived}/Gompertz Parameters/cty_gompBY_gnd.dta")


*******
*** County, by Gender x Income Quartile
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/cty_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/cty_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d>=40
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 cty gnd hh_inc_q, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(cty gnd hh_inc_q yod age_at_d) ///
	cty_popmsk(25000) type(mle)

* Output
save13 "${derived}/Gompertz Parameters/cty_gompBY_gnd_hhincquartile.dta", replace // formerly cty_gomp_race_quartile.dta
project, creates("${derived}/Gompertz Parameters/cty_gompBY_gnd_hhincquartile.dta")

	
*********************
******* State *******
*********************

*******
*** State, by Gender (positive income only)
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d >= 40
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 st gnd, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(st gnd hh_inc_q yod age_at_d) ///
	type(mle)

* Output
save13 "${derived}/Gompertz Parameters/st_gompBY_gnd.dta", replace
project, creates("${derived}/Gompertz Parameters/st_gompBY_gnd.dta")


*******
*** State, by Gender x Income Quartile
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d >= 40
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 st gnd hh_inc_q, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	collapsefrom(st gnd hh_inc_q yod age_at_d) ///
	type(mle)

* Output
save13 "${derived}/Gompertz Parameters/st_gompBY_gnd_hhincquartile.dta", replace
project, creates("${derived}/Gompertz Parameters/st_gompBY_gnd_hhincquartile.dta")


*******
*** State, by Gender x Income Quartile x Year
*******

* Load mortality rates
project, uses("${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta", clear
rename yod year
keep if age_at_d >= 40
keep if age_at_d <= 63  // keep only ages that appear in all years 2001-2014
assert inrange(hh_inc_q, 1 ,4)

* Calculate Gompertz parameters from mortality rates
estimate_gompertz2 st gnd hh_inc_q year, gnd(gnd) age(age_at_d) mort(mortrate) n(count) ///
	type(mle)

* Output
save13 "${derived}/Gompertz Parameters/st_gompBY_gnd_hhincquartile_year.dta", replace // formerly st_gomp_race_quartile_year.dta
project, creates("${derived}/Gompertz Parameters/st_gompBY_gnd_hhincquartile_year.dta")

