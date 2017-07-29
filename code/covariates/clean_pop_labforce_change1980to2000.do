* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global cov_raw "$root/data/raw/Covariate Data"
global cov_clean "$root/data/derived/covariate_data"

* Create required folders
cap mkdir "$root/data/derived/covariate_data"

/*** County-level change in population and labor force, 1980-2000
***/

*******

* Load Census data
project, original("${cov_raw}/nhgis0007_ts_nominal_county.csv")
import delimited using "${cov_raw}/nhgis0007_ts_nominal_county.csv", clear varnames(1) rowrange(3)
destring *, replace

//generate FIPS identifier, and keep vars from 1980 and 2000
gen cty = statefp*1000 + countyfp
gen statefips = statefp
ren (a00aa1980 a00aa2000) (pop1980 pop2000) // total population, 1980 & 2000
ren (b84aa1980 b84aa2000) (lf1980 lf2000) // population 16+ in the labor force, 1980 & 2000
drop if mi(pop1980) & mi(pop2000) & mi(lf1980) & mi(lf2000)
keep cty statefips pop* lf*

* Output at county level
drop if cty==.

//recode 1 county that changed FIPS (but not boundaries) over 1980-2000
gen flag = 1 if inlist(cty,12025,12086) // Miami-Dade
sort flag cty
replace pop2000 = pop2000[_n+1] if cty==12025
replace lf2000 = lf2000[_n+1] if cty==12025
drop if cty==12086
drop flag

//calculate percent change in population and labor force
gen pop_d_2000_1980 = (pop2000 - pop1980)/pop1980
gen lf_d_2000_1980 = (lf2000 - lf1980)/lf1980

//drop values for counties that changed boundaries over 1980-2000
replace pop_d_2000_1980 = . if inlist(cty, 4012, 4027, 35006, 35061, 51780, ///
	51083, 30113, 30031, 30067)
replace lf_d_2000_1980 = . if inlist(cty, 4012, 4027, 35006, 35061, 51780, ///
	51083, 30113, 30031, 30067)
//drop Alaska (many county changes)
replace pop_d_2000_1980 = . if statefips==2
replace lf_d_2000_1980 = . if statefips==2
//(excludes population ~1m with Alaska)

project, original("${cov_raw}/cty_covariates.dta") preserve
merge 1:1 cty using "${cov_raw}/cty_covariates.dta", keepus(cz) keep(match master)
//recode CZs of 2 unmatched counties
assert statefips==2 | cty==15005 | inlist(cty,51780,30113) if _merge!=3
drop _merge
replace cz = 2200 if cty==51780
replace cz = 34402 if cty==30113
drop if cz==. //Kalawao County, Hawaii (population ~90), unmatched counties in Alaska

preserve
keep if pop_d_2000_1980!=. | lf_d_2000_1980!=.
keep cty statefips pop_d_2000_1980 lf_d_2000_1980
order cty statefips pop_d_2000_1980 lf_d_2000_1980
save13 "${cov_clean}/cty_cs_popchange_labforce.dta", replace
project, creates("${cov_clean}/cty_cs_popchange_labforce.dta")

* Output at CZ level
restore
//recode populations of CZs with county changes (38100, 38300)
expand 2 if cty==4027, gen(flag)  //Yuma County
replace cz = 38300 if flag==1  //La Paz CZ
// La Paz CZ gets a small part of the pre-split Yuma County
replace pop1980 = 13844/(106895+13844) * pop1980 if flag==1
replace lf1980 =  13844/(106895+13844)* lf1980 if flag==1
replace pop2000 = . if flag==1
replace lf2000 = . if flag==1

// Yuma CZ gets most of the pre-split Yuma County
replace pop1980 = 106895/(106895+13844) * pop1980 if flag==0 & cty==4027
replace lf1980 = 106895/(106895+13844) * lf1980 if flag==0 & cty==4027

//collapse, and calculate percent change in population and labor force, 1980-2000
collapse (sum) pop1980 pop2000 lf1980 lf2000, by(cz)

gen pop_d_2000_1980 = (pop2000 - pop1980)/pop1980
gen lf_d_2000_1980 = (lf2000 - lf1980)/lf1980

keep cz pop_d_2000_1980 lf_d_2000_1980
save13 "${cov_clean}/cz_cs_popchange_labforce.dta", replace
project, creates("${cov_clean}/cz_cs_popchange_labforce.dta")
