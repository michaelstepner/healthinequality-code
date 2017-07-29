* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global cov_raw "$root/data/raw/Covariate Data"
global cov_clean "$root/data/derived/covariate_data"

* Create required folders
cap mkdir "$root/data/derived/covariate_data"

/*** BRFSS Health Data, averaging over years 1996-2008 (small samples per year).
***/

*******

*** Load and clean annual BRFSS data
foreach i in 96 97 98 99 00 01 02 03 04 05 06 07 08 {
	project, original("${cov_raw}/BRFSS/CDBRFS`i'.dta")
	use "${cov_raw}/BRFSS/CDBRFS`i'.dta", clear
	ren _state state
	
	* Clean demographic variables
	* Note: income2 - "Annual household income from all sources"
	
	recode ctycode (777 = .) (888 =.) (999 = .)
	recode income2 (77 = .) (99 = .) (1 = 0) (2 = 10000) (3 = 15000) (4 = 20000) (5 = 25000) (6 = 35000) (7 = 50000) (8 = 75000)
	label var income2 "INCOME BIN, DEFINED BY LOWER BOUND"
		
	* Clean smoking variable
	* Generates ever_smoke, cur_smoke
	ren _smoker* smokernew
	recode smokernew (9 = .)
	label define smoke 1 "Current - Daily" 2 "Current - Less than Daily" 3 "Former" 4 "Never"
	label values smokernew smoke
	
	gen ever_smoke = smokernew
	recode ever_smoke (4=0) (2=1) (3=1)
	
	gen cur_smoke = smokernew
	recode cur_smoke (4=0) (3=0) (2=1)

	* Clean obesity variables
	* Generates bmi_over, bmi_obese
	if !inrange(`i',96,99) {
		ren _bmi*cat bmicatnew
		
		recode bmicatnew (9 = .)
		label define obese 1 "no" 2 "overweight" 3 "obese"
		label values bmicatnew obese
				
		gen bmi_over = bmicatnew 
		recode bmi_over (1=0) (2=1) (3=1)
		
		gen bmi_obese = bmicatnew
		recode bmi_obese (1=0) (2=0) (3=1)
	}
	else {
		gen bmi_over = cond(_bmi >= 250,1,0) if _bmi != 999
		gen bmi_obese = cond(_bmi >= 300,1,0) if _bmi != 999
	}
	
	* Clean exercise variables
	ren exerany* exercise_any
	recode exercise_any (2=0) (7=.) (9=.)

	tempfile brfss_y`i'
	save `brfss_y`i''
}

* Append data by year
use `brfss_y96', clear
foreach i in 97 98 99 00 01 02 03 04 05 06 07 08 {	
	append using `brfss_y`i'', keep(state year ctycode income2 ever_smoke cur_smoke bmi_over bmi_obese exercise_any)
}

* Final County ID
gen county_id = state*1000 + ctycode
drop ctycode
ren income2 incomecat

* County to CZ Crosswalk
keep if county_id!=. // Missing Counties 
drop if state > 56 // US territories

* Fips County Code changes
replace county_id= 12025 if county_id==12086  //Miami-Dade -> Dade
replace county_id= 8013 if county_id == 8014  //Broomfield -> Boulder

* Merge counties to CZs
rename county_id cty
project, original("${cov_raw}/cty_covariates.dta") preserve
merge m:1 cty using "${cov_raw}/cty_covariates.dta", keepus(cz) keep(match master)
drop if cz == .

* Keep relevant variables
keep cty cz state incomecat bmi_* *_smoke exercise*

tempfile indv_data
save `indv_data'

global vars bmi_over bmi_obese ever_smoke cur_smoke exercise_any

*** Collapse to county level

* overall averages by county
use `indv_data', clear
collapse (mean) ${vars}, by(cty)
drop if cty==.
tempfile brfss_cty
save `brfss_cty'

* collapse by income quartile
use `indv_data', clear
xtile incq = incomecat, nquantiles(4)
collapse (mean) ${vars}, by(cty incq)
drop if incq==. | cty==.
reshape wide ${vars}, i(cty) j(incq)
ren *1 *_q1
ren *2 *_q2
ren *3 *_q3 
ren *4 *_q4

* output
merge 1:1 cty using `brfss_cty', nogen
lab var bmi_over "BRFSS: overweight"
lab var bmi_obese "BRFSS: obese"
lab var ever_smoke "BRFSS: ever smoke"
lab var cur_smoke "BRFSS: currently smoke"
lab var exercise_any "BRFSS: exercise in last 30 days"
foreach i in "q1" "q2" "q3" "q4" {
	lab var bmi_over_`i' "BRFSS: overweight - Inc `i'"
	lab var bmi_obese_`i' "BRFSS: obese - Inc `i'"
	lab var ever_smoke_`i' "BRFSS: ever smoke - Inc `i'"
	lab var cur_smoke_`i' "BRFSS: currently smoke - Inc `i'"
	lab var exercise_any_`i' "BRFSS: exercise in last 30 days - Inc `i'"
}
save13 "${cov_clean}/cty_brfss_byincq.dta", replace
project, creates("${cov_clean}/cty_brfss_byincq.dta")


*** Collapse to CZ level

* overall averages by CZ
use `indv_data', clear
collapse (mean) ${vars}, by(cz)
drop if cz==.
tempfile brfss_cz
save `brfss_cz'

* collapse by income quartile
use `indv_data', clear
xtile incq = incomecat, nquantiles(4)
collapse (mean) ${vars}, by(cz incq)
drop if incq==. | cz==.
reshape wide ${vars}, i(cz) j(incq)
ren *1 *_q1 
ren *2 *_q2
ren *3 *_q3 
ren *4 *_q4

* output
merge 1:1 cz using `brfss_cz', nogen
lab var bmi_over "BRFSS: overweight"
lab var bmi_obese "BRFSS: obese"
lab var ever_smoke "BRFSS: ever smoke"
lab var cur_smoke "BRFSS: currently smoke"
lab var exercise_any "BRFSS: exercise in last 30 days"
foreach i in "q1" "q2" "q3" "q4" {
	lab var bmi_over_`i' "BRFSS: overweight - Inc `i'"
	lab var bmi_obese_`i' "BRFSS: obese - Inc `i'"
	lab var ever_smoke_`i' "BRFSS: ever smoke - Inc `i'"
	lab var cur_smoke_`i' "BRFSS: currently smoke - Inc `i'"
	lab var exercise_any_`i' "BRFSS: exercise in last 30 days - Inc `i'"
}
save13 "${cov_clean}/cz_brfss_byincq.dta", replace
project, creates("${cov_clean}/cz_brfss_byincq.dta")
