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

* Erase output numbers
cap erase "${root}/scratch/Major city LE profiles by ventile/Bottom Ventile LE - Rich vs Poor Cities.csv"

* Create required folders
cap mkdir "${root}/scratch/Major city LE profiles by ventile"
cap mkdir "${root}/scratch/Major city LE profiles by ventile/data"

/*** Plot mortality profiles in individual CZs by Income Ventile (and Gender)
***/

* Save income means by ventile
project, uses("${root}/scratch/National income means by quantile/National income means by ventile.dta") preserve
use "${root}/scratch/National income means by quantile/National income means by ventile.dta", clear

* Generate income mean text for ventile
foreach g in "M" "F" {
	preserve
	keep if gnd=="`g'"
	sort ventile
	forval q = 5(5)20 {
		local inc_q`q'_`g' : di %2.0f hh_inc[`q']/1000
		local text_q`q'_`g' "$`inc_q`q'_`g''k"
		di "`text_q`q'_`g''"
	}
	restore
}

collapse (mean) hh_inc [w=count], by(gnd ventile)
sort ventile
forval q = 5(5)20 {
	local inc_q`q' : di %2.0f hh_inc[`q']/1000
	local text_q`q' "$`inc_q`q''k"
	di "`text_q`q''"
}

* Load ventile life expectancies and CZ names
project, original("$derived/le_estimates/Largest CZs by ventile/cz_leBY_gnd_hhincventile.dta")
project, original("${derived}/final_covariates/cz_full_covariates.dta")

use "$derived/le_estimates/Largest CZs by ventile/cz_leBY_gnd_hhincventile.dta", clear
merge m:1 cz using "${derived}/final_covariates/cz_full_covariates.dta", ///
	nogen assert(2 3) keep(3) ///
	keepusing(czname)


* Plot LE profiles for 4 major cities by Income Ventile, separately for each gender
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)
	
	local loclabels ""
	if ("`gender'"=="Male") {
		local loclabels text(80.7 2 "New York City", color(navy) size(*0.77) placement(e)) ///
						text(78.53 2 "San Francisco", color(maroon) size(*0.77) placement(e)) ///
						text(76.8 2.02 "Dallas", color(forest_green) size(*0.77) placement(e)) ///
						text(74.1 2 "Detroit", color(dkorange) size(*0.77) placement(e))
	}
	else {
		local loclabels text(85.1 -0.3 "New York City", color(navy) size(*0.77) placement(e)) ///
						text(82.42 -0.36 "San Francisco", color(maroon) size(*0.77) placement(e)) ///
						text(80.52 -0.28 "Dallas", color(forest_green) size(*0.77) placement(e)) ///
						text(77.8 -0.3 "Detroit", color(dkorange) size(*0.77) placement(e))
	}

	* Generate figure
	twoway	(line le_raceadj hh_inc_v if czname=="New York City") ///
			(line le_raceadj hh_inc_v if czname=="San Francisco") ///
			(line le_raceadj hh_inc_v if czname=="Dallas") ///
			(line le_raceadj hh_inc_v if czname=="Detroit") ///
			if gnd == "`g'", ///
			`loclabels' ///
			graphregion(fcolor(white)) ylabel(70(5)90) ///
			title("") xtitle("Household Income Ventile") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
			legend(off) ///
			xlabel(0 "0" 5 `" "5" "`text_q5_`g''" "' ///
					10 `" "10" "`text_q10_`g''" "' ///
					15 `" "15" "`text_q15_`g''" "' ///
					20 `" "20" "`text_q20_`g''" "')
	graph export "${root}/scratch/Major city LE profiles by ventile/Major cities LE profile by Income Ventile - `gender'.${img}", replace
	project, creates("${root}/scratch/Major city LE profiles by ventile/Major cities LE profile by Income Ventile - `gender'.${img}") preserve
	
	* Export data underlying figure
	export delim cz gnd hh_inc_v le_raceadj czname if gnd=="`g'" & inlist(czname,"New York City","San Francisco","Dallas","Detroit") ///
		using "${root}/scratch/Major city LE profiles by ventile/data/Major cities LE profile by Income Ventile - `gender'.csv", ///
		replace
	project, creates("${root}/scratch/Major city LE profiles by ventile/data/Major cities LE profile by Income Ventile - `gender'.csv") preserve

}


sum le_raceadj if hh_inc_v == 1 & czname == "San Francisco"
	scalarout using "${root}/scratch/Major city LE profiles by ventile/Bottom Ventile LE - Rich vs Poor Cities.csv", ///
		id("San Francisco, California v1 LE") fmt(%9.2f) ///
		num(`=r(mean)')
sum le_raceadj if hh_inc_v == 1 & czname == "New York City"
	scalarout using "${root}/scratch/Major city LE profiles by ventile/Bottom Ventile LE - Rich vs Poor Cities.csv", ///
		id("New York City v1 LE") fmt(%9.2f) ///
		num(`=r(mean)')
sum le_raceadj if hh_inc_v == 1 & czname == "Gary"
	scalarout using "${root}/scratch/Major city LE profiles by ventile/Bottom Ventile LE - Rich vs Poor Cities.csv", ///
		id("Gary, Indiana v1 LE") fmt(%9.2f) ///
		num(`=r(mean)')
sum le_raceadj if hh_inc_v == 1 & czname == "Detroit"
	scalarout using "${root}/scratch/Major city LE profiles by ventile/Bottom Ventile LE - Rich vs Poor Cities.csv", ///
		id("Detroit, Michigan v1 LE") fmt(%9.2f) ///
		num(`=r(mean)')
project, creates("${root}/scratch/Major city LE profiles by ventile/Bottom Ventile LE - Rich vs Poor Cities.csv") preserve



** Plot LE profiles, averaging genders

collapse (mean) le_raceadj, by(hh_inc_v czname cz)

twoway	(line le_raceadj hh_inc_v if czname=="New York City") ///
		(line le_raceadj hh_inc_v if czname=="San Francisco") ///
		(line le_raceadj hh_inc_v if czname=="Dallas") ///
		(line le_raceadj hh_inc_v if czname=="Detroit"), ///
		graphregion(fcolor(white)) ylabel(70(5)90) ///
		title("") xtitle("Household Income Ventile") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
		legend(off) ///
		xlabel(0 "0" 5 `" "5" "`text_q5'" "' ///
				10 `" "10" "`text_q10'" "' ///
				15 `" "15" "`text_q15'" "' ///
				20 `" "20" "`text_q20'" "') ///
		text(83 1.7 "New York City", color(navy) size(*0.77) placement(e)) ///
		text(80.55 1.7 "San Francisco", color(maroon) size(*0.77) placement(e)) ///
		text(78.9 1.74 "Dallas", color(forest_green) size(*0.77) placement(e)) ///
		text(76.5 1.74 "Detroit", color(dkorange) size(*0.77) placement(e))

graph export "${root}/scratch/Major city LE profiles by ventile/Major cities LE profile by Income Ventile - avg.${img}", replace
project, creates("${root}/scratch/Major city LE profiles by ventile/Major cities LE profile by Income Ventile - avg.${img}") preserve

* Export data underlying figure
export delim cz hh_inc_v le_raceadj czname if inlist(czname,"New York City","San Francisco","Dallas","Detroit") ///
	using "${root}/scratch/Major city LE profiles by ventile/data/Major cities LE profile by Income Ventile - avg.csv", ///
	replace
project, creates("${root}/scratch/Major city LE profiles by ventile/data/Major cities LE profile by Income Ventile - avg.csv") preserve


