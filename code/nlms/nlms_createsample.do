* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set working directory
cd "${root}/data/derived/NLMS"

/*** Take raw NLMS dataset and perform sample selection and manipulations to
	 prepare it for subsequent analysis.
***/

******

cap program drop nlms_createsample
program define nlms_createsample

	/*** Load raw NLMS data (already in Stata format) and:
	
		 1. Perform sample selection
		 2. Add vars necessary for analysis
			- Race groups (with or without asian group)
			- Income quartiles
				+ note: this process uses a random number generator to break
						bins into equal-sized quartiles. so seed must be set
						before running this program	to get deterministic output.
			- Census division and region
		 3. stset for survival analysis
		 
	***/

	syntax using/, saving(string) [ withasian ]
	
	************************
	*** Sample Selection ***
	************************
	
	* Load NLMS dataset
	project, uses(`"`using'"')
	use `"`using'"', clear
	
	* Count follow-up period in years (followed until death or end of 11 year sample)
	gen followyears = follow/365.25
	
	* Keep relevant sample
	drop if mi(wt) | wt==0  // not sure why NLMS gives missing or 0 weights
	keep if hisp!=. & race!=.  // non-missing race & ethnicity
	drop if adjinc==.  // non-missing income measure
	drop if followyears < 1  // survive at least one full year after income is measured
	/* Note: "2 year income lag" means death is measured in second year after measuring income.
			 For example, someone whose income is measured in Tax Year 1999 will be excluded if
			 they die anytime during the year 2000, but counted as a death if they die anytime
			 during the year 2001. So there is a one-year period after we measure their income
			 (on Dec 31 1999) that they are required to survive in order to be included in our
			 sample.
	*/
	tab age
	keep if inrange(age,38,61)  // income measured during working years
	
	* note: ~60% of sample is under 38 and ~15% is over 61. So we lose ~75% of sample to age restriction.
	* (see -tab age- before sample selection)
	
	*************************************************
	*** Generate race groups and income quartiles ***
	*************************************************
	
	* Assign race groups
	gen byte racegrp = 1  // Other
	label define racegrp 1 "Other aka White" 2 "Black non-Hispanic" 3 "Hispanic" 4 "Asian non-Hispanic"
	label values racegrp racegrp
	replace racegrp = 2 if (race==2)  // Black
	if ("`withasian'"=="withasian") replace racegrp = 4 if (race==4) // Asian
	replace racegrp = 3 if (hisp==1 | hisp==2)  // Hispanic
	tab racegrp
	
	* Generate income quartiles by sex and age
	qui gen byte incq=.
	label var incq "Income Quartile"
	
	gen adjinc_tiebroken=adjinc+runiform()  // randomly break ties within an income bin so each quartile has 25% of people
	
	forvalues a=38/61 {
		di "Computing income quartiles for age `a'..."
		fastxtile incq_1 = adjinc_tiebroken if sex==1 & age==`a' [pw=wt], nquantile(4)
		fastxtile incq_2 = adjinc_tiebroken if sex==2 & age==`a' [pw=wt], nquantile(4)
		
		qui replace incq = incq_1 if !mi(incq_1)
		qui replace incq = incq_2 if !mi(incq_2)
		drop incq_1 incq_2
	}
	assert !mi(incq)
	
	drop adjinc_tiebroken
	
	
	*******************************
	*** Adjust set of variables ***
	*******************************
	
	* Keep variables of interest
	keep record wt age sex inddea followyears incq adjinc statefips racegrp
	
	* Merge on census region & census division
	rename statefips statefip
	project, original("${root}/data/raw/Covariate Data/state_csreg_csdiv_2013.dta") preserve
	merge m:1 statefip using "${root}/data/raw/Covariate Data/state_csreg_csdiv_2013.dta", ///
		assert(3) nogen
	rename statefip statefips
	
	* Create gnd var
	assert inlist(sex,1,2)
	qui gen gnd = "M" if sex==1
	qui replace gnd = "F" if sex==2
	drop sex
	order record gnd
	
	
	*********************************
	*** Prepare survival analysis ***
	*********************************
	
	* Mean n year old is actually n+0.5 years old
	replace age=age+0.5
	
	* Generate start and end age for risk of death
	gen startage=age+1  // start measuring deaths one year after measuring income
	gen endage=age+followyears  // age of death or end of 11-year follow period
	
	* Set survival-time data
	stset endage [pw=wt], failure(inddea==1) origin(time 40) enter(time startage)
	
	* Output
	sort record
	save13 `"`saving'"', replace
	project, creates(`"`saving'"')
	
end


*************************************
*** Prepare NLMS analysis samples ***
*************************************

set seed 704350339

nlms_createsample using "nlms_v5_s11_raw.dta", ///
	saving("nlms_v5_s11_sampleA.dta") ///
	withasian
