* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "${root}/scratch/State Gini Correlations"

* Erase output numbers
cap erase "${root}/scratch/State Gini Correlations/State income inequality correlations.csv"

* Set convenient globals
global derived "${root}/data/derived"
global raw "$root/data/raw"

****************

* Import State Gini Index Data
project, relies_on("${raw}/State Gini Index/ACS_06_EST_B19083.txt")
project, original("${raw}/State Gini Index/ACS_06_EST_B19083_with_ann.csv")
import delimited "${raw}/State Gini Index/ACS_06_EST_B19083_with_ann.csv", varnames(2) rowrange(2) clear 
ren (id2 geography estimateginiindex) (state_id statename gini2006)
keep state_id statename gini2006
keep if inrange(state_id,1,56)
tempfile state_gini
save `state_gini'

project, original("${derived}/final_covariates/cty_full_covariates.dta")
use "${derived}/final_covariates/cty_full_covariates.dta", clear
collapse (sum) st_pop2000 = cty_pop2000, by(state_id)
merge 1:1 state_id using `state_gini', assert(3) nogen
ren state_id st

project, original("${derived}/le_estimates/st_leBY_gnd_hhincquartile.dta") preserve
merge 1:m st using "${derived}/le_estimates/st_leBY_gnd_hhincquartile.dta", nogen assert(match) keepusing(gnd hh_inc_q le_raceadj)
ren le_raceadj le_raceadj_q
reshape wide le_raceadj_q, i(st gnd) j(hh_inc_q)

project, original("${derived}/le_estimates/st_leBY_gnd.dta") preserve
merge 1:1 st gnd using "${derived}/le_estimates/st_leBY_gnd.dta", nogen assert(match) keepusing(le_raceadj)
collapse (mean) le_raceadj*, by(st st_pop2000 statename gini2006)

* Output correlations between Gini and LE
corr_reg le_raceadj gini2006 [w=st_pop2000], vce(robust)

scalarout using "${root}/scratch/State Gini Correlations/State income inequality correlations.csv", ///
	id("Corr of state Gini coefficient with LE pooling all income quartiles: coef") ///
	num(`=_b[vb]') fmt(%9.2f)
test vb=0
scalarout using "${root}/scratch/State Gini Correlations/State income inequality correlations.csv", ///
	id("Corr of state Gini coefficient with LE pooling all income quartiles: pval") ///
	num(`=r(p)') fmt(%9.2f)


corr_reg le_raceadj_q1 gini2006 [w=st_pop2000], vce(robust)

scalarout using "${root}/scratch/State Gini Correlations/State income inequality correlations.csv", ///
	id("Corr of state Gini coefficient with LE pooling all income quartiles: coef") ///
	num(`=_b[vb]') fmt(%9.2f)
test vb=0
scalarout using "${root}/scratch/State Gini Correlations/State income inequality correlations.csv", ///
	id("Corr of state Gini coefficient with LE pooling all income quartiles: pval") ///
	num(`=r(p)') fmt(%9.2f)

project, creates("${root}/scratch/State Gini Correlations/State income inequality correlations.csv")

