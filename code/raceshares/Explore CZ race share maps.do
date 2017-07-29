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
global img png

* Create necessary folders
cap mkdir "${root}/scratch/Race share maps"

/*** Plot CZ maps of race shares, by:
		1. Sex
		2. Sex x Income Quartile
***/

project, original("$root/code/ado/compute_raceshares.ado")

********************************
*** WITHOUT income quartiles ***
********************************

* Load data
project, original("$derived/raceshares/cz_racesharesBY_agebin_gnd.dta")
use "$derived/raceshares/cz_racesharesBY_agebin_gnd.dta", clear

* Aggregate to CZ-level, and compute raceshares
collapse (sum) pop_*, by(cz)
compute_raceshares, by(cz)

* Convert race shares to percentages
foreach var of varlist raceshare_* {
	replace `var'=`var'*100
}

* Maps
foreach r in "asian" "black" "hispanic" {
	maptile raceshare_`r', geo(cz) legd(1) cutv(5(5)40) ///
		geofolder("$root/code/ado_maptile_geo") ///
		twopt(title("Race Shares, all Q, `r' %") subtitle("last bin is >=40%")) ///
		savegraph("${root}/scratch/Race share maps/raceshares_ALLQ_`r'.${img}") replace
	project, creates("${root}/scratch/Race share maps/raceshares_ALLQ_`r'.${img}") preserve
}
maptile raceshare_other, geo(cz) legd(1) cutv(60(5)95) ///
	geofolder("$root/code/ado_maptile_geo") ///
	twopt(title("Race Shares, all Q, white %") subtitle("first bin is <=60%")) ///
	savegraph("${root}/scratch/Race share maps/raceshares_ALLQ_white.${img}") replace
project, creates("${root}/scratch/Race share maps/raceshares_ALLQ_white.${img}") preserve

*****************************
*** WITH income quartiles ***
*****************************

* Load data
project, original("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta")
use "$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta", clear

* Aggregate to CZ x Income Quartile level, and compute raceshares
collapse (sum) pop_*, by(cz hh_inc_q)
compute_raceshares, by(cz hh_inc_q)

* Convert race shares to percentages
foreach var of varlist raceshare_* {
	replace `var'=`var'*100
}

* Maps
foreach q in 1 4 {
	foreach r in "asian" "black" "hispanic" {
		maptile raceshare_`r' if hh_inc_q==`q', geo(cz) legd(1) cutv(5(5)40) ///
			geofolder("$root/code/ado_maptile_geo") ///
			twopt(title("Race Shares, Q`q', `r' %") subtitle("last bin is >=40%")) ///
			savegraph("${root}/scratch/Race share maps/raceshares_Q`q'_`r'.${img}") replace
		project, creates("${root}/scratch/Race share maps/raceshares_Q`q'_`r'.${img}") preserve
	}
	maptile raceshare_other if hh_inc_q==`q', geo(cz) legd(1) cutv(60(5)95) ///
		geofolder("$root/code/ado_maptile_geo") ///
		twopt(title("Race Shares, Q`q', white %") subtitle("first bin is <=60%")) ///
		savegraph("${root}/scratch/Race share maps/raceshares_Q`q'_white.${img}") replace
	project, creates("${root}/scratch/Race share maps/raceshares_Q`q'_white.${img}") preserve
}
