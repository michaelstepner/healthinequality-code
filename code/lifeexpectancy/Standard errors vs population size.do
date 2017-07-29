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
cap mkdir "${root}/scratch/Standard errors vs population size"
cap mkdir "${root}/scratch/Standard errors vs population size/data"

*************


*************************************************
*** LE levels, CZ by Gender x Income Quartile ***
*************************************************

project, original("$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile.dta")
project, original("${derived}/final_covariates/cz_pop.dta")
use "$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile.dta", clear
merge m:1 cz using "${derived}/final_covariates/cz_pop.dta", ///
	assert(2 3) keep(3) nogen

gen grp = gnd + string(hh_inc_q)

binscatter sd_le_raceadj pop2000 if hh_inc_q == 1 |  hh_inc_q == 4, ///
	by(grp) xscale(log) line(connect) m(o t s d) ///
	ylab(0(0.5)2.5, gmin gmax) ///
	xlabel(1e4 "10,000" 1e5 "100,000" 1e6 "1,000,000" 1e7 "10,000,000        ") ///
	xtitle("CZ Population (log scale)") ytitle("Standard Error of Expected Age Death in Years") ///
	legend(ring(0) pos(2) c(1) order(2 4 1 3) bmargin(large) ///
	label(1 "Income Q1: Women") label(2 "Income Q4: Women") label(3 "Income Q1: Men") label(4 "Income Q4: Men")) ///
	savedata("${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - CZ LE levels") replace
project, creates("${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - CZ LE levels.csv") preserve
	
graph export "${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - CZ LE levels.${img}", replace
project, creates("${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - CZ LE levels.${img}") preserve

*** Reported numbers

* Mean population-weighted SD
isid cz gnd hh_inc_q
sum sd_le_raceadj [w=pop2000]

scalarout using "${root}/scratch/Standard errors vs population size/Reported SDs.csv", ///
	replace ///
	id("Mean (pop-weighted) SE of CZ by Gender x Quartile LE levels") ///
	num(`=r(mean)') fmt(%9.2f)
	
* Fraction of pop in CZs with pop > 100k
project, original("${derived}/final_covariates/cz_pop.dta")
use "${derived}/final_covariates/cz_pop.dta", clear

sum pop2000, meanonly
local totalpop=r(sum)

sum pop2000 if pop2000>100000
scalarout using "${root}/scratch/Standard errors vs population size/Reported SDs.csv", ///
	id("Fraction of US population in CZs with pop > 100 000") ///
	num(`=r(sum)/`totalpop'') fmt(%9.2f)


*****************************************************
*** LE levels, County by Gender x Income Quartile ***
*****************************************************

project, original("$derived/le_estimates_stderr/cty_SEleBY_gnd_hhincquartile.dta")
project, original("${derived}/final_covariates/cty_full_covariates.dta")
use "$derived/le_estimates_stderr/cty_SEleBY_gnd_hhincquartile.dta", clear
merge m:1 cty using "${derived}/final_covariates/cty_full_covariates.dta", ///
	assert(2 3) keep(3) nogen keepusing(cty_pop2000)

gen grp = gnd + string(hh_inc_q)

binscatter sd_le_raceadj cty_pop2000 if hh_inc_q == 1 |  hh_inc_q == 4, ///
	by(grp) xscale(log) line(connect) m(o t s d) ///
	xlabel(1e4 "10,000" 1e5 "100,000" 1e6 "1,000,000" 1e7 "10,000,000        ") ///
	ylab(0(0.5)2.5, gmin gmax) ///
	xtitle("County Population (log scale)") ytitle("Standard Error of Expected Age Death in Years") ///
	legend(ring(0) pos(2) c(1) order(2 4 1 3) bmargin(large) ///
	label(1 "Income Q1: Women") label(2 "Income Q4: Women") label(3 "Income Q1: Men") label(4 "Income Q4: Men")) ///
	savedata("${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - County LE levels") replace
project, creates("${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - County LE levels.csv") preserve
	
graph export "${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - County LE levels.${img}", replace
project, creates("${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - County LE levels.${img}") preserve

*** Reported numbers

* Mean population-weighted SD
isid cty gnd hh_inc_q
sum sd_le_raceadj [w=cty_pop2000]

scalarout using "${root}/scratch/Standard errors vs population size/Reported SDs.csv", ///
	id("Mean (pop-weighted) SE of County by Gender x Quartile LE levels") ///
	num(`=r(mean)') fmt(%9.2f)

*************************************************
*** LE trends, CZ by Gender x Income Quartile ***
*************************************************

project, original("$derived/le_trends_stderr/cz_SEletrendsBY_gnd_hhincquartile.dta")
project, original("${derived}/final_covariates/cz_pop.dta")
use "$derived/le_trends_stderr/cz_SEletrendsBY_gnd_hhincquartile.dta", clear
merge m:1 cz using "${derived}/final_covariates/cz_pop.dta", ///
	assert(2 3) keep(3) nogen

gen grp = gnd + string(hh_inc_q)

binscatter sd_le_raceadj_b_year pop2000 if hh_inc_q == 1 |  hh_inc_q == 4, ///
	by(grp) xscale(log) line(connect) m(o t s d) ///
	ylab(0(0.05)0.25, gmin gmax) ///
	xlabel(5e5 "500,000" 1e6 "1,000,000" 2e6 "2,000,000" 4e6 "4,000,000" 1e7 "10,000,000        ") ///
	xtitle("CZ Population (log scale)") ytitle("Standard Error of Annual Change Estimate in Years") ///
	legend(ring(0) pos(2) c(1) order(2 4 1 3) bmargin(large) ///
	label(1 "Income Q1: Women") label(2 "Income Q4: Women") label(3 "Income Q1: Men") label(4 "Income Q4: Men")) ///
	savedata("${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - CZ LE trends") replace
project, creates("${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - CZ LE trends.csv") preserve

graph export "${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - CZ LE trends.${img}", replace
project, creates("${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - CZ LE trends.${img}") preserve

*** Reported numbers

* Mean population-weighted SD
isid cz gnd hh_inc_q
sum sd_le_raceadj_b_year [w=pop2000]

scalarout using "${root}/scratch/Standard errors vs population size/Reported SDs.csv", ///
	id("Mean (pop-weighted) SE of CZ by Gender x Quartile LE trends") ///
	num(`=r(mean)') fmt(%9.2f)


****************************************************
*** LE trends, State by Gender x Income Quartile ***
****************************************************

project, original("$derived/le_trends_stderr/st_SEletrendsBY_gnd_hhincquartile.dta")
project, original("${derived}/final_covariates/st_pop.dta")

use "$derived/le_trends_stderr/st_SEletrendsBY_gnd_hhincquartile.dta", clear
merge m:1 st using "${derived}/final_covariates/st_pop.dta", assert(3) nogen

*** Reported numbers

* Mean population-weighted SD
isid st gnd hh_inc_q
sum sd_le_raceadj_b_year [w=pop2000]

scalarout using "${root}/scratch/Standard errors vs population size/Reported SDs.csv", ///
	id("Mean (pop-weighted) SE of State by Gender x Quartile LE trends") ///
	num(`=r(mean)') fmt(%9.2f)
	
*****************************************
*** Project creates, reported numbers ***
*****************************************

project, creates("${root}/scratch/Standard errors vs population size/Reported SDs.csv")
