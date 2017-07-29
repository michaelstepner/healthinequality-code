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

/*** Generate maps of Life Expectancy trends:

	- by State x Income Quartile
***/


********************
*** State Trends ***
********************

* Load data
project, original("${root}/data/derived/le_trends/st_letrendsBY_gnd_hhincquartile.dta")
use "${root}/data/derived/le_trends/st_letrendsBY_gnd_hhincquartile.dta", clear
rename st statefips

* Map Q1
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	maptile le_raceadj_b_year if gnd=="`g'" & hh_inc_q==1, geo(state) geoid(statefips) rev nq(10) ///
		geofolder("$root/code/ado_maptile_geo") ///
		twopt( ///
			title("Annual Changes in Race-Adjusted Expected Age at Death") ///
			subtitle("`gender's, Bottom Quartile") ///
			legend(size(*0.8)) ///
		) ///
		savegraph("$root/scratch/LE maps/STmap_leTrendsBY_gnd_hhincquartile_Q1_`gender'.png") replace
		
	export delim statefips le_raceadj_b_year ///
		using "$root/scratch/LE maps/data/STmap_leTrendsBY_gnd_hhincquartile_Q1_`gender'.csv" ///
		if gnd == "`g'" & hh_inc_q==1, replace
		
	project, creates("$root/scratch/LE maps/STmap_leTrendsBY_gnd_hhincquartile_Q1_`gender'.png") preserve
	project, creates("$root/scratch/LE maps/data/STmap_leTrendsBY_gnd_hhincquartile_Q1_`gender'.csv") preserve
	
}


* Calculate Q4-Q1 difference in trends
isid statefips gnd hh_inc_q
keep statefips gnd hh_inc_q le_raceadj_b_year
rename le_raceadj_b_year le_raceadj_b_year_q
reshape wide le_raceadj_b_year_q, i(statefips gnd) j(hh_inc_q)
gen le_raceadj_b_year_diffq4q1 = le_raceadj_b_year_q4 - le_raceadj_b_year_q1

* Map Q4-Q1 difference
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	maptile le_raceadj_b_year_diffq4q1 if gnd=="`g'", geo(state) geoid(statefips) nq(10) ///
		geofolder("$root/code/ado_maptile_geo") ///
		twopt( ///
			title("Annual Changes in Race-Adjusted Expected Age at Death") ///
			subtitle("`gender's, Difference Between Top and Bottom Quartiles") ///
			legend(size(*0.8)) ///
		) ///
		savegraph("$root/scratch/LE maps/STmap_leTrendsBY_gnd_hhincquartile_Q4-Q1diff_`gender'.png") replace
		
	export delim statefips le_raceadj_b_year_diffq4q1 ///
		using "$root/scratch/LE maps/data/STmap_leTrendsBY_gnd_hhincquartile_Q4-Q1diff_`gender'.csv" ///
		if gnd == "`g'", replace
		
	project, creates("$root/scratch/LE maps/STmap_leTrendsBY_gnd_hhincquartile_Q4-Q1diff_`gender'.png") preserve
	project, creates("$root/scratch/LE maps/data/STmap_leTrendsBY_gnd_hhincquartile_Q4-Q1diff_`gender'.csv") preserve
	
}
	
