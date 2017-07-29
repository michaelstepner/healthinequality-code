* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "${root}/scratch/tests"
cap mkdir "${root}/scratch/tests/Test gen_mortrates ado"

* Add ado files to project
project, original("${root}/code/ado/gen_mortrates2.ado")


/*** Test whether gen_mortrates2.ado properly handles input data.
***/


*********************************************************
*** Generate synthetic output: mortality rate dataset ***
*********************************************************

* Construct mortality rate dataset
set obs 37

gen grp=1
gen byte age_at_d=_n+39
gen lag = 2 + (age_at_d>=64) * (age_at_d-63)
gen int yod = lag + 1999

gen mortrate=exp(-10 + 0.1 * age_at_d)  // Gompertz with int=-10 and slope=0.1
gen count = 100000 in 1
replace count = cond(lag==2, 100000, count[_n-1] * (1-mortrate[_n-1])) in 2/`=_N'

* Reduce precision of pop counts (which are always integers in true data)
replace count = round(count)

* Output
save13 "${root}/scratch/tests/Test gen_mortrates ado/synthetic_mortrates.dta", replace
project, creates("${root}/scratch/tests/Test gen_mortrates ado/synthetic_mortrates.dta")


************************************************
*** Generate synthetic input: deadby dataset ***
************************************************

* Construct deadby dataset
clear
set obs 24

gen grp=1
gen age=_n+37
gen tax_yr=1999

gen long count=100000

gen byte deadby_1_Mean = 0
forvalues i=2/18 {

	local survivors count * (1-deadby_`=`i'-1'_Mean)
	local mortrate exp(-10 + 0.1 * (age+`i'))
	local deathsini `survivors' * `mortrate'

	gen double deadby_`i'_Mean = (count - `survivors' + `deathsini') / count if tax_yr + `i' <= 2014
}

* Output
save13 "${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta", replace
project, creates("${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta")


*********************
*** Perform Tests ***
*********************

*** Test with perfect input data

* Generate mortrates
project, uses("${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta")
use "${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta", clear

gen_mortrates2 grp, age(age) year(tax_yr) n(count)

* Reduce precision
recast float mortrate count, force
replace count=round(count)

* Perform comparison
project, uses("${root}/scratch/tests/Test gen_mortrates ado/synthetic_mortrates.dta") preserve
cf _all using "${root}/scratch/tests/Test gen_mortrates ado/synthetic_mortrates.dta"


*** Test with a dropped deadby column

* Generate mortrates
project, uses("${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta")
use "${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta", clear

drop deadby_3_Mean

rcof "gen_mortrates2 grp, age(age) year(tax_yr) n(count)" == 111


*** Test with a missing deadby column

* Generate mortrates
project, uses("${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta")
use "${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta", clear

replace deadby_3_Mean=.

rcof "gen_mortrates2 grp, age(age) year(tax_yr) n(count)" == 9


*** Test with missing LAST deadby column

* Generate mortrates
project, uses("${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta")
use "${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta", clear

replace deadby_15_Mean=.

gen_mortrates2 grp, age(age) year(tax_yr) n(count)

* Reduce precision
recast float mortrate count, force
replace count=round(count)

* Perform comparison
isid grp age_at_d yod
ds grp age_at_d yod, not
foreach var in `r(varlist)' {
	rename `var' gen_`var'
}

project, uses("${root}/scratch/tests/Test gen_mortrates ado/synthetic_mortrates.dta") preserve
merge 1:1 grp age_at_d yod using "${root}/scratch/tests/Test gen_mortrates ado/synthetic_mortrates.dta"

count if _merge==2
assert r(N)==1

foreach var of varlist lag mortrate count {
	assert gen_`var' == `var' | mi(gen_`var')
}


*** Test with missing unused deadby data

* Generate mortrates
project, uses("${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta")
use "${root}/scratch/tests/Test gen_mortrates ado/synthetic_deadby.dta", clear

forvalues i=3/18 {
	replace deadby_`i'_Mean=. if age!=61
}

gen_mortrates2 grp, age(age) year(tax_yr) n(count)

* Reduce precision
recast float mortrate count, force
replace count=round(count)

* Perform comparison
project, uses("${root}/scratch/tests/Test gen_mortrates ado/synthetic_mortrates.dta") preserve
cf _all using "${root}/scratch/tests/Test gen_mortrates ado/synthetic_mortrates.dta"
