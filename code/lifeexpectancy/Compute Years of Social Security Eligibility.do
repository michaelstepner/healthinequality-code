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
cap mkdir "$root/scratch/Medicare and Social Security Eligibility"

/*** Compute the expected number of years lived over age 65 for 40 year-olds
	 by gender and income percentile, then report the p100-p1 gap.
***/

********

project, original("${root}/code/ado/generate_le_with_raceadj.ado")


* Calculate national Gompertz parameters by Gender x Income Percentile x Race
tempfile racegomp
generate_le_with_raceadj, returngompertz by(gnd pctile) ///
	original ///
	gompparameters("$derived/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta") ///
	raceshares("$derived/raceshares/national_racesharesBY_age_gnd_hhincpctile.dta") ///
	saving(`racegomp')
	
use `racegomp', clear
keep if pctile == 1 | pctile == 100


* Add age dimension, for ages 40-120
isid gnd pctile
expand 81
gen int age=.
bys gnd pctile: replace age = _n + 39

* Merge in CDC mortality rates
project, original("${root}/data/derived/Mortality Rates/CDC-SSA Life Table/national_CDC_SSA_mortratesBY_gnd_age.dta") preserve
merge m:1 gnd age using "${root}/data/derived/Mortality Rates/CDC-SSA Life Table/national_CDC_SSA_mortratesBY_gnd_age.dta", ///
	keepusing(cdc_mort) ///
	assert(1 2 3) keep(1 3)  // ages<40 are _merge==2, age 120 is _merge==1
assert age==120 if _merge==1
drop _merge

* Generate survival curves
isid gnd pctile age
foreach r in "agg" "w" "b" "a" "h" {

	gen surv_`r' = 1 if age==40
	bys gnd pctile (age): replace surv_`r' = surv_`r'[_n-1] * ///
		(1 - exp(gomp_int_`r' + gomp_slope_`r' * age[_n-1]) ) if inrange(age,41,90)  // mortality rates are mortality between [x,x+1)
	replace surv_`r' = surv_`r'[_n-1] * (1 - cdc_mort[_n-1]) if age>90
	
}

* Compute expected number of years lived above 65 (for a person alive at 40)
keep if age>=65
foreach var of varlist surv_* {
	replace `var' = `var'/2 if age==65  // trapezoidal approximation for the integral
}
collapse (sum) surv_*, by(gnd pctile)
rename surv* ly65*

* Race-adjust expected years above 65
project, original("${root}/data/derived/raceshares/national_2000age40_racesharesBY_gnd.dta") preserve
merge m:1 gnd using "${root}/data/derived/raceshares/national_2000age40_racesharesBY_gnd.dta", ///
	keepusing(raceshare_*) ///
	assert(match) nogen

gen ly65_raceadj =  raceshare_black * ly65_b ///
				+ raceshare_asian * ly65_a ///
				+ raceshare_hispanic * ly65_h ///
				+ raceshare_other * ly65_w
drop raceshare*

* Reshape wide on percentile
rename ly65* ly65*_p
ds ly65*
reshape wide `r(varlist)', i(gnd) j(pctile)

* Generate p100-p1 gap
gen ly65_raceadj_gap = ly65_raceadj_p100 - ly65_raceadj_p1

* Output
assert gnd==cond(_n==1,"F","M")

scalarout using "${root}/scratch/Medicare and Social Security Eligibility/Years Lived Above 65.csv", replace ///
	id("Expected Years Lived Above 65: p100 minus p1 (Women)") ///
	num(`=ly65_raceadj_gap[1]') fmt(%9.1f)

scalarout using "${root}/scratch/Medicare and Social Security Eligibility/Years Lived Above 65.csv", ///
	id("Expected Years Lived Above 65: p100 minus p1 (Men)") ///
	num(`=ly65_raceadj_gap[2]') fmt(%9.1f)
project, creates("${root}/scratch/Medicare and Social Security Eligibility/Years Lived Above 65.csv")
