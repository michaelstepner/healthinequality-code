* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "$root/scratch/BRFSS maps"
cap mkdir "$root/scratch/BRFSS maps/data"


***********************************
*** CZ Maps of Health Behaviors ***
***********************************

* Load data
project, original("${root}/data/derived/final_covariates/cz_full_covariates.dta")
use "${root}/data/derived/final_covariates/cz_full_covariates.dta", clear

*** Create maps
foreach healthvar in "cur_smoke" "bmi_obese" "exercise_any" {

	if ("`healthvar'"=="exercise_any") local revcolor revcolor

	replace `healthvar'_q1 = 100 * `healthvar'_q1

	local title : var label `healthvar'_q1

	maptile `healthvar'_q1, geo(cz) `revcolor' nquantiles(10) legd(1) ///
		geofolder("$root/code/ado_maptile_geo") ///
		twopt( ///
			title("`title'") ///
			subtitle("by Commuting Zone") ///
			legend(size(*0.8)) ///
		) ///
		savegraph("$root/scratch/BRFSS maps/CZ map - `title'.png") replace
	project, creates("$root/scratch/BRFSS maps/CZ map - `title'.png") preserve
	
	export delim cz `healthvar'_q1 using "$root/scratch/BRFSS maps/data/CZ map - `title'.csv", ///
		replace  // output data for formatted map
	project, creates("$root/scratch/BRFSS maps/data/CZ map - `title'.csv") preserve
	
}

