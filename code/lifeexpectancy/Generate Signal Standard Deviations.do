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
cap mkdir "${root}/scratch/Signal to Noise"

* Erase output numbers
cap erase "${root}/scratch/Signal to Noise/Signal SD tests of equality.csv"


****************
*** Programs ***
****************

cap program drop signal_sd_table
program define signal_sd_table

	syntax varname, fmt(string) saving(string) [saveintermediate(string)]
	local var `varlist'

	* Compute noise variance and total variance
	gen varnoise_`var' = sdnoise_`var'^2
	collapse (mean) varnoise_`var' (sd) sdtotal_`var' = `var' (count) N = varnoise_`var' [aw=pop2000], by(gnd hh_inc_q)
	gen vartotal_`var' = sdtotal_`var'^2
	
	* Compute signal SD
	gen sdsignal_`var' = sqrt(vartotal_`var' - varnoise_`var')
	format sdsignal_`var' `fmt'
	
	if (`"`saveintermediate'"'!="") {
		if !regexm(`"`: subinstr local saveintermediate "\" "/", all'"',`"^`=subinstr(c(tmpdir),"\","/",.)'"') {
			di as error "saveintermediate() must be a tempfile"
			exit 198
		}
		save `saveintermediate'
	}
	
	preserve
	
	* Reshape wide on quartile
	keep hh_inc_q gnd sdsignal_`var' N
	rename sdsignal_`var' sdsignal_`var'_q
	reshape wide sdsignal_`var'_q, i(gnd) j(hh_inc_q)
	
	* Output
	gsort -gnd
	export delim using `"`saving'"', replace
	project, creates(`"`saving'"')

end


***************************************************************
*** Signal SD: County LE levels by Gender x Income Quartile ***
***************************************************************

*** Table of signal SDs

* Load point estimates and bootstrap SDs
project, original("$derived/le_estimates_stderr/cty_SEleBY_gnd_hhincquartile.dta")
use "$derived/le_estimates_stderr/cty_SEleBY_gnd_hhincquartile.dta", clear
isid cty gnd hh_inc_q
keep cty gnd hh_inc_q le_raceadj sd_le_raceadj
rename sd* sdnoise*

* Merge in population counts
project, original("${root}/data/derived/final_covariates/cty_full_covariates.dta") preserve
merge m:1 cty using "${root}/data/derived/final_covariates/cty_full_covariates.dta", ///
	assert(2 3) keep(3) nogen keepusing(cty_pop2000)
rename cty_pop2000 pop2000

* Output signal SD table
signal_sd_table le_raceadj, fmt(%9.2f) ///
	saving("${root}/scratch/Signal to Noise/County LE Levels - Signal SD.csv")

*** Signal share of variance
gen signalshare_le_raceadj = (vartotal_le_raceadj - varnoise_le_raceadj) / vartotal_le_raceadj
export delim gnd hh_inc_q signalshare_le_raceadj ///
	using "${root}/scratch/Signal to Noise/County LE Levels - Signal share of variance.csv", ///
	replace
project, creates("${root}/scratch/Signal to Noise/County LE Levels - Signal share of variance.csv")


***********************************************************
*** Signal SD: CZ LE levels by Gender x Income Quartile ***
***********************************************************

*** Table of signal SDs

* Load point estimates and bootstrap SDs
project, original("$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile.dta")
use "$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile.dta", clear
isid cz gnd hh_inc_q
keep cz gnd hh_inc_q le_raceadj sd_le_raceadj
rename sd* sdnoise*

* Merge in population counts
merge m:1 cz using "${derived}/final_covariates/cz_pop.dta", assert(2 3) keep(3) nogen

* Output signal SD table
tempfile cz_gnd_quartile_variances
signal_sd_table le_raceadj, fmt(%9.2f) ///
	saving("${root}/scratch/Signal to Noise/CZ Signal SD of LE Levels - by Gender x Quartile.csv") ///
	saveintermediate(`cz_gnd_quartile_variances')

*** Signal share of variance
gen signalshare_le_raceadj = (vartotal_le_raceadj - varnoise_le_raceadj) / vartotal_le_raceadj
export delim gnd hh_inc_q signalshare_le_raceadj ///
	using "${root}/scratch/Signal to Noise/CZ LE Levels - Signal share of variance.csv", ///
	replace
project, creates("${root}/scratch/Signal to Noise/CZ LE Levels - Signal share of variance.csv")
	
	
*** Tests of equality of signal SDs

* Load bootstrapped CZ x Gender x Income Quartile life expectancies
project, original("${root}/data/derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile.dta")
use "${root}/data/derived/le_estimates/bootstrap/bootstrap_cz_leBY_gnd_hhincquartile.dta", clear

* Merge in CZ populations
merge m:1 cz using "${derived}/final_covariates/cz_pop.dta", assert(2 3) keep(3) nogen

* Calculate total variance *in each bootstrap sample*
isid cz gnd hh_inc_q sample_num
collapse (sd) sdtotal_le_raceadj = le_raceadj [aw=pop2000], by(gnd hh_inc_q sample_num)
gen vartotal_le_raceadj = sdtotal_le_raceadj^2

* Merge in noise variances
merge m:1 gnd hh_inc_q using `cz_gnd_quartile_variances', assert(3) nogen ///
	keepusing(varnoise_le_raceadj)

* Compute signal SD
gen sdsignal_le_raceadj = sqrt(vartotal_le_raceadj - varnoise_le_raceadj)
format sdsignal_le_raceadj %9.2f

* Reshape wide on gender and quartile
keep gnd hh_inc_q sample_num sdsignal_le_raceadj

rename sdsignal_le_raceadj sdsignal_le_raceadj_
reshape wide sdsignal_le_raceadj_, i(hh_inc_q sample_num) j(gnd) string

rename sdsignal_le_raceadj_* sdsignal_le_raceadj_*_q
reshape wide sdsignal_le_raceadj_M_q sdsignal_le_raceadj_F_q, i(sample_num) j(hh_inc_q)

* Output p-values for tests of equality

count if sdsignal_le_raceadj_M_q4 > sdsignal_le_raceadj_M_q1
scalarout using "${root}/scratch/Signal to Noise/Signal SD tests of equality.csv", ///
	id("CZ Signal SD of LE levels - probability Male Q4 SD > Male Q1 SD") ///
	num(`=r(N)/_N') fmt(%9.3f)

count if sdsignal_le_raceadj_F_q1 > sdsignal_le_raceadj_M_q1
scalarout using "${root}/scratch/Signal to Noise/Signal SD tests of equality.csv", ///
	id("CZ Signal SD of LE levels - probability Female Q1 SD > Male Q1 SD") ///
	num(`=r(N)/_N') fmt(%9.3f)

count if sdsignal_le_raceadj_F_q4 > sdsignal_le_raceadj_F_q1
scalarout using "${root}/scratch/Signal to Noise/Signal SD tests of equality.csv", ///
	id("CZ Signal SD of LE levels - probability Female Q4 SD > Female Q1 SD") ///
	num(`=r(N)/_N') fmt(%9.3f)
	
	
*************************************************************************************
*** Signal SD: County LE levels *variation within CZ* by Gender x Income Quartile ***
*************************************************************************************

cap program drop cty_withincz_resid
program define cty_withincz_resid
	
	* Compute variation in LE within CZs
	foreach g in "M" "F" {
		forvalues q=1/4 {
			areg le_raceadj if gnd=="`g'" & hh_inc_q==`q' [aw=cty_pop2000], absorb(cz)
			predict le_raceadj_czresid`g'`q', residuals
		}
	}
	
	gen le_raceadj_czresid = .
	foreach g in "M" "F" {
		forvalues q=1/4 {
			replace le_raceadj_czresid = le_raceadj_czresid`g'`q' if mi(le_raceadj_czresid)
		}
	}
	assert !mi(le_raceadj_czresid)

end

*** Table of signal SDs

** Point estimates of within-CZ variation in county LE 

* Load county LE point estimates and merge CZ ids
project, original("$derived/le_estimates/cty_leBY_gnd_hhincquartile.dta")
project, original("${root}/data/derived/final_covariates/cty_full_covariates.dta")

use cty gnd hh_inc_q le_raceadj using ///
	"$derived/le_estimates/cty_leBY_gnd_hhincquartile.dta", clear
isid cty gnd hh_inc_q

merge m:1 cty using "${root}/data/derived/final_covariates/cty_full_covariates.dta", ///
	assert(2 3) keep(3) nogen keepusing(cz cty_pop2000)

* Compute variation in LE within CZs
cty_withincz_resid

* Output
keep cty gnd hh_inc_q cty_pop2000 le_raceadj_czresid
tempfile pointest
save `pointest'
	
** Bootstrap draws of within-CZ variation in county LE

* Load bootstrapped county LEs and merge CZ ids
project, original("$derived/le_estimates/bootstrap/bootstrap_cty_leBY_gnd_hhincquartile.dta")
project, original("${root}/data/derived/final_covariates/cty_full_covariates.dta")

use cty gnd hh_inc_q sample_num le_raceadj using ///
	"$derived/le_estimates/bootstrap/bootstrap_cty_leBY_gnd_hhincquartile.dta", clear
isid cty gnd hh_inc_q sample_num 

merge m:1 cty using "${root}/data/derived/final_covariates/cty_full_covariates.dta", ///
	assert(2 3) keep(3) nogen keepusing(cz cty_pop2000)

* Compute variation in LE within CZs
cty_withincz_resid

* Collapse over bootstrap draws to mean and SD of within-CZ LE variation
collapse (mean) mean_le_raceadj_czresid=le_raceadj_czresid ///
		 (sd) sdnoise_le_raceadj_czresid=le_raceadj_czresid, by(cty gnd hh_inc_q)

** Combine point estimates and bootstrap draws
		 
* Merge in point estimates
merge 1:1 cty gnd hh_inc_q using `pointest', assert(3) nogen
		 
* Compute noise variance and total variance
gen varnoise = sdnoise_le_raceadj_czresid^2
collapse (mean) varnoise (sd) sdtotal = le_raceadj_czresid (count) N = varnoise [aw=cty_pop2000], by(gnd hh_inc_q)
gen vartotal = sdtotal^2

* Compute signal SD
gen sdsignal = sqrt(vartotal - varnoise)
format sdsignal %9.2f

* Reshape wide on quartile
keep hh_inc_q gnd sdsignal N
rename sdsignal sdsignal_q
reshape wide sdsignal_q, i(gnd) j(hh_inc_q)

* Output
gsort -gnd
export delim using "${root}/scratch/Signal to Noise/Signal SD of Variation in County LE Levels within CZ - by Gender x Quartile.csv", replace
project, creates("${root}/scratch/Signal to Noise/Signal SD of Variation in County LE Levels within CZ - by Gender x Quartile.csv")


***********************************************************
*** Signal SD: CZ LE trends by Gender x Income Quartile ***
***********************************************************

*** Table of signal SDs

* Load point estimates and bootstrap SDs
project, original("$derived/le_trends_stderr/cz_SEletrendsBY_gnd_hhincquartile.dta")
use "$derived/le_trends_stderr/cz_SEletrendsBY_gnd_hhincquartile.dta", clear
isid cz gnd hh_inc_q
keep cz gnd hh_inc_q le_raceadj_b_year sd_le_raceadj_b_year
rename *_b_year *_tr
rename sd* sdnoise*

* Merge in population counts
merge m:1 cz using "${derived}/final_covariates/cz_pop.dta", assert(2 3) keep(3) nogen

* Output signal SD table
signal_sd_table le_raceadj_tr, fmt(%9.3f) ///
	saving("${root}/scratch/Signal to Noise/CZ LE Trends - Signal SD.csv")

*** Signal share of variance
gen signalshare_le_raceadj_tr = (vartotal_le_raceadj_tr - varnoise_le_raceadj_tr) / vartotal_le_raceadj_tr
export delim gnd hh_inc_q signalshare_le_raceadj_tr ///
	using "${root}/scratch/Signal to Noise/CZ LE Trends - Signal share of variance.csv", ///
	replace
project, creates("${root}/scratch/Signal to Noise/CZ LE Trends - Signal share of variance.csv")


**************************************************************
*** Signal SD: State LE trends by Gender x Income Quartile ***
**************************************************************

*** Table of signal SDs

* Load point estimates and bootstrap SDs
project, original("$derived/le_trends_stderr/st_SEletrendsBY_gnd_hhincquartile.dta")
use "$derived/le_trends_stderr/st_SEletrendsBY_gnd_hhincquartile.dta", clear
isid st gnd hh_inc_q
keep st gnd hh_inc_q le_raceadj_b_year sd_le_raceadj_b_year
rename *_b_year *_tr
rename sd* sdnoise*

* Merge in population counts
merge m:1 st using "${derived}/final_covariates/st_pop.dta", assert(3) nogen

* Output signal SD table
signal_sd_table le_raceadj_tr, fmt(%9.3f) ///
	saving("${root}/scratch/Signal to Noise/State Signal SD of LE Trends - by Gender x Quartile.csv")

*** Signal share of variance
gen signalshare_le_raceadj_tr = (vartotal_le_raceadj_tr - varnoise_le_raceadj_tr) / vartotal_le_raceadj_tr
export delim gnd hh_inc_q signalshare_le_raceadj_tr ///
	using "${root}/scratch/Signal to Noise/State LE Trends - Signal share of variance.csv", ///
	replace
project, creates("${root}/scratch/Signal to Noise/State LE Trends - Signal share of variance.csv")
	

*****************************************
*** Project creates: reported numbers ***
*****************************************

project, creates("${root}/scratch/Signal to Noise/Signal SD tests of equality.csv")
