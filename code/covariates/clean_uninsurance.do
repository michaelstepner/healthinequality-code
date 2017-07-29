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

/*** Percent uninsured, year 2010
***/

*******


*** Load 2010 Small Area Health Insurance Estimates
project, original("${cov_raw}/sahie2010.csv")
import delimited "${cov_raw}/sahie2010.csv", delimiter(comma) varnames(4) rowrange(4) clear
destring, replace

* Keep county-level estimates by all ages/races/genders/incomes
* (Note that data is only for people below age 65, since Medicare starts at 65)
keep if geocat==50 & agecat==0 & racecat==0 & sexcat==0 & iprcat==0
keep stcou nic nui
destring nic nui, replace force
replace stcou = subinstr(stcou,"=","",.)
replace stcou = subinstr(stcou,`"""',"",.)
destring stcou, replace
ren stcou cty
recode cty (12086=12025) (8014 = 8013) // Miami-Dade name/FIPS change, Broomfield split off from Boulder
collapse (sum) nic nui, by(cty)
//merge counties to CZs

project, original("${cov_raw}/cty_covariates.dta") preserve
merge 1:1 cty using "${cov_raw}/cty_covariates.dta", keepus(cz) keep(match master)
assert floor(cty/1000)==2 | cty==15005 ///
	| inlist(cty,51560) if _merge!=3 // unmerged are Alaska counties, Kalawao, Hawaii, or Clifton Forge, VA
drop _merge
drop if cz==.
preserve
gen puninsured2010 = 100 * nui / (nic + nui)
lab var puninsured2010 "Percent without Health Insurance in 2010"
keep cty puninsured2010
save13 "${cov_clean}/cty_cs_puninsured.dta", replace
project, creates("${cov_clean}/cty_cs_puninsured.dta")

* Collapse to CZ level
restore
collapse (sum) nui nic, by(cz)
gen puninsured2010 = 100 * nui / (nic + nui)
lab var puninsured2010 "Percent without Health Insurance in 2010"
keep cz puninsured2010
save13 "${cov_clean}/cz_cs_puninsured.dta", replace
project, creates("${cov_clean}/cz_cs_puninsured.dta")
