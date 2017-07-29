* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

****************


********************************************************************
***    Load raw HH Count data                                    ***
*** # of households x County x 10-year Age Bins x 16 Income Bins ***
********************************************************************

project, relies_on("$root/data/raw/Census 2000 SF3/source.txt")  // download URL
project, relies_on("$root/data/raw/Census 2000 SF3/sf3.pdf")  // data documentation

cap program drop load_sf3_HHcount_data
program define load_sf3_HHcount_data
	/*** Clean raw Census 2000 SF3 tables
		 "AGE OF HOUSEHOLDER BY HOUSEHOLD INCOME IN THE PAST 12 MONTHS (subgroup)"
		 to a dataset with counts of households identified by County x Age Bin x Income Bin
	***/
	
	syntax using/, race(name)
	
	* Import 2000 Census SF3 file from csv
	project, original(`"`using'"')
	import delimited `"`using'"', varnames(2) rowrange(3) clear
	
	* Clean county variable
	rename id2 cty
	confirm numeric var cty
	
	* Only keep county level observations (remove rural/urban breakdowns)
	keep if substr(id,6,2)=="00"
	
	* Rename variables to more manageable names (indicating Age Bin x Income Bin)
	drop householderunder* // drop lowest age bin (<25 years)
	ren householder* h_*
	ren (*25to34years* *35to44years* *45to54years* *55to64years* *65to74years* *75yearsandover*) ///
		(*agebin25_*   *agebin35_*   *agebin45_*   *agebin55_*   *agebin65_*   *agebin75_*)
	ren (*_ *_less* *_10000t* *_15000t* *_20000t* *_25000t* *_30000t* *_35000t* *_40000t* *_45000t* *_50000t* *_60000t* *_75000t* *_100000t* *_125000t* *_150000t* *_200000*) ///
		(*_total *_inc1 *_inc2 *_inc3 *_inc4 *_inc5 *_inc6 *_inc7 *_inc8 *_inc9 *_inc10 *_inc11 *_inc12 *_inc13 *_inc14 *_inc15 *_inc16)
	drop h_*_total
	
	* Reshape to long by county x age bin x income bin
	keep cty h_*
	reshape long h_agebin25_inc h_agebin35_inc h_agebin45_inc h_agebin55_inc h_agebin65_inc h_agebin75_inc, i(cty) j(hh_inc_bin)
	reshape long h_agebin@_inc, i(cty hh_inc_bin) j(agebin)
	rename h_agebin_inc pop_`race'
	
	* Keep ages 35-64
	keep if inrange(agebin,35,55)
end


*** All households
project, relies_on("$root/data/raw/Census 2000 SF3/DEC_00_SF3_P055.txt")  // docs
load_sf3_HHcount_data using "$root/data/raw/Census 2000 SF3/DEC_00_SF3_P055_with_ann.csv", race(total)

tempfile pop_total
save `pop_total'


*** Households with a householder who is Black or African American
project, relies_on("$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT072B.txt")  // docs
load_sf3_HHcount_data using "$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT072B_with_ann.csv", race(black)

tempfile pop_black
save `pop_black'


*** Households with a householder who is Asian
project, relies_on("$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT072D.txt")  // docs
load_sf3_HHcount_data using "$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT072D_with_ann.csv", race(asian)

tempfile pop_asian
save `pop_asian'


*** Households with a householder who is Hispanic or Latino
project, relies_on("$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT072H.txt")  // docs
load_sf3_HHcount_data using "$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT072H_with_ann.csv", race(hispanic)

tempfile pop_hispanic
save `pop_hispanic'


*******************************************
*** Combine and clean HH by income data ***
*******************************************

*** Combine data on total, black, asian, and hispanic pop
use `pop_total', clear
merge 1:1 cty agebin hh_inc_bin using `pop_black', assert(3) nogen
merge 1:1 cty agebin hh_inc_bin using `pop_asian', assert(3) nogen
merge 1:1 cty agebin hh_inc_bin using `pop_hispanic', assert(3) nogen

* Generate "other" population
/*
  Note: this is not exactly right, because black/asian hispanics
		are double counted, in both the black/asian and the hispanic populations.
		
		In practice, this is not a huge problem because we are only going to be
		using this data to obtain racial income distributions (race fractions),
		not as final population data.
*/
gen long pop_other = pop_total - pop_black - pop_asian - pop_hispanic


*** Handle counties

* Convert to 1999 counties
replace cty = 2231 if cty == 2232 // renaming of most of the Skagway-Yakutat-Angoon Census Area (AK) (pop 3,679)
drop if cty == 2282 // drop the rest of the Skagway-Yakutat-Angoon Census Area (AK) (pop 725)
drop if cty == 15005 // drop Kalawao County (HI), former leper colony (pop 100)
drop if cty == 2068 // drop Denali Borough (AK) (pop 1,600), created from part of Yukon-Koyukuk Census Area
replace cty = 12025 if cty == 12086 // renaming of Dade county to Miami-Dade (FL)

* Merge county 51560 into county 51005, which is what happened in 2001 (https://www.census.gov/geo/reference/county-changes.html)
*   and how those counties appear in our county race pop data (2000-2014 Intercensal/Postcensal)
isid cty hh_inc_bin agebin
replace cty=51005 if cty==51560
collapse (sum) pop_*, by(cty hh_inc_bin agebin)


*** Output
compress
save13 "$root/data/derived/raceshares/cty_racepopBY_workingagebin_hhincbin.dta", replace
project, creates("$root/data/derived/raceshares/cty_racepopBY_workingagebin_hhincbin.dta")

