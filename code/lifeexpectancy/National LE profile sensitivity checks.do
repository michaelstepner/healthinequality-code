* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global derived "${root}/data/derived"

if (c(os)=="Windows") global img wmf
else global img png

* Create required folders
cap mkdir "${root}/scratch/National LE profiles - sensitivity checks"
cap mkdir "${root}/scratch/National LE profiles - sensitivity checks/data"


*****************


***********************************
*** Race-adjusted vs Unadjusted ***
***********************************

* Load data
project, original("$derived/le_estimates/national_leBY_gnd_hhincpctile.dta")
use gnd pctile le_raceadj le_agg using "$derived/le_estimates/national_leBY_gnd_hhincpctile.dta", clear

* Plot scatter
twoway	(scatter le_raceadj pctile if gnd=="M", msize(small) mc(gs8) ms(circle)) ///
		(scatter le_raceadj pctile if gnd=="F", msize(small) mc(gs8) ms(diamond)) ///
		(scatter le_agg pctile if gnd=="M", msize(small) mc(navy) ms(Th)) ///
		(scatter le_agg pctile if gnd=="F", msize(small) mc(maroon) ms(Sh)), ///
		ylabel(70(5)95, gmin gmax) ///
		xtitle("Household Income Percentile") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
		legend( ///
			ring(0) pos(4) c(1) bmargin(large) ///
			order(2 1 4 3) ///
			label(1 "Men (Baseline)") ///
			label(2 "Women (Baseline)") ///
			label(3 "Men (Unadjusted)") ///
			label(4 "Women (Unadjusted)") ///
		)
graph export "${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - raceadj vs unadj.${img}", replace
project, creates("${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - raceadj vs unadj.${img}") preserve

* Export data underlying figures
export delim using "${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - raceadj vs unadj.csv", ///
	replace
project, creates("${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - raceadj vs unadj.csv") preserve


****************************************
*** Gompertz to Age 90 vs to Age 100 ***
****************************************

* Load data
project, original("$derived/le_estimates/Gompertz extrapolation to 100/national_leBY_gnd_hhincpctile_GompertzTo100.dta")
project, original("$derived/le_estimates/national_leBY_gnd_hhincpctile.dta")

use gnd pctile le_raceadj using "$derived/le_estimates/Gompertz extrapolation to 100/national_leBY_gnd_hhincpctile_GompertzTo100.dta", clear
rename le_raceadj le_raceadj_gomp100

merge 1:1 gnd pctile using "$derived/le_estimates/national_leBY_gnd_hhincpctile.dta", ///
	assert(3) nogen keepusing(le_raceadj)

* Plot scatter
twoway	(scatter le_raceadj pctile if gnd=="M", msize(small) mc(gs8) ms(circle)) ///
		(scatter le_raceadj pctile if gnd=="F", msize(small) mc(gs8) ms(diamond)) ///
		(scatter le_raceadj_gomp100 pctile if gnd=="M", msize(small) mc(navy) ms(Th)) ///
		(scatter le_raceadj_gomp100 pctile if gnd=="F", msize(small) mc(maroon) ms(Sh)), ///
		ylabel(70(5)95, gmin gmax) ///
		xtitle("Household Income Percentile") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
		legend( ///
			ring(0) pos(4) c(1) bmargin(large) ///
			order(2 1 4 3) ///
			label(1 "Men (Baseline)") ///
			label(2 "Women (Baseline)") ///
			label(3 "Men (Gompertz to 100)") ///
			label(4 "Women (Gompertz to 100)") ///
		)
graph export "${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - gomp90 vs gomp100.${img}", replace
project, creates("${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - gomp90 vs gomp100.${img}") preserve

* Export data underlying figures
export delim using "${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - gomp90 vs gomp100.csv", ///
	replace
project, creates("${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - gomp90 vs gomp100.csv") preserve


**************************************
*** Household vs Individual income ***
**************************************

* Load data
project, original("$derived/le_estimates/Individual income/national_leBY_gnd_INDincpctile.dta")
project, original("$derived/le_estimates/national_leBY_gnd_hhincpctile.dta")

use gnd indv_earn_pctile le_raceadj using "$derived/le_estimates/Individual income/national_leBY_gnd_INDincpctile.dta", clear
rename indv_earn_pctile pctile
rename le_raceadj le_raceadj_ind

merge 1:1 gnd pctile using "$derived/le_estimates/national_leBY_gnd_hhincpctile.dta", ///
	assert(3) nogen keepusing(le_raceadj)

* Plot scatter
twoway	(scatter le_raceadj pctile if gnd=="M", msize(small) mc(gs8) ms(circle)) ///
		(scatter le_raceadj pctile if gnd=="F", msize(small) mc(gs8) ms(diamond)) ///
		(scatter le_raceadj_ind pctile if gnd=="M", msize(small) mc(navy) ms(Th)) ///
		(scatter le_raceadj_ind pctile if gnd=="F", msize(small) mc(maroon) ms(Sh)), ///
		ylabel(70(5)95, gmin gmax) ///
		xtitle("Income Percentile") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
		legend( ///
			ring(0) pos(4) c(1) bmargin(large) ///
			order(2 1 4 3) ///
			label(1 "Men (Baseline)") ///
			label(2 "Women (Baseline)") ///
			label(3 "Men (Individual Income)") ///
			label(4 "Women (Individual Income)") ///
		)
graph export "${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - ind vs hh.${img}", replace
project, creates("${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - ind vs hh.${img}") preserve

* Export data underlying figures
export delim using "${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - ind vs hh.csv", ///
	replace
project, creates("${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - ind vs hh.csv") preserve
