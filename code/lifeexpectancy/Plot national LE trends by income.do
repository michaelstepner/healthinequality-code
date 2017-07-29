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

* Create required folders
cap mkdir "${root}/scratch/National LE trends"
cap mkdir "${root}/scratch/National LE trends/data"

* Erase output numbers
cap erase "${root}/scratch/National LE trends/National LE trends results.csv"


/*** Plot national LE trends by household income quartile and ventile, and computes
	related statistics about national level trends in LE vs. income quantile.
***/


*********************************************
*** National LE trends by Income Quartile ***
*********************************************

* Save income means by quartile
project, uses("${root}/scratch/National income means by quantile/National income means by quartile.dta") preserve
use "${root}/scratch/National income means by quantile/National income means by quartile.dta", clear

* Generate income mean text for quartiles
isid gnd quartile
foreach g in "M" "F" {
	preserve
	keep if gnd=="`g'"
	sort quartile
	forval q = 1/4 {
		local inc_q`q'_`g' : di %2.0f hh_inc[`q']/1000
		local text_q`q'_`g' "$`inc_q`q'_`g''k"
		di "`text_q`q'_`g''"
	}
	restore
}

* Load data
project, original("$derived/le_estimates/national_leBY_year_gnd_hhincpctile.dta")
use "$derived/le_estimates/national_leBY_year_gnd_hhincpctile.dta", clear

* Collapse to quartiles
gen quartile=ceil(pctile/25)
isid gnd pctile year
collapse (mean) le_raceadj, by(gnd quartile year)

* Generate trend scatters
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	* Prepare trend coef/SE text labels
	local colors ///
		navy maroon forest_green dkorange teal cranberry lavender ///
		khaki sienna emidblue emerald brown erose gold bluishgray
		
	local trendlabels ""
	
	forvalues q = 1/4 {
		if "`g'"=="M" local tshift=0.7
		if "`g'"=="F" local tshift=0.22
		
		sum le_raceadj if year==2014 & gnd=="`g'" & quartile==`q', meanonly
		local lastyval=r(mean)
		
		reg le_raceadj year if gnd=="`g'" & quartile==`q'
		local ci_l = _b[year] - 1.96 * _se[year]
		local ci_h = _b[year] + 1.96 * _se[year]
		local trendlabels `trendlabels' text(`=max(`lastyval'+0.1,_b[_cons]+_b[year]*2014) + `tshift'' 2012.4 "Annual Change = `:di %04.2f _b[year]' (`:di %04.2f `ci_l'', `:di %04.2f `ci_h'')", color(`:word `q' of `colors'') size(*.9))
	}
	
	* Generate scatter
	binscatter le_raceadj year if gnd=="`g'", by(quartile) msymbol(circle triangle square diamond) discrete ///
		`trendlabels' ///
		xtitle("Year") ytitle("Expected Age at Death for 40 Year Olds in Years") title("") ///
		legend( ///
			ring(0) pos(10) c(1) order(4 3 2 1) bmargin(small) ///
			label(1 "1st Income Quartile: Mean `text_q1_`g''") ///
			label(2 "2nd Income Quartile: Mean `text_q2_`g''") ///
			label(3 "3rd Income Quartile: Mean `text_q3_`g''") ///
			label(4 "4th Income Quartile: Mean `text_q4_`g''") ///
			size(small) ///
		) 
		
	
	graph export "${root}/scratch/National LE trends/National LE trend by Quartile - `gender'.${img}", replace
	project, creates("${root}/scratch/National LE trends/National LE trend by Quartile - `gender'.${img}") preserve

	* Export data underlying scatter
	export delim if gnd=="`g'" ///
		using "${root}/scratch/National LE trends/data/National LE trend by Quartile - `gender'.csv", ///
		replace
	project, creates("${root}/scratch/National LE trends/data/National LE trend by Quartile - `gender'.csv") preserve
	
}

* Test that slope of Q4 is different from slope of Q1
reg le_raceadj io1.quartile##c.year if gnd == "F", robust
test 4.quartile#c.year
scalarout using "${root}/scratch/National LE trends/National LE trends results.csv", ///
	id("Equality Test for Quartiles 1 and 4 trends, Female: p = ") ///
	num(`=r(p)') fmt(%9.8f)

reg le_raceadj io1.quartile##c.year if gnd == "M", robust
test 4.quartile#c.year
scalarout using "${root}/scratch/National LE trends/National LE trends results.csv", ///
	id("Equality Test for Quartiles 1 and 4 trends, Male: p = ") ///
	num(`=r(p)') fmt(%9.8f)

********************************************
*** National LE trends by Income Ventile ***
********************************************

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

* Load data
project, original("$derived/le_estimates/national_leBY_year_gnd_hhincpctile.dta")
use "$derived/le_estimates/national_leBY_year_gnd_hhincpctile.dta", clear

* Collapse to ventiles
g ventile = ceil(pctile/5)
isid gnd pctile year
collapse (mean) le_raceadj, by(gnd ventile year)

* Estimate trends by Gender x Income Ventile
statsby _b _se, by(gnd ventile) clear : reg le_raceadj year

* Compute upper & lower 95% confidence interval
gen ci_h = _b_year + 1.96*_se_year
gen ci_l = _b_year - 1.96*_se_year

* Generate scatter of trend estimates
foreach gender in "Male" "Female" {
	
	local g=substr("`gender'",1,1)
	
	graph twoway (connect _b_year ventile) ///
				 (line ci_h ventile, lc(gs8) lp(-)) ///
				 (line ci_l ventile, lc(gs8) lp(-)) ///
				 if gnd=="`g'", ///
				 ytitle("Change per Year in Expected Age at Death in Years") ///
				 xtitle("Household Income Ventile") title("") ///
				 legend(off) graphregion(fcolor(white)) ///
				 yscale(range(-.1 .4)) ///
				 ylabel(-.1 "-0.1" 0 "0" .1 "0.1" .2 "0.2" .3 "0.3" .4 "0.4") ///
				 yline(0, lc(black)) ///
				 xlabel(0 "0" 5 `" "5" "`text_q5_`g''" "' ///
					10 `" "10" "`text_q10_`g''" "' ///
					15 `" "15" "`text_q15_`g''" "' ///
					20 `" "20" "`text_q20_`g''" "')
	graph export "${root}/scratch/National LE trends/National LE trend by Ventile - `gender'.${img}", replace
	project, creates("${root}/scratch/National LE trends/National LE trend by Ventile - `gender'.${img}") preserve

	* Export data underlying scatter
	export delim if gnd=="`g'" ///
		using "${root}/scratch/National LE trends/data/National LE trend by Ventile - `gender'.csv", ///
		replace
	project, creates("${root}/scratch/National LE trends/data/National LE trend by Ventile - `gender'.csv") preserve

}

* Numbers for paper
drop *cons
ren (_b_year _se_year ventile) (b se v)
keep b se v gnd
gen tot_change = b * (2014-2001)

sort gnd v
assert _N==40
assert gnd==cond(_n<=20,"F","M")

scalarout using "${root}/scratch/National LE trends/National LE trends results.csv", ///
	id("National Change 2001-2014: Women Bottom 5%") ///
	num(`=tot_change[1]') fmt(%9.2f)
scalarout using "${root}/scratch/National LE trends/National LE trends results.csv", ///
	id("National Change 2001-2014: Women Top 5%") ///
	num(`=tot_change[20]') fmt(%9.2f)

scalarout using "${root}/scratch/National LE trends/National LE trends results.csv", ///
	id("National Change 2001-2014: Men Bottom 5%") ///
	num(`=tot_change[21]') fmt(%9.2f)
scalarout using "${root}/scratch/National LE trends/National LE trends results.csv", ///
	id("National Change 2001-2014: Men Top 5%") ///
	num(`=tot_change[40]') fmt(%9.2f)
	
local p_f = normal((b[1]-b[20])/sqrt(se[1]^2+se[20]^2))
local p_m = normal((b[21]-b[40])/sqrt(se[21]^2+se[40]^2))
scalarout using "${root}/scratch/National LE trends/National LE trends results.csv", ///
	id("Equality Test for Ventiles 1 and 20 coefficients, Female: p = ") ///
	num(`p_f') fmt(%9.8f)
scalarout using "${root}/scratch/National LE trends/National LE trends results.csv", ///
	id("Equality Test for Ventiles 1 and 20 coefficients, Male: p = ") ///
	num(`p_m') fmt(%9.8f)

*****************************************
*** Project creates: reported numbers ***
*****************************************

project, creates("${root}/scratch/National LE trends/National LE trends results.csv")

