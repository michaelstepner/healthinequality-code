* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

/***

Uses the county-level Intercensal and Postcensal estimate tables, which contain
racial populations by County x 5-Year Age Bin x Gender x Year, each July.

We use these data to generate the county population of each race by 
Age Bin x Gender x Year (2001-2014) from the 2000s and 2010s
Intercensal/Postcensal estimates.

***/


********************************************************************

cap program drop clean_cty_censal_estimates
program define clean_cty_censal_estimates
	
	* Generate 5-digit county FIPS code
	gen long cty = 1000*state + county
	
	* Keep only desired age bins
	* --> age bins are 5-year age bins, labeled as the bottom age in each age bin
	keep if inrange(agegrp,9,16)
	replace agegrp=40+(agegrp-9)*5
	rename agegrp agebin
	
	* Keep only required race pops
	keep year cty agebin tot_male tot_female h_male h_female nhba_male nhba_female nhaa_male nhaa_female
	
	* Reshape gender long
	reshape long tot_ nhba_ nhaa_ h_, i(year cty agebin) j(gnd) string
	assert inlist(gnd,"male","female")
	replace gnd=cond(gnd=="male","M","F")
	compress gnd
	
	* Rename pop vars
	rename tot_ pop_total
	rename nhba_ pop_black
	rename nhaa_ pop_asian
	rename h_ pop_hispanic
	
	* Generate 'other' population count
	gen long pop_other = pop_total - pop_black - pop_asian - pop_hispanic
	drop pop_total

end

***************************************
*** 2000-2010 Intercensal Estimates ***
***************************************

project, relies_on("$root/data/raw/Census County Intercensal Estimates 2000-2010/source.txt") // source URL
project, relies_on("$root/data/raw/Census County Intercensal Estimates 2000-2010/Download county intercensal pop data.do") // automated download code
project, relies_on("$root/data/raw/Census County Intercensal Estimates 2000-2010/CO-EST00INT-ALLDATA.pdf") // data dictionary

* Load intercensal population data
project, original("$root/data/raw/Census County Intercensal Estimates 2000-2010/county_intercensal_2000s_allstates.dta")
use "$root/data/raw/Census County Intercensal Estimates 2000-2010/county_intercensal_2000s_allstates.dta", clear

* Reshape/rename raw intercensal data
clean_cty_censal_estimates

* Keep only annual July estimates (drop 2000 and 2010 April Census counts)
* --> see data dictionary for year codes
drop if inlist(year,1,12)
recode year (2=2000) (3=2001) (4=2002) (5=2003) (6=2004) (7=2005) (8=2006) ///
	(9=2007) (10=2008) (11=2009) (13=2010)

* Save
keep if inrange(year,2000,2009)
tempfile cty_intercensal
save `cty_intercensal'

**************************************
*** 2010-2014 Postcensal Estimates ***
**************************************

project, relies_on("$root/data/raw/Census County Postcensal Estimates 2010-2014/source.txt") // source URL
project, relies_on("$root/data/raw/Census County Postcensal Estimates 2010-2014/CC-EST2014-ALLDATA.pdf") // data dictionary

* Load postcensal population data
project, original("$root/data/raw/Census County Postcensal Estimates 2010-2014/CC-EST2014-ALLDATA.csv")
insheet using "$root/data/raw/Census County Postcensal Estimates 2010-2014/CC-EST2014-ALLDATA.csv", clear

* Reshape/rename raw postcensal data
clean_cty_censal_estimates

* Keep only annual July estimates (drop 2010 April Census counts)
* --> see data dictionary for year codes
keep if inrange(year,3,7)
recode year (3=2010) (4=2011) (5=2012) (6=2013) (7=2014)


***********************************
*** Combine data from 2001-2014 ***
***********************************
append using `cty_intercensal'
keep if inrange(year,2001,2014)

* Convert 2000-2014 Inter/Postcensal counties to 1999 counties
	* see https://www.census.gov/geo/reference/county-changes.html
isid cty year gnd agebin
drop if cty == 15005 // Kalawao, Hawaii (pop ~90)
recode cty (12086 = 12025) // Miami-Dade FIPS change
recode cty (8014 = 8013) // Broomfield County created from Boulder, CO
recode cty (2282 = 2231) (2275 2195 = 2280) (2230 2105 = 2231) ///
	(2198 = 2201) (2068 = 2290) // County changes in Alaska

collapse (sum) pop*, by(cty year gnd agebin) // combine counties that split in 2000-2014

/* Note: Bedford City (cty==51515) appears in 2001-2009 but not 2010-2014.  See: -tab year-.
	
	This is because Bedford City was merged into a larger county in 2010-2014. It therefore
	appears in 1999 and 2000-2009 but not afterwards. 
*/


* Output
compress
order year agebin gnd cty
sort year agebin gnd cty
assert !mi(pop_black, pop_asian, pop_hispanic, pop_other)
save13 "$root/data/derived/raceshares/cty_racepopBY_year_agebin_gnd.dta", replace
project, creates("$root/data/derived/raceshares/cty_racepopBY_year_agebin_gnd.dta")

