
* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global raw_data "${root}/data/raw"
global derived "${root}/data/derived"

* Create required folders
cap mkdir "${root}/data/derived/Gompertz Parameters"
cap mkdir "${root}/data/derived/Gompertz Parameters/OLS"

/*** Test whether all observations are included in mortality rate files
loaded in estimate_irs_gompertz_parameters.do.
***/


********************************************************************
**************  National Life Expectancy Estimates *****************
********************************************************************

* Load mortality rates
project, original("${derived}/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta")
use "${derived}/Mortality Rates/national_mortratesBY_gnd_hhincpctile_age_year.dta", clear
keep if age_at_d >= 40

* Assert that the correct number of observations exist per age
forval age = 40/63 { // full years 2001-2014
	bys age_at_d: assert _N == 2*100*(2014-2001+1) if age_at_d == `age'
}

forval age = 64/76 { // years 2001-2013 for age 64, 2001-2012 for age 65, etc.
	bys age_at_d: assert _N == 2*100*(76-`age'+1) if age_at_d == `age'
}


********************************************************************
*********** Life Expectancy Estimates by Commuting Zone ************
********************************************************************

* Load mortality rates
project, original("${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/cz_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d>=40
assert inrange(hh_inc_q, 1 ,4)

* Check if correct number of observations exist per CZ with pop >= 25k
merge m:1 cz using "$derived/final_covariates/cz_pop.dta", nogen keep(match master)
keep if pop2000 >= 25000

* Should be 2*14*(63-40+1) + 2*(13+12+11+10+9+8+7+6+5+4+3+2+1) = 854 observations per CZ x quartile
collapse (count) cz_q_obs = mortrate, by(hh_inc_q cz)
bys cz: assert _N==4
count if cz_q_obs!=854
di in red "Fraction of quartile x CZ groups missing observations : "`r(N)'/_N // 2.5% of CZ x quartiles are missing observations

* Should be 854*4 = 3,416 observations per CZ
collapse (sum) cz_obs = cz_q_obs, by(cz)
count if cz_obs!=3416
di in red "Fraction of CZs missing observations : "`r(N)'/_N // 9.7% of CZs are missing observations


********************************************************************
*************** Life Expectancy Estimates by County ****************
********************************************************************

* Load mortality rates
project, original("${derived}/Mortality Rates/cty_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/cty_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d>=40
assert inrange(hh_inc_q, 1 ,4)

* Check if correct number of observations exist per county with pop >= 25k
merge m:1 cty using "$derived/final_covariates/cty_full_covariates.dta", nogen keep(match master) keepus(cty_pop2000)
keep if cty_pop2000 >= 25000

* Should be 2*14*(63-40+1) + 2*(13+12+11+10+9+8+7+6+5+4+3+2+1) = 854 observations per county x quartile
collapse (count) cty_q_obs = mortrate, by(hh_inc_q cty)
bys cty: assert _N==4
count if cty_q_obs!=854
di in red "Fraction of quartile x county groups missing observations : "`r(N)'/_N // 6.5% of county x quartiles are missing observations

* Should be 854*4 = 3,416 observations per county
collapse (sum) cty_obs = cty_q_obs, by(cty)
count if cty_obs!=3416
di in red "Fraction of counties missing observations : "`r(N)'/_N // 21.4% of counties are missing observations


********************************************************************
*************** Life Expectancy Estimates by State *****************
********************************************************************

* Load mortality rates
project, original("${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta")
use "${derived}/Mortality Rates/st_mortratesBY_gnd_hhincquartile_age_year.dta", clear
keep if age_at_d >= 40
assert inrange(hh_inc_q, 1 ,4)

* Check if correct number of observations exist per state

* Should be 2*14*(63-40+1) + 2*(13+12+11+10+9+8+7+6+5+4+3+2+1) = 854 observations per state x quartile
collapse (count) st_q_obs = mortrate, by(hh_inc_q st)
bys st: assert _N==4
count if st_q_obs!=854
di in red "Fraction of quartile x state groups missing observations : "`r(N)'/_N // 0% of state x quartiles are missing observations

* Should be 854*4 = 3,416 observations per county
collapse (sum) st_obs = st_q_obs, by(st)
count if st_obs!=3416
di in red "Fraction of states missing observations : "`r(N)'/_N // 0% of states are missing observations
