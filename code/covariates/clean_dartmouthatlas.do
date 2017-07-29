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

/*** Dartmouth Atlas Data (measures of health care access & quality)
***/

*******


*** Primary care access and quality for Medicare enrollees, year 2010
project, original("${cov_raw}/PC_County_rates_2010.xls")
import excel using "${cov_raw}/PC_County_rates_2010.xls", clear

destring A, gen(cty) force
ren (B) (countyname)
destring C, gen(num_medicare) force
destring F, gen(primcarevis) force
destring R, gen(diab_hemotest) force
destring AA, gen(diab_eyeexam) force
destring AJ, gen(diab_lipids) force
destring AV, gen(mammogram) force
destring BH, gen(leg_amp_per1000) force
destring BQ, gen(amb_disch_per1000) force

keep cty countyname num_* prim* amb* diab_* mammo* 
drop if cty==.
recode cty (12086=12025) (8014 = 8013) // Miami-Dade name/FIPS change, Broomfield split off from Boulder
collapse (mean) prim* amb* diab_* mammo* (rawsum) num_medicare [w=num_medicare], by(cty)


lab var num_medicare "Number of Medicare beneficiaries - 20% Part B"
lab var primcarevis "Avg ann percent with at least one primary care visit"
lab var diab_hemotest "Avg ann percent diabetic with hemoglobin test"
lab var diab_eyeexam "Avg ann percent diabetic with eye exam"
lab var diab_lipids "Avg ann percent diabetic with lipids test"
lab var mammogram "Avg percent female 67-69 with mammogram"
lab var amb_disch_per1000 "Discharges for ambulatory care per 1000 Medicare Enrollees"

ren (*) (*_10)
ren (cty_10) (cty)

* Save at county level
tempfile dartmouth_primarycare_cty
save `dartmouth_primarycare_cty'

* Collapse to CZ level
project, original("${cov_raw}/cty_covariates.dta") preserve
merge m:1 cty using "${cov_raw}/cty_covariates.dta", keepus(cz) keep(match master)
assert floor(cty/1000)==2 | inlist(cty,15005,51560,99999) if _merge!=3 // unmerged are Alaska counties, Kalawao, Hawaii, or Clifton Forge, VA
drop _merge
replace cz = 28900 if cty==8014  // Assign Broomfield to Boulder CZ
drop if cz==.
collapse (mean) prim* amb* diab_* mammo* [w=num_medicare_10], by(cz)
tempfile dartmouth_primarycare_cz
save `dartmouth_primarycare_cz'


*** County reimbursements, 2010
project, original("${cov_raw}/pa_reimb_county_2010.xls")
import excel county_id name enroll reimb_penroll10 reimb_penroll_adj10 using "${cov_raw}/pa_reimb_county_2010.xls", cellrange(A3) clear
ren county_id cty
drop if cty==.
recode cty (12086=12025) (8014 = 8013) // Miami-Dade name/FIPS change, Broomfield split off from Boulder
keep reimb* enroll cty
collapse (mean) reimb* (rawsum) enroll [w=enroll], by(cty)

lab var reimb_penroll10 "Medicare Reimbursements per Enrollee 2010"
lab var reimb_penroll_adj10 "Medicare Reimbursements per Enrollee - Price/Age/Sex Adj - 2010"
lab var enroll "Number of Medicare Enrollees"

* Save at county level
tempfile medicarereimb_cty
save `medicarereimb_cty'

*Collapse to CZ level
project, original("${cov_raw}/cty_covariates.dta") preserve
merge 1:1 cty using "${cov_raw}/cty_covariates.dta", keep(match master) keepus(cz)
assert floor(cty/1000)==2 | cty==15005 | enroll < 100 ///
	| inlist(cty,51560,8014,99999) if _merge!=3 // unmerged are Alaska counties, Kalawao, Hawaii, or specific cases
drop _merge
replace cz = 28900 if cty==8014  //Assign Broomfield County to Boulder CZ
drop if cz==.
collapse (mean) reimb* [w=enroll], by(cz)
tempfile medicarereimb_cz
save `medicarereimb_cz'

*** Combine into dartmouth health atlas dataset (county) 
use `dartmouth_primarycare_cty', clear
merge 1:1 cty using `medicarereimb_cty', nogen
project, original("${cov_raw}/cty_covariates.dta") preserve
merge 1:1 cty using "${cov_raw}/cty_covariates.dta", keepusing(cty_pop2000) keep(match master)
assert floor(cty/1000)==2 | cty==15005 | enroll < 100 ///
	| inlist(cty,51560,99999) if _merge!=3 // unmerged are Alaska counties, Kalawao, Hawaii, or Clifton Forge, VA
drop _merge
drop if cty_pop2000==.

* Generate pooled preventive care measure
foreach v of varlist primcarevis_10 diab_hemotest_10 diab_eyeexam_10 diab_lipids_10 mammogram_10 amb_disch_per1000_10 {
	qui sum `v' [w=cty_pop2000]
	gen `v'_std = (`v'- `r(mean)')/`r(sd)'
}
gen med_prev_qual_z = (primcarevis_10_std + diab_hemotest_10_std + diab_eyeexam_10_std + diab_lipids_10_std ///
	+ mammogram_10_std - amb_disch_per1000_10_std)/6

lab var med_prev_qual_z "Mean of Z-Scores for Dartmouth Atlas ambulatory care measures"
drop *_std cty_pop2000
save13 "${cov_clean}/cty_dartmouth.dta", replace
project, creates("${cov_clean}/cty_dartmouth.dta")


*** Combine into dartmouth health atlas dataset (CZ) 
use `dartmouth_primarycare_cz', clear
merge 1:1 cz using `medicarereimb_cz', nogen assert(match)
project, original("${cov_raw}/cz_characteristics.dta") preserve
merge 1:1 cz using "${cov_raw}/cz_characteristics.dta", nogen keepusing(pop2000) keep(match master)

* Generate pooled preventive care measure
foreach v of varlist primcarevis_10 diab_hemotest_10 diab_eyeexam_10 diab_lipids_10 mammogram_10 amb_disch_per1000_10 {
	qui sum `v' [w=pop2000]
	gen `v'_std = (`v'- `r(mean)')/`r(sd)'
}
gen med_prev_qual_z = (primcarevis_10_std + diab_hemotest_10_std + diab_eyeexam_10_std + diab_lipids_10_std ///
	+ mammogram_10_std - amb_disch_per1000_10_std)/6

lab var med_prev_qual_z "Mean of Z-Scores for Dartmouth Atlas ambulatory care measures"
drop *_std pop2000
recast float primcarevis_10-reimb_penroll_adj10, force
save13 "${cov_clean}/cz_dartmouth.dta", replace
project, creates("${cov_clean}/cz_dartmouth.dta")
