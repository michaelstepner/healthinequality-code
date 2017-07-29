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

/*** fraction Black, fraction Hispanic; year 2000
***/

*******

*** Load Census Data
project, original("${cov_raw}/Census cty population by race/DEC_00_SF1_P008_with_ann.csv")
import delim "${cov_raw}/Census cty population by race/DEC_00_SF1_P008_with_ann.csv", clear rowr(3) varn(1)
destring *, replace
ren (geoid2 vd01 vd04 vd10) (cty pop_total pop_black pop_hispanic)
keep cty pop_*

// merge to CZs
recode cty (12086=12025) // Miami-Dade fips change
merge 1:1 cty using "${cov_raw}/cty_covariates.dta", keepus(cz) keep(match master)
assert floor(cty/1000)==2 | cty==15005 if _merge!=3 // unmerged are Alaska counties or Kalawao, Hawaii
drop _merge
drop if cz==.
preserve

// output at county level
gen cs_frac_black = pop_black/pop_total
gen cs_frac_hisp = pop_hispanic/pop_total
keep cty cs_frac*
save13 "${cov_clean}/cty_cs_popbyrace.dta", replace
project, creates("${cov_clean}/cty_cs_popbyrace.dta")

// output at CZ level
restore
collapse (sum) pop*, by(cz)
gen cs_frac_black = pop_black/pop_total
gen cs_frac_hisp = pop_hispanic/pop_total
keep cz cs_frac*
save13 "${cov_clean}/cz_cs_popbyrace.dta", replace
project, creates("${cov_clean}/cz_cs_popbyrace.dta")
