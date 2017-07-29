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

/*** Test runtime of different methods for estimating Gompertz race shifters,
	 which is especially relevant for bootstrap runtimes.
***/

********


*** Load data
timer clear

project, original("nlms_v5_s11_sampleA.dta")
use "nlms_v5_s11_sampleA.dta", clear


*** Method 1: Loop and store estimates
timer on 1
foreach g in "M" "F" {
	streg i.csdiv i.incq i.racegrp if gnd=="`g'", dist(gompertz) nohr ancillary(i.csdiv i.incq i.racegrp)
	estimates store est`g'
}
timer off 1


*** Method 2: statsby, saving

* Specify parameters to save
local save_est ///
diff_gomp_int_black = _b[_t:2.racegrp] ///
diff_gomp_int_hisp = _b[_t:3.racegrp] ///
diff_gomp_int_asian = _b[_t:4.racegrp] ///
diff_gomp_slope_black = _b[gamma:2.racegrp] ///
diff_gomp_slope_hisp = _b[gamma:3.racegrp] ///
diff_gomp_slope_asian = _b[gamma:4.racegrp]

* Run regression
timer on 2

tempfile save_bysex
statsby `save_est', saving(`save_bysex', `replace') ///
	by(gnd): streg i.csdiv i.incq i.racegrp, dist(gompertz) nohr ancillary(i.csdiv i.incq i.racegrp)

timer off 2


*** Method 3: statsby, clear
timer on 3

statsby `save_est', clear ///
	by(gnd): streg i.csdiv i.incq i.racegrp, dist(gompertz) nohr ancillary(i.csdiv i.incq i.racegrp)

timer off 3

		
*** Display times
timer list
