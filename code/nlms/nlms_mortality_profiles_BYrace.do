* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
if (c(os)=="Windows") global img wmf
else global img png

* Create required folders
cap mkdir "${root}/scratch/NLMS mortality profiles by race"
cap mkdir "${root}/scratch/NLMS mortality profiles by race/data"

/*** Plot NLMS log mortality-agebin profiles from binned raw data,
		drawing OLS fit lines through them illustrating Gompertz relationship.
		
	 - Separate series for each race.
	 - Separate panel for each gender.
***/


********************
*** Create panel ***
********************

* Load data
project, original("${root}/data/derived/NLMS/nlms_v5_s11_sampleA.dta")
use "${root}/data/derived/NLMS/nlms_v5_s11_sampleA.dta", clear
stset, clear

* Create panel structure
expand 11  // creates 11 duplicate obs, because we observe up to 11 full years
bys record: replace age = age + (_n-1)  // increment age for 11 follow-up obs
keep if inrange(age,startage,endage)  // keep observations in risk period (income lagged 2 years and before death)

* Replace age with average age in year of observation
/* Someone who dies in a given year dies on average 6 months into the year */
replace age=age+0.5
	
* Generate indicator for year of death
gen byte dead=0
isid record age
bys record (age): replace dead=1 if _n==_N & inddea==1

rename inddea r_dead
label var r_dead "Death Ever Observed indicator"
label var dead "Year of Death indicator"
	
* Generate age bins, coding agebin as the center of the bin
assert inrange(age,40,72)
g agebin = floor(age/5)*5 + 2
replace agebin = 71 if agebin==72  // center of last agebin (ages 70-72)
assert inrange(agebin,40,71)


************************
*** Generate Figures ***
************************

*** Collapse to mortality rates

* Define mortality rate in each Age Bin x Sex x Race x Income Quartile group G as
* number of individual life-years in group G that are dead by a+1
* divided by the number of individual life-years in group G
collapse (mean) dead [w=wt], by(agebin gnd racegrp incq)

* Income-adjust by taking unweighted average across income bins
collapse (mean) dead, by(agebin gnd racegrp)


*** Create binscatters
* Exclude agebin 71 because it's a 3-year bin instead of a 5-year bin

g l_mortrate = log(dead)

foreach g in "M" "F" {

	* Generate scatter
	binscatter l_mortrate agebin if gnd=="`g'" & agebin<70, by(racegrp) ///
		mcolor(navy maroon) xscale(range(40 70)) ///
		xtit("Age Bin in Years") ytit("Log Mortality Rate") tit("") ///
		ylabel(-7(1)-3) yscale(range(-7 -3)) legend(ring(0) pos(4) c(1) order(2 1 3 4) bmargin(medium) ///
		label(1 "White") label(2 "Black") label(3 "Hispanic") label(4 "Asian")) msymbol(circle triangle square diamond) ///
		xlab(42 "40-44" 47 "45-49" 52 "50-54" 57 "55-59" 62 "60-64" 67 "65-69"/* 71 "70-72"*/)
	graph export "${root}/scratch/NLMS mortality profiles by race/NLMS_raw_mortality_profiles_wOLSfitline_`g'.${img}", replace
	project, creates("${root}/scratch/NLMS mortality profiles by race/NLMS_raw_mortality_profiles_wOLSfitline_`g'.${img}") preserve

	* Export underlying data
	export delim gnd racegrp agebin l_mortrate if gnd=="`g'" & agebin<70 ///
		using "${root}/scratch/NLMS mortality profiles by race/data/NLMS_raw_mortality_profiles_wOLSfitline_`g'.csv", replace
	project, creates("${root}/scratch/NLMS mortality profiles by race/data/NLMS_raw_mortality_profiles_wOLSfitline_`g'.csv") preserve
	
	
}
