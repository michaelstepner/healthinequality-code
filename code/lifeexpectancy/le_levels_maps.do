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
cap mkdir "$root/scratch/LE maps"
cap mkdir "$root/scratch/LE maps/data"

* Erase output numbers
cap erase "${root}/scratch/LE maps/Southern gap.csv"

/*** Generate maps of Life Expectancy levels
***/


**************************************
*** NCHS State Map of LE by Gender ***
**************************************

* Load data
project, original("$derived/le_estimates/NCHS state pooled income/st_NCHSleBY_gnd.dta")
use "$derived/le_estimates/NCHS state pooled income/st_NCHSleBY_gnd.dta", clear
rename st statefips

*** Create maps
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	maptile le_raceadj if gnd=="`g'", geo(state) geoid(statefips) revcolor nquantiles(10) ///
		geofolder("$root/code/ado_maptile_geo") ///
		twopt( ///
			title("Race-Adjusted Expected Age at Death for 40 Year Olds") ///
			subtitle("`gender's, by State, using NCHS mortality data") ///
			legend(size(*0.8)) ///
		) ///
		savegraph("$root/scratch/LE maps/STmap_NCHSleBY_gnd_`gender'.png") replace
	project, creates("$root/scratch/LE maps/STmap_NCHSleBY_gnd_`gender'.png") preserve
	
	export delim statefips le_raceadj using "$root/scratch/LE maps/data/STmap_NCHSleBY_gnd_`gender'.csv" if gnd=="`g'", ///
		replace  // output data for formatted map
	project, creates("$root/scratch/LE maps/data/STmap_NCHSleBY_gnd_`gender'.csv") preserve
}


*** Calculate difference between South region and other regions, by gender

* Merge on state populations
rename statefips st
merge m:1 st using "${derived}/final_covariates/st_pop.dta", assert(3) nogen

* Merge on census regions
rename st statefip
project, original("${root}/data/raw/Covariate Data/state_csreg_csdiv_2013.dta") preserve
merge m:1 statefip using "${root}/data/raw/Covariate Data/state_csreg_csdiv_2013.dta", ///
	assert(3) nogen

* Generate south dummy
gen south=(csregion==3)

* Output southern gap in LE
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	* Race-adjusted
	reg le_raceadj south [w=pop2000] if gnd=="`g'"
	
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE pooling Q1-Q4, NCHS data: coef") fmt(%9.2f) ///
		num(`=_b[south]') 
	
	test south=0
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE pooling Q1-Q4, NCHS data: pval") fmt(%9.3f) ///
		num(`=r(p)')
		
}

foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)
	
	* Race unadjusted
	reg le_agg south [w=pop2000] if gnd=="`g'"
	
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE pooling Q1-Q4, NCHS data race-UNADJUSTED: coef") fmt(%9.2f) ///
		num(`=_b[south]') 
	
	test south=0
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE pooling Q1-Q4, NCHS data race-UNADJUSTED: pval") fmt(%9.3f) ///
		num(`=r(p)')
	
}


***************************************************************
*** CZ Maps of LE by Gender, pooling income including zeros ***
***************************************************************

* Load data
project, original("$derived/le_estimates/With zero incomes/cz_leBY_gnd_With0Inc.dta")
use "$derived/le_estimates/With zero incomes/cz_leBY_gnd_With0Inc.dta", clear

*** Create maps
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	maptile le_raceadj if gnd=="`g'", geo(cz) revcolor nquantiles(10) ///
		geofolder("$root/code/ado_maptile_geo") ///
		twopt( ///
			title("Race-Adjusted Expected Age at Death for 40 Year Olds") ///
			subtitle("`gender's, by Commuting Zone, pooling incomes including $0") ///
			legend(size(*0.8)) ///
		) ///
		savegraph("$root/scratch/LE maps/CZmap_With0IncleBY_gnd_`gender'.png") replace
	
	export delim cz le_raceadj using "$root/scratch/LE maps/data/CZmap_With0IncleBY_gnd_`gender'.csv" if gnd=="`g'", ///
		replace  // output data for formatted map
		
	project, creates("$root/scratch/LE maps/CZmap_With0IncleBY_gnd_`gender'.png") preserve
	project, creates("$root/scratch/LE maps/data/CZmap_With0IncleBY_gnd_`gender'.csv") preserve
}


*** Calculate difference between South region and other regions, by gender

* Merge on population and census regions
project, original("${root}/data/derived/final_covariates/cz_full_covariates.dta") preserve
merge m:1 cz using "${root}/data/derived/final_covariates/cz_full_covariates.dta", ///
	assert(2 3) keep(3) nogen keepusing(fips pop2000)
rename fips statefip

project, original("${root}/data/raw/Covariate Data/state_csreg_csdiv_2013.dta") preserve
merge m:1 statefip using "${root}/data/raw/Covariate Data/state_csreg_csdiv_2013.dta", ///
	assert(3) nogen

* Generate south dummy
gen south=(csregion==3)

* Output southern gap in LE
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	reg le_raceadj south [w=pop2000] if gnd=="`g'", vce(cl statefip)
	
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE pooling $0 and Q1-Q4: coef") fmt(%9.2f) ///
		num(`=_b[south]') 
	
	test south=0
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE pooling $0 and Q1-Q4: pval") fmt(%9.3f) ///
		num(`=r(p)')
	
}

foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)
	
	* Race unadjusted
	reg le_agg south [w=pop2000] if gnd=="`g'", vce(cl statefip)
	
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE pooling pooling $0 and Q1-Q4 race-UNADJUSTED: coef") fmt(%9.2f) ///
		num(`=_b[south]') 
	
	test south=0
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE pooling $0 and Q1-Q4 race-UNADJUSTED: pval") fmt(%9.3f) ///
		num(`=r(p)')
	
}

***********************************************************
*** CZ Maps of LE by Income Quartile, Averaging Genders ***
***********************************************************

* Load data
project, original("$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta")
use cz gnd hh_inc_q le_raceadj using "$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta", clear

* Reshape wide on quartile and gender
rename le_raceadj le_raceadj_q
reshape wide le_raceadj_q, i(cz gnd) j(hh_inc_q)

rename le_raceadj_q* le_raceadj_q*_
reshape wide le_raceadj_q1_ le_raceadj_q2_ le_raceadj_q3_ le_raceadj_q4_, i(cz) j(gnd) string

* Plot LE Maps
foreach q in 1 {

	gen le_raceadj_q`q' = (le_raceadj_q`q'_M + le_raceadj_q`q'_F) / 2

	maptile le_raceadj_q`q', geo(cz) revcolor nquantiles(10) ///
		geofolder("$root/code/ado_maptile_geo") ///
		twopt( ///
			title("Race-Adjusted Expected Age at Death for 40 Year Olds") ///
			subtitle("Averaging of Men and Women, Q`q'") ///
			legend(size(*0.8)) ///
		) ///
		savegraph("$root/scratch/LE maps/CZmap_leBY_hhincquartile_Q`q'_pooledgender.png") replace
		
	export delim cz le_raceadj_q`q' ///
		using "$root/scratch/LE maps/data/CZmap_leBY_hhincquartile_Q`q'_pooledgender.csv", ///
		replace  // output data for formatted map
		
	project, creates("$root/scratch/LE maps/CZmap_leBY_hhincquartile_Q`q'_pooledgender.png") preserve
	project, creates("$root/scratch/LE maps/data/CZmap_leBY_hhincquartile_Q`q'_pooledgender.csv") preserve

}

*************************************************
*** CZ Maps of LE by Gender x Income Quartile ***
*************************************************

* Load data
project, original("$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta")
use cz gnd hh_inc_q le_raceadj using "$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta", clear

* Reshape wide on quartile
rename le_raceadj le_raceadj_q
reshape wide le_raceadj_q, i(cz gnd) j(hh_inc_q)

* Plot LE Maps
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)
	
	forvalues q=1/4 {

		* Plot map
		maptile le_raceadj_q`q' if gnd == "`g'", geo(cz) revcolor nquantiles(10) ///
			geofolder("$root/code/ado_maptile_geo") ///
			twopt( ///
				title("Race-Adjusted Expected Age at Death for 40 Year Olds") ///
				subtitle("`gender's, Q`q'") ///
				legend(size(*0.8)) ///
			) ///
			savegraph("$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q`q'_`gender'.png") replace
		project, creates("$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q`q'_`gender'.png") preserve

		* Output data underlying the map
		export delim cz le_raceadj_q`q' ///
			using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q`q'_`gender'.csv" ///
			if gnd == "`g'", replace
		project, creates("$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q`q'_`gender'.csv") preserve
		
		* Output decile data underlying the map, without LEs
		fastxtile le_raceadj_decile_q`q'_`g' = le_raceadj_q`q' if gnd=="`g'", nq(10)
		
		export delim cz le_raceadj_decile_q`q'_`g' ///
			using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q`q'_`gender' - decile data.csv" ///
			if gnd == "`g'", replace
		project, creates("$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q`q'_`gender' - decile data.csv") preserve

	}
	
}


*** Calculate difference between South region and other regions, by gender

* Merge on population and census regions
project, original("${root}/data/derived/final_covariates/cz_full_covariates.dta") preserve
merge m:1 cz using "${root}/data/derived/final_covariates/cz_full_covariates.dta", ///
	assert(2 3) keep(3) nogen keepusing(fips pop2000)
rename fips statefip

project, original("${root}/data/raw/Covariate Data/state_csreg_csdiv_2013.dta") preserve
merge m:1 statefip using "${root}/data/raw/Covariate Data/state_csreg_csdiv_2013.dta", ///
	assert(3) nogen

* Generate south dummy
gen south=(csregion==3)

* Output southern gap in LE
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	reg le_raceadj_q1 south [w=pop2000] if gnd=="`g'", vce(cl statefip)
	
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE Q1: coef") fmt(%9.2f) ///
		num(`=_b[south]') 
		
	test south
	scalarout using "${root}/scratch/LE maps/Southern gap.csv", ///
		id("Southern gap - `gender' LE Q1: pval") fmt(%9.2f) ///
		num(`=r(p)')
	
}
project, creates("${root}/scratch/LE maps/Southern gap.csv") preserve



*** Calculate average LE in top and bottom deciles

* Keep only required variables
isid cz gnd
keep cz gnd le_raceadj_q1

* Generate deciles of Q1 LE by gender
tempvar maledec
xtile `maledec' = le_raceadj_q1 if gnd=="M", nq(10)
xtile le_raceadj_q1_dec = le_raceadj_q1 if gnd=="F", nq(10)
replace le_raceadj_q1_dec = `maledec' if gnd=="M"
assert !mi(le_raceadj_q1_dec)

* Collapse to mean LE within decile
collapse (mean) le_raceadj_q1, by(gnd le_raceadj_q1_dec)

* Output mean LE in top and bottom deciles
assert _N==20
sort gnd le_raceadj_q1_dec
assert gnd==cond(_n<=10,"F","M")

scalarout using "${root}/scratch/LE maps/CZ LE levels - Q1 mean in top and bottom deciles of CZs.csv", ///
	replace ///
	id("Mean Q1 LE in bottom decile of CZs: men") ///
	num(`=le_raceadj_q1[11]') fmt(%9.1f)

scalarout using "${root}/scratch/LE maps/CZ LE levels - Q1 mean in top and bottom deciles of CZs.csv", ///
	id("Mean Q1 LE in top decile of CZs: men") ///
	num(`=le_raceadj_q1[20]') fmt(%9.1f)

scalarout using "${root}/scratch/LE maps/CZ LE levels - Q1 mean in top and bottom deciles of CZs.csv", ///
	id("Difference in Q1 LE in between top and bottom decile of CZs: men") ///
	num(`=le_raceadj_q1[20]-le_raceadj_q1[11]') fmt(%9.1f)

scalarout using "${root}/scratch/LE maps/CZ LE levels - Q1 mean in top and bottom deciles of CZs.csv", ///
	id("Mean Q1 LE in bottom decile of CZs: women") ///
	num(`=le_raceadj_q1[1]') fmt(%9.1f)

scalarout using "${root}/scratch/LE maps/CZ LE levels - Q1 mean in top and bottom deciles of CZs.csv", ///
	id("Mean Q1 LE in top decile of CZs: women") ///
	num(`=le_raceadj_q1[10]') fmt(%9.1f)

scalarout using "${root}/scratch/LE maps/CZ LE levels - Q1 mean in top and bottom deciles of CZs.csv", ///
	id("Difference in Q1 LE in between top and bottom decile of CZs: women") ///
	num(`=le_raceadj_q1[10]-le_raceadj_q1[1]') fmt(%9.1f)

project, creates("${root}/scratch/LE maps/CZ LE levels - Q1 mean in top and bottom deciles of CZs.csv")


*** Test there is a difference in LEs across CZs

project, original("$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile.dta")
use "$derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile.dta", clear

keep if hh_inc_q==1
rename le_raceadj le_raceadj_q1
isid cz gnd sample_num
keep cz gnd sample_num le_raceadj_q1

project, original("${root}/data/derived/final_covariates/cz_pop.dta") preserve
merge m:1 cz using "${root}/data/derived/final_covariates/cz_pop.dta", ///
	assert(2 3) keep(3) nogen

set matsize 800

reg le_raceadj_q1 i.cz if gnd=="M" [w=pop2000], robust
scalarout using "${root}/scratch/LE maps/CZ LE levels - Test of equality in Q1 LE across CZs.csv", ///
	replace ///
	id("Test that Q1 LE is the same in all CZs: men, p=") fmt(%9.4f) ///
	num(`=Ftail(e(df_m),e(df_r),e(F))')
	
reg le_raceadj_q1 i.cz if gnd=="F" [w=pop2000], robust
scalarout using "${root}/scratch/LE maps/CZ LE levels - Test of equality in Q1 LE across CZs.csv", ///
	id("Test that Q1 LE is the same in all CZs: women, p=") fmt(%9.4f) ///
	num(`=Ftail(e(df_m),e(df_r),e(F))')
	
project, creates("${root}/scratch/LE maps/CZ LE levels - Test of equality in Q1 LE across CZs.csv")


************************************************************************
*** County Maps of LE by Gender x Income Quartile, for specific CSAs ***
************************************************************************

* Load data
project, original("$derived/le_estimates/cty_leBY_gnd_hhincquartile.dta")
use cty gnd hh_inc_q le_raceadj using "$derived/le_estimates/cty_leBY_gnd_hhincquartile.dta", clear
rename le_raceadj le_raceadj_q
reshape wide le_raceadj_q, i(cty gnd) j(hh_inc_q)

* Merge in county characteristics
project, original("$derived/final_covariates/cty_full_covariates.dta") preserve
merge m:1 cty using "$derived/final_covariates/cty_full_covariates.dta", ///
	assert(2 3) keep(3) nogen ///
	keepusing(county_name cty_pop2000 csa csa_name stateabbrv)

* Rename CSAs to simpler names
replace csa_name = "New York" if csa_name == "New York-Newark, NY-NJ-CT-PA"
replace csa_name = "Detroit" if csa_name == "Detroit-Warren-Ann Arbor, MI"
replace csa_name = "Washington DC" if csa_name == "Washington-Baltimore-Arlington, DC-MD-VA-WV-PA"
replace csa_name = "Chicago" if csa_name == "Chicago-Naperville, IL-IN-WI"
replace csa_name = "Boston" if csa_name == "Boston-Worcester-Providence, MA-RI-NH-CT"
replace csa_name = "San Francisco" if csa_name == "San Jose-San Francisco-Oakland, CA"
replace csa_name = "Philadelphia" if csa_name == "Philadelphia-Reading-Camden, PA-NJ-DE-MD"

* Generate county maps for New York and Detroit
foreach csa in "New York" "Detroit" /*"Washington DC" "Chicago" "Boston" "San Francisco" "Philadelphia"*/ {

	foreach gender in "Male" "Female" {
	
		local g=substr("`gender'",1,1)

		rename cty county
		maptile le_raceadj_q1 if gnd=="`g'" & csa_name=="`csa'", geo(county1990) ///
			geofolder("$root/code/ado_maptile_geo") ///
			n(10) revcolor ///
			mapif(csa_name=="`csa'") ///
			twopt( ///
				title("Race-Adjusted Expected Age at Death", size(medium)) ///
				subtitle("`gender's in Bottom Quartile, by County in `csa'") ///
				legend(size(*0.8)) ///
			) ///
			savegraph("$root/scratch/LE maps/CSAmap_leBY_gnd_hhincquartile_`csa'_Q1_`gender'.png") replace
		rename county cty
		
		export delim cty le_raceadj_q1 ///
			using "$root/scratch/LE maps/data/CSAmap_leBY_gnd_hhincquartile_`csa'_Q1_`gender'.csv" ///
			if gnd=="`g'" & csa_name=="`csa'", replace  // output data for formatted map
			
		project, creates("$root/scratch/LE maps/CSAmap_leBY_gnd_hhincquartile_`csa'_Q1_`gender'.png") preserve
		project, creates("$root/scratch/LE maps/data/CSAmap_leBY_gnd_hhincquartile_`csa'_Q1_`gender'.csv") preserve
	}
	
}

* Reported numbers: highest and lowest LE counties for men in New York
isid cty gnd
keep if csa_name=="New York" & gnd=="M"

sort le_raceadj_q1

scalarout using "${root}/scratch/LE maps/County LE levels - top and bottom counties for New York men.csv", ///
	replace ///
	id("LE in bottom county for New York Q1 men: `=county_name[1]' County `=stateabbrv[1]'") ///
	num(`=le_raceadj_q1[1]') fmt(%9.1f)

scalarout using "${root}/scratch/LE maps/County LE levels - top and bottom counties for New York men.csv", ///
	id("LE in top county for New York Q1 men: `=county_name[_N]' County `=stateabbrv[_N]'") ///
	num(`=le_raceadj_q1[_N]') fmt(%9.1f)
 
project, creates("${root}/scratch/LE maps/County LE levels - top and bottom counties for New York men.csv")
