* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global raw "${root}/data/raw"

* Create required folders
cap mkdir "${root}/data/derived/Mortality Rates"
cap mkdir "${root}/data/derived/Mortality Rates/NCHS-SSA-IRS Deaths and Populations"


/*** Load and combine counts of deaths and populations
	 by Gender x Age x Year from numerous sources:
		- CDC NCHS
		- SSA
		- IRS
		
	 Covering years 2001-2014 and ages 40-76 (when available from each source).
***/

*******
*** SSA DM1 count of deaths and population
*******

project, original("${raw}/Mortality Collapses/ssa_dm1_tab_mskd.dta")
use "${raw}/Mortality Collapses/ssa_dm1_tab_mskd.dta", clear

keep if gnd!="U"
assert inlist(gnd,"M","F")

reshape wide count, i(gnd year age) j(died)
ren (count0 count1) (dm1_pop dm1_dead) 
replace dm1_pop = dm1_pop + dm1_dead

keep if inrange(age,40,76) & year>=2001

tempfile ssa
save `ssa'

*******
*** IRS count of deaths and population (including zero incomes)
*******

project, original("${root}/code/ado/gen_mortrates2.ado")

project, original("${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta")
use "${raw}/Mortality Collapses/mort_ad_v6_nat_byageyr_new_mskd.dta", clear

* Clean up raw data
compress
drop if tax_yr<1999
assert inlist(gnd,"M","F")

assert pctile!=0
replace pctile=0 if pctile==-1  // in IRS collapse, zero incomes are coded as -1
replace pctile=-1 if pctile==.  // in IRS collapse, negative incomes are coded as .

ren deadby_* deadby_*_Mean
drop agebin_mort  // we already have exact age

* Calculate mortality rates
gen_mortrates2 gnd pctile, age(age) year(tax_yr) n(count)

* Partition into population and deaths by Positive and Zero earnings
rename age_at_d age
rename yod year
rename count irs_pop

gen irs_dead = chop(mortrate * irs_pop, 10e-6)

isid gnd age year pctile
replace pctile=1 if pctile>=1
label define poszeroneg 1 "posinc_" 0 "zeroinc_" -1 "neginc_"
label values pctile poszeroneg

collapse (sum) irs_pop irs_dead, by(gnd age year pctile)
compress

decode pctile, gen(pos_zero_neg)
drop pctile
reshape wide irs_@pop irs_@dead, i(gnd age year) j(pos_zero_neg) string

* Calculate total population and deaths
gen long irs_pop = irs_posinc_pop + irs_zeroinc_pop + irs_neginc_pop
gen long irs_dead = irs_posinc_dead + irs_zeroinc_dead + irs_neginc_dead
drop irs_neginc*

* Output
keep if inrange(age,40,76) & year>=2001
tempfile irs
save `irs'


*******
*** CDC NCHS count of deaths and population
*******

project, original("${raw}/CDC-Census Counts/Underlying Cause of Death, 1999-2014.txt")
import delimited "${raw}/CDC-Census Counts/Underlying Cause of Death, 1999-2014.txt", clear

drop if !mi(notes)
keep singleyearagescode gendercode deaths population year
ren (singleyearagescode gendercode deaths   population) ///
	(age                gnd        cdc_dead cdc_pop) 

destring age, replace force
keep if inrange(age,40,76) & year>=2001
destring cdc_pop, replace

tempfile cdc
save `cdc'

*******
*** Merge all death and population data together
*******

use `ssa', clear
merge 1:1 gnd age year using `irs', assert(1 3) nogen
merge 1:1 gnd age year using `cdc', assert(3) nogen

compress

save13 "${root}/data/derived/Mortality Rates/NCHS-SSA-IRS Deaths and Populations/death_and_pop_counts_multisource.dta", replace
project, creates("${root}/data/derived/Mortality Rates/NCHS-SSA-IRS Deaths and Populations/death_and_pop_counts_multisource.dta")
