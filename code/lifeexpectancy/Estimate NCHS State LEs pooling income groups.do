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
cap mkdir "${root}/data/derived/Mortality Rates/NCHS state pooled income"
cap mkdir "${root}/data/derived/Gompertz Parameters/NCHS state pooled income"
cap mkdir "${root}/data/derived/le_estimates/NCHS state pooled income"


***********************
*** Mortality rates ***
***********************

* Load NCHS State mortality data by Gender x Age, pooling 1999-2014
project, original("$root/data/raw/NCHS Underlying Cause of Death/Underlying Cause of Death, 1999-2014, by state, gender, and age.txt")
import delimited "$root/data/raw/NCHS Underlying Cause of Death/Underlying Cause of Death, 1999-2014, by state, gender, and age.txt", clear
drop if mi(gendercode)

assert mi(notes)
drop notes

keep if inrange(singleyearagescode,40,76)
destring population, replace

* Check that there are 51 states x 2 genders x 37 ages
assert _N == 51*2*37

* Keep required vars and use our standard var names and formats
keep statecode singleyearagescode gendercode population deaths
ren (statecode singleyearagescode gendercode population) ///
	(st        age_at_d           gnd        count     )
	
gen double mortrate = deaths/count
drop deaths

* Output
save13 "${root}/data/derived/Mortality Rates/NCHS state pooled income/st_NCHSmortratesBY_gnd_age.dta", replace
project, creates("${root}/data/derived/Mortality Rates/NCHS state pooled income/st_NCHSmortratesBY_gnd_age.dta") preserve


***************************
*** Gompertz parameters ***
***************************

* Calculate Gompertz parameters from mortality rates
project, original("${root}/code/ado/estimate_gompertz2.ado") preserve
project, original("${root}/code/ado/mle_gomp_est.ado") preserve
project, original("${root}/code/ado/fastregby_gompMLE_julia.ado") preserve
project, original("${root}/code/ado/estimate_gompertz.jl") preserve

estimate_gompertz2 st gnd, age(age_at_d) mort(mortrate) n(count) ///
	type(mle)

* Output
save13 "${derived}/Gompertz Parameters/NCHS state pooled income/st_NCHSgompBY_gnd.dta", replace
project, creates("${derived}/Gompertz Parameters/NCHS state pooled income/st_NCHSgompBY_gnd.dta") preserve


***********************
*** Life expectancy ***
***********************

generate_le_with_raceadj, by(st gnd) ///
	gompparameters("${derived}/Gompertz Parameters/NCHS state pooled income/st_NCHSgompBY_gnd.dta") ///
	raceshares("${derived}/raceshares/st_racesharesBY_agebin_gnd.dta") ///
	saving("${derived}/le_estimates/NCHS state pooled income/st_NCHSleBY_gnd.dta")
