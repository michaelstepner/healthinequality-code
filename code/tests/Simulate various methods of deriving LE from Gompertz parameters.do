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

* Load LE functions
project, original("${root}/code/ado/generate_le_with_raceadj.ado")
include "$root/code/ado/generate_le_with_raceadj.ado"

* Add ado files to project
project, original("${root}/code/ado/fastregby.ado")


/*** Simulates various methods for integrating the survival curve based on the
	 "discretized Gompertz parameters" and compares their results to the true LE.
***/

*************


* Load Gompertz parameters for national percentiles
project, original("${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta")
use "${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta", clear
isid gnd pctile
keep gnd pctile gomp_int gomp_slope

* Create an age dimension
expand 76-40+1
bys gnd pctile: gen age_at_d = 40 + _n - 1

* Compute discrete-time mortality rates at age [x,x+1)
gen mort_discrete = 1 - exp( 1 / gomp_slope * ( exp(gomp_int + gomp_slope*age_at_d) - exp(gomp_int + gomp_slope*(age_at_d+1)) ) )

* Estimate discretized Gompertz parameters
gen log_mort_discrete = log(mort_discrete)
fastregby log_mort_discrete age_at_d, by(gnd pctile) clear
ren (_b_age_at_d _b_cons) (gomp_slope_estimated gomp_int_estimated)
order gomp_int_estimated gomp_slope_estimated, last

* Merge in true Gompertz parameters
merge 1:1 gnd pctile using "${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta", ///
	assert(2 3) keep(3) nogen keepusing(gomp*)
rename (gomp_int gomp_slope) (gomp_int_true gomp_slope_true)

* Adjust Gompertz intercept to midpoint of integer bins, since "age 40" in estimation is actually age [40,41)
gen gomp_int_adjusted = gomp_int_estimated - 0.5 * gomp_slope_estimated


* Compute expected life years at true Gompertz parameters
rename (gomp_int_true gomp_slope_true) (gomp_int gomp_slope)
gen_gomp_lifeyears_cont, startage(40) endage(90)
rename expectedLY_gomp expectedLY_true
rename (gomp_int gomp_slope) (gomp_int_true gomp_slope_true)

* Compute expected life years at estimated unadjusted Gompertz parameters
rename (gomp_int_estimated gomp_slope_estimated) (gomp_int gomp_slope)
gen_gomp_lifeyears_cont, startage(40) endage(90)
rename expectedLY_gomp expectedLY_est
rename (gomp_int gomp_slope) (gomp_int_estimated gomp_slope_estimated)

* Compute expected life years at estimated adjusted Gompertz parameters
rename (gomp_int_adjusted gomp_slope_estimated) (gomp_int gomp_slope)
gen_gomp_lifeyears_cont, startage(40) endage(90)
rename expectedLY_gomp expectedLY_adj
rename (gomp_int gomp_slope) (gomp_int_adjusted gomp_slope_estimated)

* Compute expected life years at estimated Gompertz parameters, DISCRETE method
rename (gomp_int_estimated gomp_slope_estimated) (gomp_int gomp_slope)
mata: gen_gomp_lifeyears_disc(40, 90)
rename expectedLY_gomp expectedLY_estdiscrete
rename (gomp_int gomp_slope) (gomp_int_estimated gomp_slope_estimated)


foreach t in est adj estdiscrete {
	gen diff_`t' = expectedLY_`t' - expectedLY_true
	gen reldiff_`t' = diff_`t' / expectedLY_true
}


sum diff*
sum reldiff*
