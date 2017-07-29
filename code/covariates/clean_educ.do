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

/*** Education, year 2000
***/

*******

*** Load Census Data
project, original("${cov_raw}/census_education_2000_county.csv")
insheet using "${cov_raw}/census_education_2000_county.csv", clear names
ren geoid2 cty
ren (hc01_vc31 hc01_vc32) (cs_educ_hs cs_educ_ba) // age 25+ with high school degree, bachelor's degree
keep cty cs_educ_hs cs_educ_ba 
recode cty (12086=12025) // Miami-Dade name/FIPS change
lab var cs_educ_hs "Percent age 25+ with high school degree"
lab var cs_educ_ba "Percent age 25+ with bachelor's degree"

//merge counties to CZs
project, original("${cov_raw}/cty_covariates.dta") preserve
merge 1:1 cty using "${cov_raw}/cty_covariates.dta", keepus(cz cty_pop2000) keep(match master)
assert floor(cty/1000)==2 | cty==15005 if _merge!=3 // unmerged are either Alaska counties or Kalawao, Hawaii
drop _merge
drop if cz==.
preserve
keep cty cs_educ*
save13 "${cov_clean}/cty_cs_educ.dta", replace
project, creates("${cov_clean}/cty_cs_educ.dta")

* Collapse to CZ level
restore
collapse (mean) cs_educ_hs cs_educ_ba [w=cty_pop2000], by(cz)
save13 "${cov_clean}/cz_cs_educ.dta", replace
project, creates("${cov_clean}/cz_cs_educ.dta")
