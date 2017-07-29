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

if (c(os)=="Windows") global img wmf
else global img png

* Create required folders
cap mkdir "${root}/scratch/Deaths and population counts in IRS and other samples"
cap mkdir "${root}/scratch/Deaths and population counts in IRS and other samples/data"

* Erase output numbers
cap rm "${root}/scratch/Deaths and population counts in IRS and other samples/Correlation between NCHS and SSA deaths.csv"

/*** Compares general properties of the NCHS, SSA, and IRS/SSA with positive income samples
***/

*************

********************************************
*** Number of Deaths in NCHS vs SSA data ***
********************************************

* Prepare data
project, original("${derived}/Mortality Rates/NCHS-SSA-IRS Deaths and Populations/death_and_pop_counts_multisource.dta")
use "${derived}/Mortality Rates/NCHS-SSA-IRS Deaths and Populations/death_and_pop_counts_multisource.dta", clear
assert inrange(age, 40, 76)

replace dm1_dead = dm1_dead/1000
replace cdc_dead = cdc_dead/1000

tempfile NCHSvSSA
save `NCHSvSSA'

* Compare death counts by Gender x Age, pooling years
use `NCHSvSSA', clear
isid gnd year age
collapse (sum) cdc_dead dm1_dead, by(gnd age)

foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)
	
	* Plot fig
	twoway (connect dm1_dead age, m(circle) legend(label(1 SSA))) ///
		   (connect cdc_dead age, m(triangle) legend(label(2 NCHS))) ///
		   if gnd=="`g'", ///
		   ylab(0(100)425, gmin gmax) ///
		   legend(ring(0) pos(4) c(1) order(2 1) bmargin(medium)) ///
		   ytit("Deaths (in thousands)") ///
		   xtit("Age in Years") ti("", size(medsmall))	   
	graph export "${root}/scratch/Deaths and population counts in IRS and other samples/Death counts in NCHS and SSA by Gender x Age - `gender'.${img}", replace
	project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/Death counts in NCHS and SSA by Gender x Age - `gender'.${img}") preserve

	* Export data underlying fig
	export delim if gnd=="`g'" ///
		using "${root}/scratch/Deaths and population counts in IRS and other samples/data/Death counts in NCHS and SSA by Gender x Age - `gender'.csv", replace
	project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/data/Death counts in NCHS and SSA by Gender x Age - `gender'.csv") preserve	
		   
	* Output correlation between two series in fig
	corr dm1_dead cdc_dead if gnd=="`g'"
	scalarout using "${root}/scratch/Deaths and population counts in IRS and other samples/Correlation between NCHS and SSA deaths.csv", ///
		id("Correlation by Gender x Age pooling years: `gender'") ///
		num(`=r(rho)') fmt(%12.4f)

}

* Compare death counts by Gender x Year, pooling ages
use `NCHSvSSA', clear
isid gnd year age
collapse (sum) cdc_dead dm1_dead, by(gnd year)
recast float cdc_dead dm1_dead, force  // keeps output constant (even in last decimals) when code is rerun

foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)	
	
	* Plot fig
	twoway (connect dm1_dead year, m(circle) legend(label(1 SSA))) ///
		   (connect cdc_dead year, m(triangle) legend(label(2 NCHS))) ///
		   if gnd=="`g'", ///
		   ylab(0(100)700, gmin gmax) xlab(2000(5)2015) ///
		   legend(ring(0) pos(4) c(1) order(2 1) bmargin(medium)) ///
		   ytit("Deaths (in thousands)") ///
		   xtit("Year") ti("", size(medsmall))
	graph export "${root}/scratch/Deaths and population counts in IRS and other samples/Death counts in NCHS and SSA by Gender x Year - `gender'.${img}", replace
	project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/Death counts in NCHS and SSA by Gender x Year - `gender'.${img}") preserve
	
	* Export data underlying fig
	export delim if gnd=="`g'" ///
		using "${root}/scratch/Deaths and population counts in IRS and other samples/data/Death counts in NCHS and SSA by Gender x Year - `gender'.csv", replace
	project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/data/Death counts in NCHS and SSA by Gender x Year - `gender'.csv") preserve	
	
	* Output correlation between two series in fig
	corr dm1_dead cdc_dead if gnd=="`g'"
	scalarout using "${root}/scratch/Deaths and population counts in IRS and other samples/Correlation between NCHS and SSA deaths.csv", ///
		id("Correlation by Gender x Year pooling ages: `gender'") ///
		num(`=r(rho)') fmt(%12.4f)

}

project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/Correlation between NCHS and SSA deaths.csv")


*************************************************************
*** Death and Population Counts in NCHS, SSA and IRS data ***
*************************************************************

* Prepare data
project, original("${derived}/Mortality Rates/NCHS-SSA-IRS Deaths and Populations/death_and_pop_counts_multisource.dta")
use "${derived}/Mortality Rates/NCHS-SSA-IRS Deaths and Populations/death_and_pop_counts_multisource.dta", clear
keep if inrange(age, 40, 63)

foreach var of varlist _all {
	assert !mi(`var')
}

* Aggregate counts across ages, take average counts across years
isid gnd year age
collapse (sum) *_pop *_dead, by(gnd year)
collapse (mean) *_pop *_dead, by(gnd)

* Generate mortality rates per 100,000
foreach s in cdc dm1 irs irs_posinc irs_zeroinc {
	gen `s'_mortrate = `s'_dead / `s'_pop * 100000
}

* Generate percentages of pop, deaths, mortrate in DM-1/IRS vs NCHS CDC
foreach s in dm1 irs irs_posinc irs_zeroinc {
	gen `s'_pop_pct = `s'_pop / cdc_pop
	gen `s'_dead_pct = `s'_dead / cdc_dead
	gen `s'_mortrate_pct = `s'_mortrate / cdc_mortrate
}

gsort -gnd

* Output comparisons of Population Counts, Death Counts, Mortality Rates
export delim gnd cdc_pop* dm1_pop* irs_pop* irs_posinc_pop* irs_zeroinc_pop* ///
	using "${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Population Counts.csv", replace
project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Population Counts.csv") preserve

export delim gnd cdc_dead* dm1_dead* irs_dead* irs_posinc_dead* irs_zeroinc_dead* ///
	using "${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Death Counts.csv", replace
project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Death Counts.csv") preserve

export delim gnd cdc_mortrate* dm1_mortrate* irs_mortrate* irs_posinc_mortrate* irs_zeroinc_mortrate* ///
	using "${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Mortality Rates.csv", replace
project, creates("${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Mortality Rates.csv")

