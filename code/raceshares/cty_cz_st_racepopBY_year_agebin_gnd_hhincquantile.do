* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

/***

Add an income dimension to the local race population data.

Uses race fractions derived from the 2000 Census SF3/SF4 tables
to assign income quantiles to the race populations in the 2000-2014
Intercensal/Postcensal estimates.

***/

****************

cap program drop impute_pop_incomedim
program define impute_pop_incomedim

	/*** Take the race population data from the 2000-2014 Intercensal/Postcensal Estimates,
		 and in each year, distribute population into quantiles using race fractions.
	***/
	
	syntax , geo(name) nq(integer) qvar(name) dta_qstub(string)
	
	if !inlist("`geo'","cty","cz") error 198
	
	* Load race population data (by County x Year x 5-year Age Bin x Gender)
	project, uses("$root/data/derived/raceshares/cty_racepopBY_year_agebin_gnd.dta")
	use "$root/data/derived/raceshares/cty_racepopBY_year_agebin_gnd.dta", clear
	
	if "`geo'"=="cz" {
		* Load CZ identifiers
		project, uses("$root/data/derived/final_covariates/cty_full_covariates.dta") preserve
		merge m:1 cty using "$root/data/derived/final_covariates/cty_full_covariates.dta", ///
			assert(2 3) keepusing(cz)
		assert cty==51560 if _merge==2  // county 51560 was merged into 51005 in 2001
		drop if _merge==2
		drop _merge
	
		* Collapse to CZ level
		isid year agebin gnd cty
		collapse (sum) pop_*, by(year agebin gnd cz)
		recast long pop_*
	}
	
	* Add an income quantile dimension
	isid `geo' year agebin gnd
	expand `nq'
	bys `geo' year agebin gnd: gen byte `qvar'=_n
	order `geo' year agebin gnd `qvar'
	
	* Generate a temporary "agebin" variable corresponding to the
	* 10-year Age Bin of the income distribution we want merged in.
	rename agebin trueagebin
	assert inrange(trueagebin,35,75)
	recode trueagebin (35/44 = 35) (45/54 = 45) (55/75 = 55), gen(agebin)
	
	* Merge in higher level geo identifiers
	if "`geo'"=="cty" {
		* merge CZ and State identifiers
		project, uses("$root/data/derived/final_covariates/cty_full_covariates.dta") preserve
		merge m:1 cty using "$root/data/derived/final_covariates/cty_full_covariates.dta", ///
			assert(2 3) keepusing(cz state_id)
		assert cty==51560 if _merge==2  // county 51560 was merged into 51005 in 2001
		drop if _merge==2
		drop _merge
	}
	else if "`geo'"=="cz" {
		* merge State identifiers
		project, uses("$root/data/derived/final_covariates/cz_full_covariates.dta") preserve
		merge m:1 cz using "$root/data/derived/final_covariates/cz_full_covariates.dta", ///
			assert(3) keepusing(state_id) nogen
	}
	rename state_id st
	
	* Merge in County, CZ and State income distributions
	/*
		The master (race pop) dataset is identified by geo X year X 5-year agebin X gnd X hh_inc_quantile,
		and the using (race frac) dataset is identified by geo X 10-year agebin X hh_inc_quantile.
		
		So we are using the same household income distributions for:
			- all years
			- both 5-year agebins within a 10-year agebin
			- both genders
	*/
	if ("`geo'"=="cty") local incdist_levels cty cz st
	else if ("`geo'"=="cz")  local incdist_levels cz st
	
	foreach l in `incdist_levels' {
		project, uses("$root/data/derived/raceshares/`l'_racefractionsBY_workingagebin_`dta_qstub'.dta") preserve
		merge m:1 `l' agebin `qvar' using "$root/data/derived/raceshares/`l'_racefractionsBY_workingagebin_`dta_qstub'.dta", ///
			assert(3) keepusing(frac_of_*) nogen
		drop frac_of_total  // not useful, we'll compute total after assigning races to income bins
		rename frac_* `l'frac_*
	}
	
	
	* Drop vars only needed for merging race fractions
	keep `geo' year trueagebin gnd `qvar' pop_* *frac_*
	rename trueagebin agebin
	
	* Apply race fractions to adjust population counts
	/*
		If race fractions are missing for a given race, we go up one geographic level
		and use those race fractions *for that race*. State race fractions are always available.
		
		For example, if black county-level race fractions are missing, we might assign
		black individuals using the CZ-level black income distribution, and white individuals
		using the county-level white income distribution.
		
		One concern is that in cases where the county is richer or poorer than the CZ as a
		whole, this generates bias between races.  But in practice, race fractions are missing
		only when that race has a very small population and thus no one of that race was counted
		in the Long Form 2000 Census.  Assigning a very small population using the wrong income
		distribution results in very small errors in race shares.  We are better off assigning
		the races with a large population in an area using the most accurate income distribution
		available for them.
	*/
	assert !mi(stfrac_of_black, stfrac_of_asian, stfrac_of_hispanic, stfrac_of_other)
	foreach race in black asian hispanic other {
	
		if ("`geo'"=="cty") {
			replace pop_`race' = pop_`race' * ctyfrac_of_`race' if !mi(ctyfrac_of_`race')
			replace pop_`race' = pop_`race' * czfrac_of_`race' if mi(ctyfrac_of_`race') & !mi(czfrac_of_`race')
			replace pop_`race' = pop_`race' * stfrac_of_`race' if mi(ctyfrac_of_`race') & mi(czfrac_of_`race')
		}
		else if ("`geo'"=="cz") {
			replace pop_`race' = cond(!mi(czfrac_of_`race'), pop_`race' * czfrac_of_`race', pop_`race' * stfrac_of_`race')
		}

	}
	
	assert !mi(pop_black, pop_asian, pop_hispanic, pop_other)
	drop *frac_*
	
	* Output
	isid `geo' year agebin gnd `qvar'
	sort `geo' year agebin gnd `qvar'
	save13 "$root/data/derived/raceshares/`geo'_racepopBY_year_agebin_gnd_`dta_qstub'.dta", replace
	project, creates("$root/data/derived/raceshares/`geo'_racepopBY_year_agebin_gnd_`dta_qstub'.dta")
	
end


*********************************************************
*** Distribute race populations into income quantiles ***
*********************************************************

* County x Quartile
impute_pop_incomedim, geo(cty) nq(4) qvar(hh_inc_q) dta_qstub(hhincquartile)

* CZ x Quartile, Ventile
impute_pop_incomedim, geo(cz) nq(4) qvar(hh_inc_q) dta_qstub(hhincquartile)
impute_pop_incomedim, geo(cz) nq(20) qvar(hh_inc_v) dta_qstub(hhincventile)

* State x Quartile (aggregating from counties)

/*** Note: there are two ways this could be done.

1. Use the year 2000 state income distributions and apply them to the
	state population in each year.
	
2. Aggregate up to state-level from imputed county populations, which use
	county income distributions.
	
The result differs if some areas of the state have different population growth
than others. Ex: whites are moving to San Francisco, hispanics are moving to
San Diego, and SF & SD have different income distributions.

At the CZ level, we use CZ income distributions because CZs are local labor markets.

At the state level, we aggregate up from counties because there are many labor
markets within a state, and differences in population growth between labor markets
could be important.

We don't aggregate up from CZs because CZs cross state boundaries.

***/

* Load data
project, uses("$root/data/derived/raceshares/cty_racepopBY_year_agebin_gnd_hhincquartile.dta")
project, uses("$root/data/derived/final_covariates/cty_full_covariates.dta")
use "$root/data/derived/raceshares/cty_racepopBY_year_agebin_gnd_hhincquartile.dta", clear

* Merge on State IDs
merge m:1 cty using "$root/data/derived/final_covariates/cty_full_covariates.dta", ///
	assert(2 3) keepusing(state_id) sorted  // sorted option is necessary for exact replication
assert cty==51560 if _merge==2  // county 51560 was merged into 51005 in 2001
drop if _merge==2
drop _merge

rename state_id st

* Aggregate county populations to state level
isid cty year agebin gnd hh_inc_q
collapse (sum) pop_*, by(st year agebin gnd hh_inc_q)

* Output
save13 "$root/data/derived/raceshares/st_racepopBY_year_agebin_gnd_hhincquartile.dta", replace
project, creates("$root/data/derived/raceshares/st_racepopBY_year_agebin_gnd_hhincquartile.dta")
