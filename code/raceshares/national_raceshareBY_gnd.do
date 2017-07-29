* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}


************************

project, original("$root/code/ado/compute_raceshares.ado")

* Load age 40 race population data by Gender from 2000 Census
project, uses("$root/data/derived/raceshares/national_2000age40_racepopBY_gnd.dta")
use "$root/data/derived/raceshares/national_2000age40_racepopBY_gnd.dta", clear

* Generate race shares
compute_raceshares, by(gnd)

* Output
isid gnd
save13 "$root/data/derived/raceshares/national_2000age40_racesharesBY_gnd.dta", replace
project, creates("$root/data/derived/raceshares/national_2000age40_racesharesBY_gnd.dta")
