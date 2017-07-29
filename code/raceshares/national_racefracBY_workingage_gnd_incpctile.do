* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "$root/data/derived/raceshares/"
cap mkdir "$root/data/derived/raceshares/Individual income/"
cap mkdir "$root/data/derived/raceshares/2008-2012 ACS income distribution/"

set seed 1738157  // for noise added to positive incomes

/***

Uses the 2000 Census 5% sample microdata to generate the national population of
each race by Age x Gender x Income Percentile, at ages before retirement.

Then calculates the racial income distributions at each Age x Gender,
by computing the fraction of the population in each income percentile.

***/

****************
*** Programs ***
****************

cap program drop census_popcounts_by_race_inc
program define census_popcounts_by_race_inc

	/*** Load microdata extract from IPUMS containing
		 age, gender, race, income.
		 
		 Collapse to a file with population counts for each race
		 by Age x Gender x Income Percentile.
		 
		 Income percentiles are constructed using positive incomes.
		 Income percentile var is set == 0 for zero income and == -2 for negative incomes.
		 Missing incomes are dropped.
	***/
	
	syntax using/, income(name) income_pctile(name) [ income_pctile_label(string) ]
	
	* Load microdata
	project, original("`using'")
	use "`using'", clear
	
	* Drop older ages, because we're measuring contemporaneous income around retirement
	keep if inrange(age,40,61)
	
	* Restrict to non-missing incomes
	drop if `income'==9999999
	
	* Add some noise to positive incomes
	/*	Note:
		All self-reported incomes are integer values, and there is bunching at
		round numbers (ex: 30k).  In order to obtain equally sized percentiles,
		we break ties by adding "cents" to each positive income value.
	*/
	replace `income'=`income'+runiform() if `income'>0
	
	* Compute income percentile for each individual
	* --> percentiles computed separately by age and sex (as is done at the IRS)
	gen byte `income_pctile'=.
	if ("`income_pctile_label'"!="") label var `income_pctile' "`income_pctile_label'"
	forvalues a=40/61 {
		di "Computing percentiles for age `a'..."
		fastxtile `income_pctile'_m=`income' if sex==1 & `income'>0 & age==`a' [pw=perwt], nquantile(100)
		fastxtile `income_pctile'_f=`income' if sex==2 & `income'>0 & age==`a' [pw=perwt], nquantile(100)
		qui replace `income_pctile'=`income_pctile'_m if !mi(`income_pctile'_m)
		qui replace `income_pctile'=`income_pctile'_f if !mi(`income_pctile'_f)
		drop `income_pctile'_m `income_pctile'_f
	}
	
	* Code income percentiles for those with 0 and negative incomes
	replace `income_pctile'=0 if `income'==0
	replace `income_pctile'=-2 if `income'<0
	
	* Generate race indicators
	gen byte black=(race==2 & hispan==0)
	gen byte asian=(inrange(race,4,6) & hispan==0)
	gen byte hispanic=(hispan!=0)
	gen byte other=(black+asian+hispanic==0)
	
	* Check that the race categories are mutually exclusive and exhaustive
	assert black+asian+hispanic+other==1
	
	* Collapse to population counts by Age x Gender x Income Percentile
	collapse (sum) black asian hispanic other [pw=perwt], by(`income_pctile' sex age)
	
	* Rename variables containing population counts
	rename black pop_black
	rename asian pop_asian
	rename hispanic pop_hispanic
	rename other pop_other
	
	* Recode sex var
	assert inlist(sex,1,2)
	gen gnd=cond(sex==1,"M","F")
	drop sex
	
	* Reorder and sort
	order age gnd `income_pctile'
	sort age gnd `income_pctile'
	
	* Drop unnecessary labels
	label values age .
	label drop _all
	
	compress
	
end

project, original("$root/code/ado/compute_racefracs.ado")

************************************************
*** 2000 Census, HOUSEHOLD income percentile ***
************************************************

* Reference data source and codebook
project, relies_on("$root/data/raw/Census 2000 public microdata/source.txt")
project, relies_on("$root/data/raw/Census 2000 public microdata/Codebook_Basic.cbk")

* Compute race populations by income percentile
census_popcounts_by_race_inc ///
	using "$root/data/raw/Census 2000 public microdata/census2000race_sex_age_county_income.dta", ///
	income(ftotinc) ///
	income_pctile(hh_inc_pctile) ///
	income_pctile_label("Household Income Percentile")
	
* Compute race fractions
compute_racefracs, by(age gnd) incomevar(hh_inc_pctile) lowess_bw(0.2)

* Output
save13 "$root/data/derived/raceshares/national_racefractionsBY_workingage_gnd_hhincpctile.dta", replace
project, creates("$root/data/derived/raceshares/national_racefractionsBY_workingage_gnd_hhincpctile.dta")


*************************************************
*** 2000 Census, INDIVIDUAL income percentile ***
*************************************************

* Compute race populations by income percentile
census_popcounts_by_race_inc ///
	using "$root/data/raw/Census 2000 public microdata/census2000race_sex_age_county_income.dta", ///
	income(inctot) ///
	income_pctile(ind_inc_pctile) ///
	income_pctile_label("Individual Income Percentile")

* Compute race fractions
compute_racefracs, by(age gnd) incomevar(ind_inc_pctile) lowess_bw(0.2)

* Output
save13 "$root/data/derived/raceshares/Individual income/national_racefractionsBY_workingage_gnd_INDincpctile.dta", replace
project, creates("$root/data/derived/raceshares/Individual income/national_racefractionsBY_workingage_gnd_INDincpctile.dta")


**************************************************
*** 2008-2012 ACS, HOUSEHOLD income percentile ***
**************************************************

* Reference data source and codebook
project, relies_on("$root/data/raw/ACS 2008-2012 public microdata/source.txt")
project, relies_on("$root/data/raw/ACS 2008-2012 public microdata/usa_00005.cbk")

* Compute race populations by income percentile
census_popcounts_by_race_inc ///
	using "$root/data/raw/ACS 2008-2012 public microdata/acs20082012_race_sex_age_income.dta", ///
	income(ftotinc) ///
	income_pctile(hh_inc_pctile) ///
	income_pctile_label("Household Income Percentile")
	
* Compute race fractions
compute_racefracs, by(age gnd) incomevar(hh_inc_pctile) lowess_bw(0.2)

* Output
save13 "$root/data/derived/raceshares/2008-2012 ACS income distribution/national_racefractionsBY_workingage_gnd_hhincpctile_ACS.dta", replace
project, creates("$root/data/derived/raceshares/2008-2012 ACS income distribution/national_racefractionsBY_workingage_gnd_hhincpctile_ACS.dta")
