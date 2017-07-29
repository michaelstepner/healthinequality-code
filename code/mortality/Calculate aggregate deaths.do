* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "${root}/scratch/Deaths and population counts in IRS and other samples"

/*** Calculate the aggregate number of deaths and mortality rate in our sample,
	 pooling all ages 40-76 and all years. Separately for men and women.
***/

*************


* Load mortality rates
project, uses("${root}/data/derived/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta")
use "${root}/data/derived/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta", clear
keep if age_at_d >= 40

* Collapse to aggregate deaths and population counts by Gender
gen long deaths=mortrate*count

collapse (rawsum) count deaths, by(gnd)
recast long count deaths
format %12.0gc count deaths

* Generate mortality per 100,000
gen mortper100K = deaths/count*100000
format %9.1f mortper100K

* Output numbers
assert gnd=="F" in 1

scalarout using "${root}/scratch/Deaths and population counts in IRS and other samples/Aggregate deaths and mortality rate by gender.csv", ///
	replace ///
	id("Aggregate deaths in sample 40-76: Men") ///
	num(`=deaths[2]') fmt(%12.0gc)

scalarout using "${root}/scratch/Deaths and population counts in IRS and other samples/Aggregate deaths and mortality rate by gender.csv", ///
	id("Aggregate mortality per 100,000 in sample 40-76: Men") ///
	num(`=mortper100K[2]') fmt(%9.1f)
	
scalarout using "${root}/scratch/Deaths and population counts in IRS and other samples/Aggregate deaths and mortality rate by gender.csv", ///
	id("Aggregate deaths in sample 40-76: Women") ///
	num(`=deaths[1]') fmt(%12.0gc)

scalarout using "${root}/scratch/Deaths and population counts in IRS and other samples/Aggregate deaths and mortality rate by gender.csv", ///
	id("Aggregate mortality per 100,000 in sample 40-76: Women") ///
	num(`=mortper100K[1]') fmt(%9.1f)

project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/Aggregate deaths and mortality rate by gender.csv")
