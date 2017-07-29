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
cap mkdir "${root}/data/derived/Gompertz Parameters/bootstrap"
cap mkdir "${root}/data/derived/le_estimates/bootstrap"

* Import bootstrap config
project, original("$root/code/set_bootstrap.do")
include "$root/code/set_bootstrap.do"

/*** Perform parametric bootstrap of Gompertz parameters
	 and combine with non-parametric bootstrap of race shifters,
	 to create bootstrapped estimates of life expectancy.
***/


project, original("${root}/code/ado/simulated_delta.ado")
project, original("${root}/code/ado/generate_le_with_raceadj.ado")

*******
*** National, by Gender x Income Percentile
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta")
use "${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta", replace

* Draw simulations of new Gompertz parameters
simulated_delta gnd pctile, reps(${reps}) seed(606005614)

* Output parametric bootstrapped Gompertz parameters
sort gnd pctile sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_national_gompBY_gnd_hhincpctile.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_national_gompBY_gnd_hhincpctile.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(gnd pctile) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_national_gompBY_gnd_hhincpctile.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/national_racesharesBY_age_gnd_hhincpctile.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile.dta")  // formerly national_LE_bootstrap.dta


*******
*** National, by Gender x Income Percentile x Year
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile_year.dta")
use "${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile_year.dta", replace

* Draw simulations of new Gompertz parameters
simulated_delta gnd pctile year, reps(${reps}) seed(488879442)

* Output parametric bootstrapped Gompertz parameters
sort gnd pctile year sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_national_gompBY_gnd_hhincpctile_year.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_national_gompBY_gnd_hhincpctile_year.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(gnd pctile year) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_national_gompBY_gnd_hhincpctile_year.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/national_racesharesBY_year_age_gnd_hhincpctile.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile_year.dta")


*******
*** CZ by Gender (positive income only)
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/cz_gompBY_gnd.dta")
use "${derived}/Gompertz Parameters/cz_gompBY_gnd.dta", replace

* Draw simulations of new Gompertz parameters
simulated_delta cz gnd, reps(${reps}) seed(980451454)

* Output parametric bootstrapped Gompertz parameters
sort cz gnd sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(cz gnd) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd.dta")


*******
*** CZ, by Gender x Income Quartile
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincquartile.dta")
use "${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincquartile.dta", replace
assert inrange(hh_inc_q, 1, 4)

* Draw simulations of new Gompertz parameters
simulated_delta cz gnd hh_inc_q, reps(${reps}) seed(715510228)

* Output parametric bootstrapped Gompertz parameters
sort cz gnd hh_inc_q sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincquartile.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincquartile.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(cz gnd hh_inc_q) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincquartile.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile.dta")  // formerly cz_le_quartile_bootstrap.dta


*******
*** CZ, by Gender x Income Quartile x Year
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincquartile_year.dta")
use "${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincquartile_year.dta", replace
assert inrange(hh_inc_q, 1, 4)

* Draw simulations of new Gompertz parameters
simulated_delta cz gnd hh_inc_q year, reps(${reps}) seed(374273802)

* Output parametric bootstrapped Gompertz parameters
sort cz gnd hh_inc_q year sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincquartile_year.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincquartile_year.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(cz gnd hh_inc_q year) maxage_gomp_parameterfit(63) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincquartile_year.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_year_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile_year.dta")  // formerly cz_le_quartile_yod_bootstrap.dta


*******
*** CZ, by Gender x Income Ventile
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincventile.dta")
use "${derived}/Gompertz Parameters/cz_gompBY_gnd_hhincventile.dta", replace
assert inrange(hh_inc_v, 1, 20)

* Draw simulations of new Gompertz parameters
simulated_delta cz gnd hh_inc_v, reps(${reps}) seed(426170716)

* Output parametric bootstrapped Gompertz parameters
sort cz gnd hh_inc_v sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincventile.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincventile.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(cz gnd hh_inc_v) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_cz_gompBY_gnd_hhincventile.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincventile.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincventile.dta")


*******
*** State, by Gender x Income Quartile
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/st_gompBY_gnd_hhincquartile.dta")
use "${derived}/Gompertz Parameters/st_gompBY_gnd_hhincquartile.dta", replace
assert inrange(hh_inc_q, 1, 4)

* Draw simulations of new Gompertz parameters
simulated_delta st gnd hh_inc_q, reps(${reps}) seed(580334491)

* Output parametric bootstrapped Gompertz parameters
sort st gnd hh_inc_q sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_st_gompBY_gnd_hhincquartile.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_st_gompBY_gnd_hhincquartile.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(st gnd hh_inc_q) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_st_gompBY_gnd_hhincquartile.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/st_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_st_leBY_gnd_hhincquartile.dta")


*******
*** State, by Gender x Income Quartile x Year
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/st_gompBY_gnd_hhincquartile_year.dta")
use "${derived}/Gompertz Parameters/st_gompBY_gnd_hhincquartile_year.dta", replace
assert inrange(hh_inc_q,1,4)

* Draw simulations of new Gompertz parameters
simulated_delta st gnd hh_inc_q year, reps(${reps}) seed(468649260)

* Output parametric bootstrapped Gompertz parameters
sort st gnd hh_inc_q year sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_st_gompBY_gnd_hhincquartile_year.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_st_gompBY_gnd_hhincquartile_year.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(st gnd hh_inc_q year) maxage_gomp_parameterfit(63) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_st_gompBY_gnd_hhincquartile_year.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/st_racesharesBY_year_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_st_leBY_gnd_hhincquartile_year.dta")  // formerly st_le_quartile_yod_bootstrap.dta


*******
*** County, by Gender x Income Quartile
*******

* Load Gompertz parameter estimates
project, original("${derived}/Gompertz Parameters/cty_gompBY_gnd_hhincquartile.dta")
use "${derived}/Gompertz Parameters/cty_gompBY_gnd_hhincquartile.dta", replace
assert inrange(hh_inc_q,1,4)

* Draw simulations of new Gompertz parameters
simulated_delta cty gnd hh_inc_q, reps(${reps}) seed(943423605)

* Output parametric bootstrapped Gompertz parameters
sort cty gnd hh_inc_q sample_num
save13 "${derived}/Gompertz Parameters/bootstrap/bootstrap_cty_gompBY_gnd_hhincquartile.dta", replace
project, creates("${derived}/Gompertz Parameters/bootstrap/bootstrap_cty_gompBY_gnd_hhincquartile.dta")

* Calculate bootstrapped life expectancies
generate_le_with_raceadj, by(cty gnd hh_inc_q) bootstrap_samplevar(sample_num) ///
	gompparameters("${derived}/Gompertz Parameters/bootstrap/bootstrap_cty_gompBY_gnd_hhincquartile.dta") ///
	raceshifters("${derived}/NLMS/bootstrap/bootstrap_raceshifters_BYsex.dta") ///
	raceshares("$derived/raceshares/cty_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/bootstrap/bootstrap_cty_leBY_gnd_hhincquartile.dta")  // formerly cty_le_quartile_bootstrap.dta
