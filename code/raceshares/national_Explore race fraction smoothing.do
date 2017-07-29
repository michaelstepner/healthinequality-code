* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "$root/scratch/Race fraction smoothing figs"

/*** 1. Visualize the smoothing of racial income distributions using
		different lowess bandwidths.
	 
		Separately by:
		 - Race
		 - Age

	 2. Verify whether the smoothed pecentiles are approximately equal sized.
***/


****************
*** Programs ***
****************

cap program drop smoothing_graph
program define smoothing_graph
	/*** For a given Lowess bandwidth, create a graph of the lowess-smoothed
		 racial income distribution and the underlying scatterpoints.
	***/

	syntax , race(string) age(integer) income_pctile(varname) lowess_bw(real) [ export ]

	if "`race'"=="all" {
		foreach race in black asian hispanic other {
			smoothing_graph, race(`race') age(`age') income_pctile(`income_pctile') lowess_bw(`lowess_bw') `export'
		}
	}
	else {

		tw  (lowess frac_of_`race' `income_pctile' if age==`age' & gnd=="M" & `income_pctile'>0, bw(`lowess_bw')) ///
			(lowess frac_of_`race' `income_pctile' if age==`age' & gnd=="F" & `income_pctile'>0, bw(`lowess_bw')) ///
			(scatter frac_of_`race' `income_pctile' if age==`age' & gnd=="M" & `income_pctile'>0, mc(navy) ms(o)) ///
			(scatter frac_of_`race' `income_pctile' if age==`age' & gnd=="F" & `income_pctile'>0, mc(maroon) ms(o)) ///
			(scatter frac_of_`race' `income_pctile' if age==`age' & gnd=="M" & `income_pctile'<=0, mc(navy) ms(T)) ///
			(scatter frac_of_`race' `income_pctile' if age==`age' & gnd=="F" & `income_pctile'<=0, mc(maroon) ms(T)) ///
			, ///
			legend(lab(1 "Male") lab(2 "Female") order(1 2)) ///
			ytitle("Fraction of `race' age `age' population")
		if ("`export'"=="export") {
			local exportfile ${root}/scratch/Race fraction smoothing figs/racefrac_age`age'`race'_bw0`=subinstr("`lowess_bw'",".","",.)'.png
			graph export `"`exportfile'"', replace
			project, creates(`"`exportfile'"') preserve
		}
		
		*lowess frac_of_`race' `income_pctile' if age==`age' & `income_pctile'>0, by(gnd) bw(`lowess_bw')
		*if ("`export'"=="export") graph export "$root/scratch/lowess_racefrac_age`age'`race'_BY_sex_hhincpctile.png", replace
		
	}

end

************************************************
*** Visualize different smoothing bandwidths ***
************************************************

* Load data
project, original("$root/data/derived/raceshares/national_racefractionsBY_workingage_gnd_hhincpctile.dta")
use "$root/data/derived/raceshares/national_racefractionsBY_workingage_gnd_hhincpctile.dta", clear
drop smoothfrac_*

* Generate and save lowess figs
forvalues a=40(5)60 {
	smoothing_graph, race(all) age(`a') income_pctile(hh_inc_pctile) lowess_bw(0.2) export
	smoothing_graph, race(all) age(`a') income_pctile(hh_inc_pctile) lowess_bw(0.3) export
}


*********************************************************
*** Check population size in smoothed percentile bins ***
*********************************************************

* Load data
project, original("$root/data/derived/raceshares/national_racefractionsBY_workingage_gnd_hhincpctile.dta")
use "$root/data/derived/raceshares/national_racefractionsBY_workingage_gnd_hhincpctile.dta", clear

* Collapse away income dimension
isid age gnd hh_inc_pctile
collapse (sum) pop_*, by(age gnd)

* Generate an income bin dimension
expand 102
bys age gnd: gen int hh_inc_pctile = _n - 2
replace hh_inc_pctile=-2 if hh_inc_pctile==-1
order age gnd hh_inc_pctile

* Merge back in racial income distributions
merge 1:1 age gnd hh_inc_pctile using "$root/data/derived/raceshares/national_racefractionsBY_workingage_gnd_hhincpctile.dta", ///
	assert(3) keepusing(smoothfrac_*) nogen

* Apply race fractions to adjust population counts
foreach race in black asian hispanic other {
	replace pop_`race' = pop_`race' * smoothfrac_of_`race'
}
drop smoothfrac_*

* Generate total population
gen double pop_total = pop_black + pop_asian + pop_hispanic + pop_other

* Analyze variation in total population across income percentiles
egen max_percentile_pop=max(pop_total) if hh_inc_pctile>0, by(age gnd)
egen min_percentile_pop=min(pop_total) if hh_inc_pctile>0, by(age gnd)
egen mean_percentile_pop=mean(pop_total) if hh_inc_pctile>0, by(age gnd)

collapse (mean) *_percentile_pop, by(age gnd)

* Study relative error in population size of income percentiles
gen relerr=(max_percentile_pop-min_percentile_pop)/mean_percentile_pop
sum relerr, d
