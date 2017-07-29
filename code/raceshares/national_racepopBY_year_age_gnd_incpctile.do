* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set global aliases
global racedata $root/data/derived/raceshares

/***

Add an income dimension to the national race population data.

Uses race fractions derived from the 2000 Census public-use microdata
to assign income bins to the race populations in the 2000-2014
Intercensal/Postcensal estimates.

We apply the age 61 racial income distribution to the racial population for each
age 62-76.  This imputes the income dimension of the last working age we see for
people who are at retirement ages.  The procedure is an approximation of the
procedure we perform at the IRS, where we use peoples' income at age 61 at all
later ages. Note that we only observe contemporary income in the Census.

We verify the accuracy of this approximation using a parametric simulation and a
non-parametric check where we extrapolate forward from age 51.

***/

************************

cap program drop impute_income_dimension
program define impute_income_dimension

	/*** Loads racial population data by Year x Age x Gender,
		 then imputes an income dimension using racial income distributions,
		 which are Age x Gender (same distribution used in all years).
		 
		 Uses the income distribution at the last working age for the
		 income dimension at all subsequent ages.
	***/
	
	syntax using/, incomevar(name) [ retirementage(integer 62) ]
	
	project, uses(`"`using'"')
	
	* Load race population data
	project, uses("$racedata/national_racepopBY_year_age_gnd.dta")
	use "$racedata/national_racepopBY_year_age_gnd.dta", clear
	
	* Generate an income bin dimension
	isid year age gnd
	expand 102
	bys year age gnd: gen int `incomevar' = _n - 2
	replace `incomevar'=-2 if `incomevar'==-1
	order year age gnd `incomevar'
	
	* Generate a temporary "age" variable corresponding to the age of the income distribution
	* we want merged in.
	rename age trueage
	assert inrange(trueage,40,76)
	recode trueage (`retirementage'/76 = `=`retirementage'-1'), gen(age)
	
	* Merge in racial income distributions
	merge m:1 age gnd `incomevar' using `"`using'"', ///
		assert(2 3) keep(3) keepusing(smoothfrac_*) nogen
		// note: _merge==2 happens when we set the retirement age < 62, so the income distributions at some working ages are not used.

	drop age
	rename trueage age
	
	* Apply race fractions to adjust counts
	foreach race in black asian hispanic other {
		replace pop_`race' = pop_`race' * smoothfrac_of_`race'
	}
	drop smoothfrac_*
			
	* Output
	sort year age gnd `incomevar'
	isid year age gnd `incomevar'
	compress

end


*************************************
*** 2000 Census, Household income ***
*************************************

impute_income_dimension using "$racedata/national_racefractionsBY_workingage_gnd_hhincpctile.dta", ///
	incomevar(hh_inc_pctile)

save13 "$racedata/national_racepopBY_year_age_gnd_hhincpctile.dta", replace
project, creates("$racedata/national_racepopBY_year_age_gnd_hhincpctile.dta")


**************************************
*** 2000 Census, Individual income ***
**************************************

impute_income_dimension using "$racedata/Individual income/national_racefractionsBY_workingage_gnd_INDincpctile.dta", ///
	incomevar(ind_inc_pctile)
	
save13 "$racedata/Individual income/national_racepopBY_year_age_gnd_INDincpctile.dta", replace
project, creates("$racedata/Individual income/national_racepopBY_year_age_gnd_INDincpctile.dta")

***************************************
*** 2008-2012 ACS, Household income ***
***************************************

impute_income_dimension using "$racedata/2008-2012 ACS income distribution/national_racefractionsBY_workingage_gnd_hhincpctile_ACS.dta", ///
	incomevar(hh_inc_pctile)
	
save13 "$racedata/2008-2012 ACS income distribution/national_racepopBY_year_age_gnd_hhincpctile_ACS.dta", replace
project, creates("$racedata/2008-2012 ACS income distribution/national_racepopBY_year_age_gnd_hhincpctile_ACS.dta")


********************************************************************************
*** Age 51 Retirement Age Extrapolation Test (2000 Census, Household Income) ***
********************************************************************************

impute_income_dimension using "$racedata/national_racefractionsBY_workingage_gnd_hhincpctile.dta", ///
	incomevar(hh_inc_pctile) retirementage(52)
	
keep if inrange(age,51,61)

cap mkdir "$racedata/Age 51 Retirement Age Extrapolation Test/"
save13 "$racedata/Age 51 Retirement Age Extrapolation Test/national_racepopBY_year_age_gnd_hhincpctile_51test.dta", replace
project, creates("$racedata/Age 51 Retirement Age Extrapolation Test/national_racepopBY_year_age_gnd_hhincpctile_51test.dta")
