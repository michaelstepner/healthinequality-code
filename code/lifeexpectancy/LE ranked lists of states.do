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
cap mkdir "$root/scratch/State LE ranked lists by income quartile"


/*** Create ranked lists of State LE levels and State LE trends,
	 by income quartile.
***/

**************
*** Levels ***
**************

* Load state LE levels data
project, original("$derived/le_estimates/st_leBY_gnd_hhincquartile.dta")
use st gnd hh_inc_q le_raceadj using "$derived/le_estimates/st_leBY_gnd_hhincquartile.dta", clear

* Take unweighted average of men and women
isid st gnd hh_inc_q
collapse (mean) le_raceadj, by(st hh_inc_q)

* Merge on state names
rename st statefips
project, original("${root}/data/raw/Covariate Data/state_database.dta") preserve
merge m:1 statefips using "${root}/data/raw/Covariate Data/state_database.dta", ///
	keepusing(state*) ///
	assert(3) nogen

* Reshape wide on income quartile
rename le_raceadj le_raceadj_q
reshape wide le_raceadj_q, i(statefips) j(hh_inc_q)
order state*

* Ranked lists
foreach q in 1 4 {
	sort le_raceadj_q`q'
	export delim state* le_raceadj_q`q' ///
		using "$root/scratch/State LE ranked lists by income quartile/State ranked LE levels Q`q'.csv", ///
		replace
	project, creates("$root/scratch/State LE ranked lists by income quartile/State ranked LE levels Q`q'.csv") preserve
}

sort le_raceadj_q1
maptile le_raceadj_q1, geo(state) geoid(statefips) cutv(`=le_raceadj_q1[10]+epsfloat()') rev ///
	geofolder("$root/code/ado_maptile_geo") ///
	savegraph("$root/scratch/State LE ranked lists by income quartile/State ranked LE levels Q`q' - geographic belt among 10 lowest states.png") replace
project, creates("$root/scratch/State LE ranked lists by income quartile/State ranked LE levels Q`q' - geographic belt among 10 lowest states.png") preserve

**************
*** Trends ***
**************

* Load state LE trends data
project, original("$derived/le_trends/st_letrendsBY_gnd_hhincquartile.dta")
use st gnd hh_inc_q le_raceadj_b_year using "$derived/le_trends/st_letrendsBY_gnd_hhincquartile.dta", clear
rename le_raceadj_b_year le_raceadj_tr

* Take unweighted average of men and women
isid st gnd hh_inc_q
collapse (mean) le_raceadj_tr, by(st hh_inc_q)

* Merge on state names
rename st statefips
project, original("${root}/data/raw/Covariate Data/state_database.dta") preserve
merge m:1 statefips using "${root}/data/raw/Covariate Data/state_database.dta", ///
	keepusing(statename) ///
	assert(3) nogen
	
* Reshape wide on income quartile
rename le_raceadj_tr le_raceadj_tr_q
reshape wide le_raceadj_tr_q, i(statefips) j(hh_inc_q)
order state*

* Ranked lists
sort le_raceadj_tr_q1
export delim state* le_raceadj_tr_q1 ///
	using "$root/scratch/State LE ranked lists by income quartile/State ranked LE trends Q1.csv", ///
	replace
project, creates("$root/scratch/State LE ranked lists by income quartile/State ranked LE trends Q1.csv") preserve
