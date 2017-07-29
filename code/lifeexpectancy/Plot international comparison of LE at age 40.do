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
cap mkdir "${root}/scratch/International comparison of LE at 40"
cap mkdir "${root}/scratch/International comparison of LE at 40/data"


****************

* Load World Health Organization data on LE at 40
project, original("${root}/data/raw/WHO/International_LEat40_in2013.dta")
use "${root}/data/raw/WHO/International_LEat40_in2013.dta", clear

* Append our national LE estimates by Gender x Income Percentile, for select percentiles
project, original("$derived/le_estimates/national_leBY_gnd_hhincpctile.dta") preserve
append using "$derived/le_estimates/national_leBY_gnd_hhincpctile.dta", ///
	keep(le_raceadj gnd pctile) gen(_append)
keep if _append==0 | inlist(pctile,1,25,50,100)
replace country = "United States - P" + string(pctile) if _append==1
drop _append

* Manually select specific countries to highlight
gen byte highlight=0
replace highlight=1 if gnd=="M" & (inlist(country,"Lesotho","Zambia","Sudan","India","Pakistan") | inlist(country,"Iraq","Libya","China","San Marino","United Kingdom","Canada"))
replace highlight=1 if gnd=="F" & (inlist(country,"Sierra Leone","Zambia","Sudan","India","Pakistan") | inlist(country,"Iraq","Libya","China","United Kingdom","Canada","Japan"))
replace highlight=. if !mi(pctile)

* Generate ranks by gender, where rank==1 means lowest LE
bys gnd (le_raceadj): gen le_raceadj_rank = _n
order gnd country pctile highlight le_raceadj le_raceadj_rank


* Plot bar graphs of LE at age 40

foreach gender in "Men" "Women" {

	local g=cond("`gender'"=="Men","M","F")

	* Generate figure
	twoway	(spike le_raceadj le_raceadj_rank if highlight==0, hor lc(gs10)) ///
			(spike le_raceadj le_raceadj_rank if highlight==1, hor lc(navy)) ///
			(spike le_raceadj le_raceadj_rank if !mi(pctile), hor lc(maroon)) ///
			(scatter le_raceadj_rank le_raceadj if highlight==1, m(none) mlabel(country) mlabc(black)) ///
			(scatter le_raceadj_rank le_raceadj if !mi(pctile), m(none) mlabel(country) mlabc(maroon)) ///	
			if gnd=="`g'", ///
			graphregion(fcolor(white)) legend(off) ///
			ytitle("") ylab(none) ///
			ysize(7) xsize(8.25) fxsize(66.667) /// Create a canvas that is height 7 x width 5.5, without cutting off labels
			xtitle("Expected Age at Death for 40 Year Old `gender'") xlabel(60(5)90) ///
			title("") 
	graph export "${root}/scratch/International comparison of LE at 40/International comparison of LE at 40 - `gender'.${img}", replace
	project, creates("${root}/scratch/International comparison of LE at 40/International comparison of LE at 40 - `gender'.${img}") preserve
	
	* Export data underlying figure
	export delim if gnd=="`g'" ///
		using "${root}/scratch/International comparison of LE at 40/data/International comparison of LE at 40 - `gender'.csv", ///
		replace
	project, creates("${root}/scratch/International comparison of LE at 40/data/International comparison of LE at 40 - `gender'.csv") preserve
	
}
