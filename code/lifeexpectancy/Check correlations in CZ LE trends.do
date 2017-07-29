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

* Create required folders
cap mkdir "${root}/scratch/CZ trend correlations"

/*** Compute population-weighted correlations in CZ LE trends:
		- Between unadjusted and race-adjusted trends
		- Between trends for men and for women
***/

*** Check correlation between unadjusted and race-adjusted trends

* Load data
project, original("${derived}/le_trends/cz_letrendsBY_gnd_hhincquartile.dta")
use "${derived}/le_trends/cz_letrendsBY_gnd_hhincquartile.dta", clear

* Merge on CZ populations
project, original("${root}/data/derived/final_covariates/cz_full_covariates.dta") preserve
merge m:1 cz using "${root}/data/derived/final_covariates/cz_full_covariates.dta", ///
	assert(2 3) keep(3) nogen ///
	keepusing(pop2000)

* Compute population-weighted correlations by gender
bys gnd: corr le_agg_b_year le_raceadj_b_year [w=pop2000]

* Compute population-weighted correlations by gender and income quartile
isid cz gnd hh_inc_q
statsby corr_raceadj_unadj = r(rho), by(gnd hh_inc_q) clear: corr le_raceadj_b_year le_agg_b_year [w=pop2000]

sum corr_raceadj_unadj
scalarout using "${root}/scratch/CZ trend correlations/Correlation between CZ LE trends raceadj and unadj.csv", ///
	replace ///
	id("Min corr b/w race-unadj and race-adj CZ trends in a Gender x Quartile") ///
	num(`=r(min)') fmt(%9.3f)
project, creates("${root}/scratch/CZ trend correlations/Correlation between CZ LE trends raceadj and unadj.csv")


*** Check correlation between genders

* Load data
project, original("${derived}/le_trends/cz_letrendsBY_gnd_hhincquartile.dta")
use "${derived}/le_trends/cz_letrendsBY_gnd_hhincquartile.dta", clear
drop le_agg_b_cons le_raceadj_b_cons
rename *_b_year *_b_year_

reshape wide le_agg_b_year_ le_raceadj_b_year_, i(cz hh_inc_q) j(gnd) string

* Merge on CZ populations
project, original("${root}/data/derived/final_covariates/cz_full_covariates.dta") preserve
merge m:1 cz using "${root}/data/derived/final_covariates/cz_full_covariates.dta", ///
	assert(2 3) keep(3) nogen ///
	keepusing(pop2000)

* Compute correlations across genders
corr le_agg_b_year_F le_agg_b_year_M [w=pop2000]
corr le_raceadj_b_year_F le_raceadj_b_year_M [w=pop2000]

* Compute correlations across genders by Income Quartile
bys hh_inc_q: corr le_agg_b_year_F le_agg_b_year_M [w=pop2000]
bys hh_inc_q: corr le_raceadj_b_year_F le_raceadj_b_year_M [w=pop2000]
