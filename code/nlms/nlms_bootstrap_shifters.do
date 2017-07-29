* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set working directory
cd "$root/data/derived/NLMS"

* Create necessary folders
cap mkdir "$root/data/derived/NLMS/bootstrap"
cap mkdir "$root/data/derived/NLMS/bootstrap_percentiles"

* Import bootstrap config
project, original("$root/code/set_bootstrap.do")
include "$root/code/set_bootstrap.do"

/*** 1. Estimate the differences in Gompertz intercept and slope by race,
		relative to the non-Black non-Hispanic group. (Separately by sex.)
	 
		Use bootstrap sampling on original NLMS sample, weighting draws
		by population weights.
		
	 2. Take NLMS bootstrapped Gompertz race shifters,
		compute and store 2.5th and 97.5th percentiles
		of bootstrap distribution for use in confidence
		intervals.
***/


*****************************************
*** Define bootstrapping loop program ***
*****************************************

program define sim_raceshifters_BYsex
	/*** Runs the Gompertz race shifter estimation bootstrap, for the shifters
		 estimated separately by Sex.
	
		 Appends the resulting estimates together
		 with the iteration number indicated in
		 the variable sample_num.
	***/

	syntax using/, reps(integer) ///
		save_bysex(string) replace
	
	local cmd nlms_bootstrap_raceshifters using "`using'",
	
	* Display command and progress bar
	di ""
	di as text `"{tab}command:  `cmd'"'
	di ""
	_dots 0, title(Simulations) reps(`reps') `nodots'
	
	* Perform simulations
	forvalues i=1/`reps' {
		_dots `i' 0
		
		tempfile result`i'
		qui `cmd' save_bysex(`result`i'')
	}
	
	* Append results together
	di ""
	clear
	gen int sample_num=.
	forvalues i=1/`reps' {
		append using `result`i''
		qui replace sample_num=`i' if mi(sample_num)
	}
	
	* Output
	label data "NOTE: Gompertz intercepts in this data correspond to intercepts at age 40."
	save13 `save_bysex', `replace'
	
end

project, relies_on(${root}/code/ado/wsample.ado)

program define nlms_bootstrap_raceshifters
	/*** Given an NLMS panel, generate a bootstrap sample and
		 estimate the Gompertz parameters for each race
		 while controlling for Income Quartile and Census Divsion.
		 
		 Return the race shifters, which are the differences in Gompertz
		 parameters relative to the non-Black non-Hispanic group.
		 
		 Estimates shifters separately by Sex.
		 
	***/
		
	syntax using/, save_bysex(string)

	*****************
	*** Load data ***
	*****************
	
	* Load NLMS sample
	use `"`using'"', clear
	
	* If bootstrapping: assign the number of draws for each observation,
	* using weights to determine probability of draw	
	wsample num_draws, wt(wt)
	keep if num_draws>0  // for speed, drop unnecessary obs
	
	streset [fw=num_draws], noshow
	drop wt startage endage inddea  // for speed, drop unnecessary vars
	
	******************************
	*** Estimate race shifters ***
	******************************

	* Run regressions by Sex
	tempname raceshifters
	streg i.csdiv i.incq i.racegrp if gnd=="F", dist(gompertz) nohr ancillary(i.csdiv i.incq i.racegrp)
	matrix `raceshifters' = (_b[_t:2.racegrp], _b[_t:3.racegrp], _b[_t:4.racegrp], _b[gamma:2.racegrp], _b[gamma:3.racegrp], _b[gamma:4.racegrp])
	streg i.csdiv i.incq i.racegrp if gnd=="M", dist(gompertz) nohr ancillary(i.csdiv i.incq i.racegrp)
	matrix `raceshifters' = `raceshifters' \ (_b[_t:2.racegrp], _b[_t:3.racegrp], _b[_t:4.racegrp], _b[gamma:2.racegrp], _b[gamma:3.racegrp], _b[gamma:4.racegrp])
	
	* Store estimates in dataset
	matrix colnames `raceshifters' = diff_gomp_int_black diff_gomp_int_hisp diff_gomp_int_asian diff_gomp_slope_black diff_gomp_slope_hisp diff_gomp_slope_asian
	clear
	svmat `raceshifters', names(col)
	gen gnd=cond(_n==1,"F","M")
	
	* Output
	save13 `save_bysex', replace
	
end


****************************************
*** Bootstrap Gompertz race shifters ***
****************************************

*** Minimize file size
project, uses("nlms_v5_s11_sampleA.dta")
use "nlms_v5_s11_sampleA.dta", clear

keep record wt gnd incq csdiv racegrp _* startage endage inddea // only necessary vars

compress
tempfile bootstrap_sample
save `bootstrap_sample'


*** Perform bootstrap
set seed 207335925

sim_raceshifters_BYsex using `bootstrap_sample', reps(${reps}) ///
	save_bysex("bootstrap/bootstrap_raceshifters_BYsex.dta") replace
	
project, creates("bootstrap/bootstrap_raceshifters_BYsex.dta")

********************************************************
*** Compute percentiles of bootstrapped distribution ***
********************************************************

* Load bootstrapped estimates
project, uses("bootstrap/bootstrap_raceshifters_BYsex.dta")
use "bootstrap/bootstrap_raceshifters_BYsex.dta", clear

* Build matrix of 2.5th and 97.5th percentiles
foreach var of varlist diff_gomp_* {
	tempfile `var'pctiles

	statsby `var'25=r(r1) `var'975=r(r2), saving(``var'pctiles') ///
		by(gnd): _pctile `var', percentiles(2.5 97.5)
}

* Combine datasets of percentile values
ds diff_gomp_*
local shiftervars=r(varlist)

clear
qui use gnd using ``:word 1 of `shiftervars''pctiles'
foreach var of local shiftervars {
	qui merge 1:1 gnd using ``var'pctiles', assert(3) nogen
}

* Reshape percentile long
reshape long `shiftervars', i(gnd) j(pctile)
replace pctile=pctile/10

* Output
label data "NOTE: Gompertz intercepts in this data correspond to intercepts at age 40."
save13 "bootstrap_percentiles/bootstrap_raceshifters_percentiles_BYsex.dta", replace
project, creates("bootstrap_percentiles/bootstrap_raceshifters_percentiles_BYsex.dta")
