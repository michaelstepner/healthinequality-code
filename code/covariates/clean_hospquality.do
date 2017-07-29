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

/*** Hospital Compare Data

30-day hospital mortality rates for heart attacks, pneumonia, heart failure.
Averaged over years 2002-2013.

***/

*******


*** Create SSA-cty FIPS crosswalk
project, original("${cov_raw}/ssa_cty_cw.dta")
use "${cov_raw}/ssa_cty_cw.dta", clear
*drop double-coding of miami-dade
drop if fips=="12086"
isid ssa
tempfile ssa_cty
save `ssa_cty'


*** Load data
project, original("${cov_raw}/Adj_mortality_2002to2013_byCounty.dta")
use "${cov_raw}/Adj_mortality_2002to2013_byCounty.dta", clear
drop service
drop if substr(cnty,-3,3)=="999" //state-level observations
ren cnty ssa

//merge to county FIPS identifiers
merge m:1 ssa using `ssa_cty', keepus(fips) keep(match master) nogen
drop if mi(fips)
ren fips cty
destring cty, replace

* Recode Counties
* Miami-Dade name/FIPS change, Broomfield split off from Boulder, Washabaugh Merged into Jackson, South Boston Merged into Halifax, Nansemond merged into Suffolk
recode cty (12086=12025) (8014 = 8013) (46131=46071) (51780=51083) (51695=51800)

* Collapse to County level
foreach cause in ami chf pn {
	bys cty: egen temp = wtmean(adjmortmeas_`cause'all30day), weight(ndmortmeas_`cause'all)
	drop adjmortmeas_`cause'all30day
	ren temp adjmortmeas_`cause'all30day
}
collapse (mean) adj* (rawsum) nd*, by(cty)


drop if cty>=57000  //Drop Territories
project, original("${cov_raw}/cty_covariates.dta") preserve
merge 1:1 cty using "${cov_raw}/cty_covariates.dta", keepus(cz cty_pop2000 cz_pop2000)
assert floor(cty/1000)==2 if _merge!=3 // unmatched counties are Alaskan
drop _merge
drop if cz==.

preserve

*** County level
keep adj* cty cty_pop2000

* Create index for acute care (standardize & combine measures)
foreach v of varlist adjmortmeas_amiall30day adjmortmeas_chfall30day adjmortmeas_pnall30day {
	qui sum `v' [w=cty_pop2000]
	gen `v'_std = (`v'- `r(mean)')/`r(sd)'
}
gen mort_30day_hosp_z = (adjmortmeas_amiall30day_std + adjmortmeas_chfall30day_std + adjmortmeas_pnall30day_std)/3

* Output cty dataset
save13 "${cov_clean}/cty_hospitalcompare_30day.dta", replace
project, creates("${cov_clean}/cty_hospitalcompare_30day.dta")


*** CZ level
restore

* Collapse mortality rates to CZ level
foreach cause in ami chf pn {
	bys cz: egen temp = wtmean(adjmortmeas_`cause'all30day), weight(ndmortmeas_`cause'all)
	drop adjmortmeas_`cause'all30day
	ren temp adjmortmeas_`cause'all30day
}
collapse (mean) adj* cz_pop2000, by(cz)

* Create index for acute care (standardize & combine measures)
foreach v of varlist adjmortmeas_amiall30day adjmortmeas_chfall30day adjmortmeas_pnall30day {
	qui sum `v' [w=cz_pop2000]
	gen `v'_std = (`v'- `r(mean)')/`r(sd)'
}
gen mort_30day_hosp_z = (adjmortmeas_amiall30day_std + adjmortmeas_chfall30day_std + adjmortmeas_pnall30day_std)/3
drop cz_pop2000

* Output cz dataset
save13 "${cov_clean}/cz_hospitalcompare_30day.dta", replace
project, creates("${cov_clean}/cz_hospitalcompare_30day.dta")
