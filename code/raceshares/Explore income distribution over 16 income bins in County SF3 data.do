* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "$root/scratch/SF3 income distributions"

************************

*********************************************************
*** Explore income distribution across 16 income bins ***
*********************************************************

* Load data
project, uses("$root/data/derived/raceshares/cty_racepopBY_workingagebin_hhincbin.dta")
use "$root/data/derived/raceshares/cty_racepopBY_workingagebin_hhincbin.dta", clear

* Create national income distribution by agebin, collapsing over counties
isid cty hh_inc_bin agebin
collapse (sum) pop_total, by(hh_inc_bin agebin)

* Display income distribution
bys agebin: tab hh_inc_bin [w=pop_total]

* Convert from population counts to relative frequencies, by agebin
gen float frac_total=.
foreach a in 35 45 55 {
	sum pop_total if agebin==`a', meanonly
	replace frac_total=pop_total/`r(sum)' if agebin==`a'
}

* Reshape agebin wide
drop pop_total
rename frac_total frac_agebin
reshape wide frac_agebin, i(hh_inc_bin) j(agebin)

* Output
export delim "$root/scratch/SF3 income distributions/national_popfracBY_agebin_hhincbin.csv", replace
project, creates("$root/scratch/SF3 income distributions/national_popfracBY_agebin_hhincbin.csv") preserve


******************************************************************
*** Explore manual assignment of 16 income bins into quartiles ***
******************************************************************

* Reshape agebin long
reshape long frac_agebin, i(hh_inc_bin) j(agebin)

* Manually assign income bins to quartiles, separately by age bin
gen byte hh_inc_q = hh_inc_bin
recode hh_inc_q (1/5 = 1) (6/9 = 2) (10/11 = 3) (12/16 = 4) if agebin==35
recode hh_inc_q (1/6 = 1) (7/10 = 2) (11/12 = 3) (13/16 = 4) if agebin==45
recode hh_inc_q (1/4 = 1) (5/8 = 2) (9/11 = 3) (12/16 = 4) if agebin==55

* Collapse fractions to quartiles
collapse (sum) frac_agebin, by(hh_inc_q agebin)

* Reshape agebin wide
reshape wide frac_agebin, i(hh_inc_q) j(agebin)

* Output
export delim "$root/scratch/SF3 income distributions/national_popfracBY_agebin_hhincq.csv", replace
project, creates("$root/scratch/SF3 income distributions/national_popfracBY_agebin_hhincq.csv")
