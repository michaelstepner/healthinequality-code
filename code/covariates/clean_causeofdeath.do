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

/*** NCHS Cause of Death Data

External vs. medical mortality, 2004

***/

*******


*** Load underlying cause of death data
project, original("${cov_raw}/mort2004.dta")
use "${cov_raw}/mort2004.dta", clear

* Reformat ucod variable
gen ucod_cat = substr(ucod,1,3)
gen ucod_4th = substr(ucod,4,1)

* Generate college dummy
gen byte college=.
replace college=1 if inrange(educ,4,8)
replace college=0 if inrange(educ,1,3)
replace college=1 if inrange(educ89,13,17)
replace college=0 if inrange(educ89,0,12)
drop if mi(college) 

* Generate age in years
gen int yearsold=.
replace yearsold=age-1000 if inrange(age,1001,1998)
replace yearsold=0 if inrange(age,2001,6999)
assert age==9999 if mi(yearsold)

* Generate age groups (0-4,5-9,...,35-39,...)
gen agebin_mort = floor(yearsold/5)*5
keep if inrange(agebin_mort,40,60)

* Generate 5-digit FIPS county codes (by combining 2-digit FIPS state code with 3-digit county code)
gen state=staters
drop if inlist(state,"PR","VI","GU","ZZ") // drop residents of territories and foreign countries

project, original("${cov_raw}/state_database.dta") preserve
merge m:1 state using "${cov_raw}/state_database.dta", assert(match) nogen

replace countyrs=substr(countyrs,3,3) //county-code
drop if countyrs=="999" // drop counties not recorded bc pop. < 100,000 (27% obs, 103048)
egen countyfips = concat(statefips countyrs)
destring countyfips, replace
ren countyfips cty
ren sex GND_IND

* Collapse for number of external deaths
gen external_mort = (inlist(substr(ucod_cat,1,1),"V","W","X","Y"))
gen medical_mort = (external_mort==0)
collapse (sum) external_mort medical_mort, by(cty college GND_IND agebin_mort)
tempfile nchs_deaths
save `nchs_deaths'

*** Bring in county populations by age and gender
project, relies_on("$root/data/raw/Census 2000 SF1/DEC_00_SF1_PCT012.txt")
project, original("$root/data/raw/Census 2000 SF1/DEC_00_SF1_PCT012_with_ann.csv")
import delim using "$root/data/raw/Census 2000 SF1/DEC_00_SF1_PCT012_with_ann.csv", clear rowr(3) varn(1)
rename geoid2 cty

* Rename the population variables to descriptive names
forval a = 35/76 {  // works for ages 0 to 99. 100+ are binned in raw data
	local m "`: di %02.0f `a'+3'"  // the male pop vars are numbered age + 3
	local f "`: di %02.0f `a'+107'" // the female pop vars are numbered age + 107
	
	rename vd`m' pop_M_`a'
	rename vd`f' pop_F_`a'
}
keep cty pop_*

* Convert vars to numeric
destring *, replace
reshape long pop_M_ pop_F_ , i(cty) j(age)
rename (pop_M_ pop_F_) (popM popF)
reshape long pop , i(cty age) j(GND_IND) string
keep if inrange(age,40,64)
tempfile cty_pop_by_age
save `cty_pop_by_age'

* Bring in county populations by college, gender, and coarse age bins
project, relies_on("$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT025.txt")
project, original("$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT025_with_ann.csv")
import delim using "$root/data/raw/Census 2000 SF3/DEC_00_SF3_PCT025_with_ann.csv", clear rowr(3) varn(1)
rename geoid2 cty

destring *, replace
gen college_share_35_44M = (vd23+vd24+vd25+vd26)/vd19
gen college_share_45_64M = (vd31+vd32+vd33+vd34)/vd27
gen college_share_35_44F = (vd64+vd65+vd66+vd67)/vd60
gen college_share_45_64F = (vd72+vd73+vd74+vd75)/vd68
keep cty college_share*
reshape long college_share_35_44 college_share_45_64, i(cty) j(GND_IND) string

* Use college shares to impute college population by county
merge 1:m cty GND_IND using `cty_pop_by_age', assert(match) nogen
gen college_pop1 = pop*college_share_35_44 if inrange(age,35,44)
replace college_pop1 = pop*college_share_45_64 if inrange(age,45,64)
gen college_pop0 = pop - college_pop1
reshape long college_pop, i(cty GND_IND age) j(college)
drop pop
rename college_pop pop

* Generate age groups (0-4,5-9,...,35-39,...) and collapse
gen agebin_mort = floor(age/5)*5
collapse (sum) pop, by(cty college GND_IND agebin_mort)

* Collapse counts to CZ-college-agebin-gender level
merge 1:1 cty college GND_IND agebin_mort using `nchs_deaths', keep(match) nogen
recode cty (12086 = 12025)  // Recode Miami-Dade (Clifton Forge and Broomfield not in data, so no need to recode)

project, original("${cov_raw}/cty_covariates.dta") preserve
merge m:1 cty using "${cov_raw}/cty_covariates.dta", nogen keepus(cz) keep(match master) // 2,614 missing counties (bc pop too small)
collapse (sum) external_mort medical_mort pop, by(cz college GND_IND agebin_mort)

* Estimate mortality rates by CZ, age-gender adjusting using IRS 2000
project, original("${cov_raw}/IRS_age_gender_weights_2000.dta") preserve
merge m:1 GND_IND agebin_mort using "${cov_raw}/IRS_age_gender_weights_2000.dta", keep(master match) nogen
gen ext_mort = external_mort / pop
gen med_mort = medical_mort / pop
collapse (mean) ext_mort med_mort [w=weight], by(cz college)

replace ext_mort = 100000*ext_mort
replace med_mort = 100000*med_mort
gen total_mort = ext_mort+med_mort

reshape wide ext_mort med_mort total_mort, i(cz) j(college) 
rename *0 *_coll0
rename *1 *_coll1
keep cz ext* med* total_mort*

lab var ext_mort_coll0 "External Mortality - No College Ed."
lab var med_mort_coll0 "Medical Mortality - No College Ed."
lab var total_mort_coll0 "Total Mortality - No College Ed."
lab var ext_mort_coll1 "External Mortality - College Ed."
lab var total_mort_coll1 "Total Mortality - College Ed."

save13 "${cov_clean}/cz_NCHS_causeofdeath.dta", replace
project, creates("${cov_clean}/cz_NCHS_causeofdeath.dta")
