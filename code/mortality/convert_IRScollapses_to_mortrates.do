* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global raw "${root}/data/raw"
global derived "${root}/data/derived"

* Create required folders
cap mkdir "${root}/data/derived/Mortality Rates"
cap mkdir "${root}/data/derived/Mortality Rates/Fixed income levels"
cap mkdir "${root}/data/derived/Mortality Rates/Individual income"
cap mkdir "${root}/data/derived/Mortality Rates/Cost of Living Adjusted"
cap mkdir "${root}/data/derived/Mortality Rates/With zero incomes"
cap mkdir "${root}/data/derived/Mortality Rates/With all income lags"
cap mkdir "${root}/data/derived/Mortality Sample Counts/"

/*** Load raw IRS collapses, standardize their data structure (which varies
	 because collapses produced at different times using different code at IRS),
	 and convert it into mortality rates.
***/

****************
*** Programs ***
****************

project, original("${root}/code/ado/gen_mortrates2.ado")

cap program drop mask_few_deaths
program define mask_few_deaths
	/*** Mask cells with few deaths or few people.
	***/
	
	syntax, saving(string) [ geo(varname) mincount(integer 50) ]
	
	* Keep only ages 40+
	keep if age_at_d>=40
	
	* Replace cells that have 1 or 2 deaths with 3 deaths.
	gen long deaths = chop(mortrate * count, 10e-6)
	assert deaths==round(deaths)
	label var deaths "Numerator of mortrate"
	
	replace deaths = 3 if inlist(deaths,1,2)
	replace mortrate = deaths/count
	
	* Drop entire county/CZ if any of its cells contains a small count
	if ("`geo'"!="") {
		egen minc = min(count), by(`geo')
		drop if minc<`mincount'
		drop minc
	}
	assert count>=`mincount'
	
	* Output
	order count, last
	compress deaths
	label data "Masked: all obs with 1 or 2 deaths recoded to 3 deaths before computing mortrate"
	save13 `"`saving'"', replace
	project, creates(`"`saving'"')
	
end

*******
*** National, by Gender x Income Percentile x Age x Year
*******

* Load raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta", clear

* Clean up raw data
compress
drop if tax_yr<1999
drop if pctile<1 | mi(pctile)

ren deadby_* deadby_*_Mean
drop agebin_mort  // we already have exact age

label var gnd "Gender"
label var pctile "Household Income Percentile"
label var hh_inc "Mean Household Income"

* Calculate mortality rates
gen_mortrates2 gnd pctile, age(age) year(tax_yr) n(count)

* Output
save13 "${derived}/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta", replace  // formerly irs_mortrates_by_nat_pctile.dta
project, creates("${derived}/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta") preserve

mask_few_deaths, saving("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")


*******
*** National, by Gender x Income Percentile x Age x Year; ALL INCOME LAGS
*******

* Load raw IRS collapse
project, original("${root}/data/raw/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta")
use "${root}/data/raw/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta", clear

* Clean up raw data
compress
drop if tax_yr<1999
drop if pctile<1 | mi(pctile)

ren deadby_* deadby_*_Mean
drop agebin_mort  // we already have exact age

label var gnd "Gender"
label var pctile "Household Income Percentile"
label var hh_inc "Mean Household Income"

* Calculate mortality rates; including all lags at all ages
gen_mortrates2 gnd pctile, age(age) year(tax_yr) n(count) all_lags

* Output
save13 "${derived}/Mortality Rates/With all income lags/national_mortratesBY_gnd_hhincpctile_age_year_WithAllLags.dta", replace
project, creates("${derived}/Mortality Rates/With all income lags/national_mortratesBY_gnd_hhincpctile_age_year_WithAllLags.dta") preserve

mask_few_deaths, saving("${derived}/Mortality Rates/With all income lags/mskd_national_mortratesBY_gnd_hhincpctile_age_year_WithAllLags.dta")

*******
*** National, by Gender x Income Percentile x Age x Year; Fixed income LEVELS
* Each percentile corresponds to the bin whose mean is closest to the 1999 percentile mean
* So bins can be reused for multiple percentile values, but in every year the percentile values are exactly {1,...,100}
*******

* Load raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta", clear

* Clean up raw data
compress
drop if tax_yr<1999
drop if pctile<1 | mi(pctile)

ren deadby_* deadby_*_Mean
drop agebin_mort  // we already have exact age

* In each year, set each percentile to whatever bin has mean income closest to the 1999 mean income for that percentile
isid gnd age pctile tax_yr
expand 100
bys gnd age pctile tax_yr: gen possible_pctile = _n

drop if tax_yr == 1999 & possible_pctile != pctile  // in 1999, pctile:=possible_pctile

gen hh_inc_1999 = hh_inc if tax_yr == 1999
egen income_to_match = mean(hh_inc_1999), by(gnd age possible_pctile)

gen income_diff = abs(hh_inc-income_to_match)
egen min_income_diff = min(income_diff), by(gnd age possible_pctile tax_yr)
keep if income_diff == min_income_diff

isid gnd age possible_pctile tax_yr
drop pctile hh_inc_1999 income_to_match income_diff min_income_diff
rename possible_pctile pctile

* Calculate mortality rates
gen_mortrates2 gnd pctile, age(age) year(tax_yr) n(count)

* Output
save13 "${derived}/Mortality Rates/Fixed income levels/national_mortratesBY_gnd_hhincpctile_age_year_FixedIncomeLevels.dta", replace
project, creates("${derived}/Mortality Rates/Fixed income levels/national_mortratesBY_gnd_hhincpctile_age_year_FixedIncomeLevels.dta")


*******
*** National, by Gender x Income Percentile x Age x Year; Bins in 1999 percentiles
* Each income bin is assigned whatever percentile value had 1999 mean income closest to its own mean income
* So, every bin appears exactly once but percentile values can be reused: in every year, the percentile values are not necessarily {1,...100}
*******

* Load raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta", clear

* Clean up raw data
compress
drop if tax_yr<1999
drop if pctile<1 | mi(pctile)

ren deadby_* deadby_*_Mean
drop agebin_mort  // we already have exact age

* In each year, set each bin to whatever percentile had 1999 mean income closest to its own mean income
isid gnd age pctile tax_yr
expand 100
bys gnd age pctile tax_yr: gen possible_pctile = _n

drop if tax_yr == 1999 & possible_pctile != pctile  // in 1999, pctile:=possible_pctile

gen hh_inc_1999 = hh_inc if tax_yr == 1999
egen income_to_match = mean(hh_inc_1999), by(gnd age possible_pctile)

gen income_diff = abs(hh_inc-income_to_match)
egen min_income_diff = min(income_diff), by(gnd age pctile tax_yr)
keep if income_diff == min_income_diff

rename possible_pctile pctile1999
isid gnd age pctile tax_yr
drop hh_inc_1999 income_to_match income_diff min_income_diff

* Calculate mortality rates
gen_mortrates2 gnd pctile pctile1999, age(age) year(tax_yr) n(count)

isid gnd pctile age_at_d yod
drop pctile
rename pctile1999 pctile
collapse (mean) mortrate (rawsum) count [w=count], by(gnd pctile age_at_d yod)
compress

* Output
save13 "${derived}/Mortality Rates/Fixed income levels/national_mortratesBY_gnd_hhincpctile_age_year_BinsIn1999Percentiles.dta", replace
project, creates("${derived}/Mortality Rates/Fixed income levels/national_mortratesBY_gnd_hhincpctile_age_year_BinsIn1999Percentiles.dta")


*******
*** National, by Gender x INDIVIDUAL Income Percentile x Age x Year
*******

* Load raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_indv_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_indv_mskd.dta", clear

* Clean up raw data
compress
drop if tax_yr<1999
drop if indv_earn_pctile<1 | mi(indv_earn_pctile)

rename GND_IND gnd

rename X_FREQ_ count
assert indv_earn_N == count
drop indv_earn_N

forvalues i=16/18 {
	assert deadby_`i'_Mean==0 & deadby_`i'_N==0
	replace deadby_`i'_Mean=.
}

forvalues i=1/18 {
	assert inlist(deadby_`i'_N,count,0)
	assert deadby_`i'_Mean==. if deadby_`i'_N==0
	drop deadby_`i'_N
}

label var gnd "Gender"
label var indv_earn_pctile "Individual Income Percentile"
label var indv_earn_Mean "Mean Individual Income"

* Calculate mortality rates
gen_mortrates2 gnd indv_earn_pctile, age(age) year(tax_yr) n(count)

* Output
save13 "${derived}/Mortality Rates/Individual income/national_mortratesBY_gnd_INDincpctile_age_year.dta", replace  // formerly irs_mortrates_by_nat_indvpctile.dta
project, creates("${derived}/Mortality Rates/Individual income/national_mortratesBY_gnd_INDincpctile_age_year.dta") preserve

mask_few_deaths, saving("${derived}/Mortality Rates/Individual income/mskd_national_mortratesBY_gnd_INDincpctile_age_year.dta")


*******
*** CZ, by Gender x Income Quartile x Age x Year
*******

* Load raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_cz_byyearageq_new_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_cz_byyearageq_new_mskd.dta", clear

* Clean up raw data
drop if mi(cz)
drop if tax_yr<1999
drop if mi(hh_inc_q)
assert inlist(hh_inc_q,0,1,2,3,4)  // include zeros
compress

keep if inlist(GND_IND,"M","F")
rename GND_IND gnd

rename X_FREQ_ count
assert hh_inc_N == count
drop hh_inc_N

forvalues i=1/18 {
	assert inlist(deadby_`i'_N,count,0)
	assert deadby_`i'_Mean==. if deadby_`i'_N==0
	drop deadby_`i'_N
}

rename hh_inc_Mean hh_inc

label var cz "Commuting Zone"
label var gnd "Gender"
label var hh_inc_q "Household Income Quartile"
label var hh_inc "Mean Household Income"


* Calculate mortality rates
gen_mortrates2 cz gnd hh_inc_q, age(age) year(tax_yr) n(count)

rename count count_double
gen long count=round(count_double)
label var count "`:variable label count_double'"
assert reldif(count,count_double)<10e-10
drop count_double

* Output with zero incomes
save13 "${derived}/Mortality Rates/With zero incomes/cz_with0mortratesBY_gnd_hhincquartile_age_year.dta", replace
project, creates("${derived}/Mortality Rates/With zero incomes/cz_with0mortratesBY_gnd_hhincquartile_age_year.dta") preserve

* Output without zero incomes
drop if hh_inc_q==0

save13 "${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta", replace  // formerly irs_mortrates_by_cz_incq_long_raw.dta
project, creates("${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta") preserve

drop mortrate hh_inc
save13 "${derived}/Mortality Sample Counts/cz_mortcountsBY_gnd_hhincquartile_age_year.dta", replace
project, creates("${derived}/Mortality Sample Counts/cz_mortcountsBY_gnd_hhincquartile_age_year.dta")


*******
*** CZ, by Gender x Income Quartile x Age x Year: Cost of Living adjusted
*******

* Load raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_coli_byczq_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_coli_byczq_mskd.dta", clear

* Clean up raw data
drop if mi(cz)
drop if tax_yr<1999
drop if hh_inc_coli_q < 1 | mi(hh_inc_coli_q)
compress

assert inlist(gnd,"M","F")

ren deadby_* deadby_*_Mean
gen byte deadby_1_Mean=0

* Calculate mortality rates
gen_mortrates2 cz gnd hh_inc_coli_q, age(age) year(tax_yr) n(count)

rename count count_double
gen long count=round(count_double)
label var count "`:variable label count_double'"
assert reldif(count,count_double)<10e-10
drop count_double

* Output
save13 "${derived}/Mortality Rates/Cost of Living Adjusted/cz_mortratesBY_gnd_hhincquartile_age_year_COLIadjusted.dta", replace  // formerly irs_mortrates_by_cz_incq_coli_long_raw.dta
project, creates("${derived}/Mortality Rates/Cost of Living Adjusted/cz_mortratesBY_gnd_hhincquartile_age_year_COLIadjusted.dta")


*******
*** CZ, by Gender x Income PERCENTILE x Age BIN x Year
*******

* Get list of CZs with large populations
project, original("${raw}/Covariate Data/cz_characteristics.dta")
use cz pop2000 using "${raw}/Covariate Data/cz_characteristics.dta", clear
compress
keep if pop2000>250e3 & !mi(pop2000)
keep cz

* Load large CZs from raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_cz_byyear_new_mskd.dta") preserve
merge 1:m cz using "${raw}/Mortality Collapses/mort_ad_v6_cz_byyear_new_mskd.dta", ///
	keep(3) nogen
	
* Clean up raw data
assert !mi(cz)
drop if tax_yr<1999
drop if hh_inc_pctile < 1 | mi(hh_inc_pctile)
compress

drop if GND_IND=="U"
assert inlist(GND_IND,"M","F")
rename GND_IND gnd

rename X_FREQ_ count
assert hh_inc_N == count
drop hh_inc_N

forvalues i=1/18 {
	assert inlist(deadby_`i'_N,count,0)
	assert deadby_`i'_Mean==. if deadby_`i'_N==0
	drop deadby_`i'_N
}

rename hh_inc_Mean hh_inc

* Set age as the center of the agebin in which **income is measured**
/*
	agebin_mort is currently set as the lowest age at which **mortality**
	is measured in the agebin, assuming income is measured with a 2-year lag.
	
	So we are given the following agebins:
		- Inc: 33-37, 2-year mort: 35-39
		- Inc: 38-42, 2-year mort: 40-44
		- Inc: 43-47, 2-year mort: 45-49
		- Inc: 48-52, 2-year mort: 50-54
		- Inc: 53-57, 2-year mort: 55-59
		- Inc: 58-61, 2-year mort: 60-63 = 4 YEAR BIN
		
	For all the 5-year agebins, the center age at which income is measured is
	the bottom age at which 2-year mortality is measured.
	
	But for the 4-year agebin, the center age at which income is measured is 59.5.
	
	ALSO, for this last bin we'll extend our mortality measures past a
	2-year income lag to get into retired ages.  So deadby_2 corresponds to a
	center age of 61.5, deadby_3 is a center age of 62.5, etc.
 
*/
replace agebin_mort=59.5 if agebin_mort==60
rename agebin_mort agebin

* Calculate mortality rates
gen_mortrates2 cz gnd hh_inc_pctile, age(agebin) year(tax_yr) n(count)

* Since last agebin is 4 years, only measure them once every 4 years
* to avoid double-counting the same deaths
keep if mod(lag,4) == 2

* Output
save13 "${derived}/Mortality Rates/czLARGE_mortratesBY_gnd_hhincpctile_agebin_year.dta", replace  // formerly not saved
project, creates("${derived}/Mortality Rates/czLARGE_mortratesBY_gnd_hhincpctile_agebin_year.dta") preserve

* Output counts by ventile instead of percentile
drop mortrate hh_inc

isid cz gnd hh_inc_pctile age_at_d yod
g byte hh_inc_v = ceil(hh_inc_pctile/5)
collapse (rawsum) count, by(cz gnd hh_inc_v age_at_d yod lag) fast

compress
save13 "${derived}/Mortality Sample Counts/czLARGE_mortcountsBY_gnd_hhincventile_agebin_year.dta", replace
project, creates("${derived}/Mortality Sample Counts/czLARGE_mortcountsBY_gnd_hhincventile_agebin_year.dta")


*******
*** County, by Gender x Income Quartile x Age x Year
*******

* Load raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_cty_byyearageq_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_cty_byyearageq_mskd.dta", clear

* Clean up raw data
drop if mi(cty)
drop if tax_yr<1999
drop if hh_inc_q < 1 | mi(hh_inc_q)
compress

assert inlist(GND_IND,"M","F")
rename GND_IND gnd

rename deadby_* deadby_*_Mean

label var cty "County FIPS Code"
label var gnd "Gender"
label var hh_inc_q "Household Income Quartile"
label var hh_inc "Mean Household Income"

* Calculate mortality rates
gen_mortrates2 cty gnd hh_inc_q, age(age) year(tax_yr) n(count)

* Output
save13 "${derived}/Mortality Rates/cty_mortratesBY_gnd_hhincquartile_age_year.dta", replace  // formerly irs_mortrates_by_cty_incq_long_raw.dta
project, creates("${derived}/Mortality Rates/cty_mortratesBY_gnd_hhincquartile_age_year.dta") preserve

drop mortrate hh_inc
save13 "${derived}/Mortality Sample Counts/cty_mortcountsBY_gnd_hhincquartile_age_year.dta", replace
project, creates("${derived}/Mortality Sample Counts/cty_mortcountsBY_gnd_hhincquartile_age_year.dta")



*******
*** State, by Gender x Income Quartile x Age x Year
*******

* Load raw IRS collapse
project, original("${raw}/Mortality Collapses/mort_ad_v6_st_new_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_st_new_mskd.dta", clear

* Clean up raw data
drop if mi(st)
drop if tax_yr<1999
drop if hh_inc_q < 1 | mi(hh_inc_q)
compress

assert inlist(GND_IND,"M","F")
rename GND_IND gnd

rename deadby_* deadby_*_Mean
gen byte deadby_1_Mean=0

label var st "State FIPS Code"
label var gnd "Gender"
label var hh_inc_q "Household Income Quartile"
label var hh_inc "Mean Household Income"

* Calculate mortality rates
gen_mortrates2 st gnd hh_inc_q, age(age) year(tax_yr) n(count)

rename count count_double
gen long count=round(count_double)
label var count "`:variable label count_double'"
assert reldif(count,count_double)<10e-8
drop count_double

* Output
save13 "${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta", replace  // formerly irs_mortrates_by_state_incq_long_raw.dta
project, creates("${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta") preserve

drop mortrate hh_inc
save13 "${derived}/Mortality Sample Counts/st_mortcountsBY_gnd_hhincquartile_age_year.dta", replace
project, creates("${derived}/Mortality Sample Counts/st_mortcountsBY_gnd_hhincquartile_age_year.dta")
