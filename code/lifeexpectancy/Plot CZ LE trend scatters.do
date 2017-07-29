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
cap mkdir "${root}/scratch/CZ trend scatters"
cap mkdir "${root}/scratch/CZ trend scatters/data"


/*** Plot the trends in life expectancy in selected CZs.
***/


*******************************
*** Load data on LE by year ***
*******************************

* Get list of Top 10/Bottom 10 CZs

project, uses("${root}/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 cz - Q1 LE trends.csv") preserve
import delim using "${root}/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 cz - Q1 LE trends.csv", clear
rename (le_raceadj_tr_q1_m_s le_raceadj_tr_q1_f_s) (le_raceadj_tr_q1_M_s le_raceadj_tr_q1_F_s)

* Fetch LE levels by year for T10/B10 in trends
assert _N==20
project, original("$derived/le_estimates/cz_leBY_year_gnd_hhincquartile.dta") preserve
merge 1:m cz using "$derived/le_estimates/cz_leBY_year_gnd_hhincquartile.dta", ///
	assert(2 3) keep(3) nogen


************************
*** Generate figures ***
************************

*** Plot LE trend for Birmingham, Cincinnati, Knoxville and Tampa

* Generate plot
twoway	(scatter le_raceadj year if gnd=="M", ms(o)) ///
		(scatter le_raceadj year if gnd=="F", ms(t)) ///
		(lfit le_raceadj year if gnd=="M", lc(navy) text(71.1 1999.5 "Annual Change =", color(navy) place(east))) ///
		(lfit le_raceadj year if gnd=="F", lc(maroon) text(88 1999.5 "Annual Change =", color(maroon) place(east))) ///
		if hh_inc_q==1 & inlist(loc_name,"Birmingham, AL","Cincinnati, OH","Knoxville, TN","Tampa, FL"), ///
		by(loc_name, rows(1) legend(off) note("")) ///
		graphregion(fcolor(white)) legend(off) ///
		xsize(9.5) ///
		ylab(70(5)90) yscale(range(73 90)) ///
		xlab(2001 2014) xscale(range(2000 2015)) ///
		xtitle("Year") ytitle("Expected Age at Death in Years") ///
		title("")

* Add trend coefs & CIs
local byplotcounter=0
foreach city in "Birmingham, AL" "Cincinnati, OH" "Knoxville, TN" "Tampa, FL" {

	local ++byplotcounter

	foreach g in "M" "F" {
	
		local color=cond("`g'"=="M","navy","maroon")
		local textboxid=cond("`g'"=="M",1,2)

		qui levelsof le_raceadj_tr_q1_`g'_s if gnd=="`g'" & hh_inc_q==1 & loc_name=="`city'", local(texttrend) clean
		
		gr_edit .plotregion1.plotregion1[`byplotcounter'].textbox`textboxid'.text = {}
		gr_edit .plotregion1.plotregion1[`byplotcounter'].textbox`textboxid'.text.Arrpush Annual Change = `texttrend'

	}
}

* Add "Men/Women" legend
gr_edit .plotregion1.plotregion1[4].AddTextBox added_text editor 84.20748502118725 2014.24
gr_edit .plotregion1.plotregion1[4].added_text_new = 1
gr_edit .plotregion1.plotregion1[4].added_text_rec = 1
gr_edit .plotregion1.plotregion1[4].added_text[1].style.editstyle  angle(default) size(medium) color(maroon) horizontal(left) vertical(middle) margin(zero) linegap(zero) drawbox(no) boxmargin(zero) fillcolor(bluishgray) linestyle( width(thin) color(black) pattern(solid)) box_alignment(west) editcopy
gr_edit .plotregion1.plotregion1[4].added_text[1].text = {}
gr_edit .plotregion1.plotregion1[4].added_text[1].text.Arrpush Women

gr_edit .plotregion1.plotregion1[4].AddTextBox added_text editor 76 2014.24
gr_edit .plotregion1.plotregion1[4].added_text_new = 2
gr_edit .plotregion1.plotregion1[4].added_text_rec = 2
gr_edit .plotregion1.plotregion1[4].added_text[2].style.editstyle  angle(default) size(medium) color(navy) horizontal(left) vertical(middle) margin(zero) linegap(zero) drawbox(no) boxmargin(zero) fillcolor(bluishgray) linestyle( width(thin) color(black) pattern(solid)) box_alignment(west) editcopy
gr_edit .plotregion1.plotregion1[4].added_text[2].text = {}
gr_edit .plotregion1.plotregion1[4].added_text[2].text.Arrpush Men

* Remove blue background, set heading background to light blue-gray
gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
gr_edit .plotregion1.subtitle[1].style.editstyle fillcolor(ltbluishgray) editcopy
gr_edit .plotregion1.subtitle[1].style.editstyle linestyle(color(ltbluishgray)) editcopy

* Output figure
graph export "${root}/scratch/CZ trend scatters/LE trends in selected cities.${img}", replace
project, creates("${root}/scratch/CZ trend scatters/LE trends in selected cities.${img}") preserve

* Export data underlying fig
export delim cz loc_name gnd hh_inc_q year le_raceadj ///
	if hh_inc_q==1 & inlist(loc_name,"Birmingham, AL","Cincinnati, OH","Knoxville, TN","Tampa, FL") ///
	using "${root}/scratch/CZ trend scatters/data/LE trends in selected cities.csv", replace
project, creates("${root}/scratch/CZ trend scatters/data/LE trends in selected cities.csv") preserve

*** Plot LE trend for Birmingham, Cincinnati, Knoxville and Tampa in separate figs

* Generate plot
foreach city in "Birmingham, AL" "Cincinnati, OH" "Knoxville, TN" "Tampa, FL" {

	foreach g in "M" "F" {
		local textboxid=cond("`g'"=="M",1,2)

		qui levelsof le_raceadj_tr_q1_`g'_s if gnd=="`g'" & hh_inc_q==1 & loc_name=="`city'", local(texttrend) clean
		local trend`g' `texttrend'
	}

	twoway	(scatter le_raceadj year if gnd=="M", ms(o)) ///
			(scatter le_raceadj year if gnd=="F", ms(t)) ///
			(lfit le_raceadj year if gnd=="M", lc(navy) text(71.1 2000.5 "Annual Change = `trendM'", color(navy) place(east))) ///
			(lfit le_raceadj year if gnd=="F", lc(maroon) text(87.5 2000.5 "Annual Change = `trendF'", color(maroon) place(east))) ///
			if hh_inc_q==1 & inlist(loc_name,"`city'"), ///
			legend(off) ///
			graphregion(fcolor(white)) legend(off) ///
			ylab(70(5)85) yscale(range(73 88)) ///
			xlab(2001 2014) xscale(range(2000 2015)) ///
			xtitle("Year") ytitle("Race-Adjusted Life Expectancy") ///
			title("`city'", color(black) size(medlarge))
	graph export "${root}/scratch/CZ trend scatters/LE trend scatter in Q1 - `city'.${img}", replace
	project, creates("${root}/scratch/CZ trend scatters/LE trend scatter in Q1 - `city'.${img}") preserve
	
}


*** Plot LE trend for 2 CZs: Birmingham and Tampa 

* Generate plot
twoway	(scatter le_raceadj year if gnd=="M", ms(o)) ///
		(scatter le_raceadj year if gnd=="F", ms(o)) ///
		(lfit le_raceadj year if gnd=="M", lc(navy) text(71.1 1999.5 "Annual Change =", color(navy) place(east))) ///
		(lfit le_raceadj year if gnd=="F", lc(maroon) text(88 1999.5 "Annual Change =", color(maroon) place(east))) ///
		if hh_inc_q==1 & inlist(loc_name,"Birmingham, AL", "Tampa, FL"), ///
		by(loc_name, rows(1) legend(off) note("")) ///
		graphregion(fcolor(white)) legend(off) ///
		ylab(70(5)90) yscale(range(73 90)) ///
		xlab(2001 2014) xscale(range(2000 2015)) ///
		xtitle("Year") ytitle("Expected Age at Death in Years") ///
		title(" ")

* Add trend coefs & CIs
local byplotcounter=0
foreach city in "Birmingham, AL" "Tampa, FL" {

	local ++byplotcounter

	foreach g in "M" "F" {
	
		local color=cond("`g'"=="M","navy","maroon")
		local textboxid=cond("`g'"=="M",1,2)

		qui levelsof le_raceadj_tr_q1_`g'_s if gnd=="`g'" & hh_inc_q==1 & loc_name=="`city'", local(texttrend) clean
		
		gr_edit .plotregion1.plotregion1[`byplotcounter'].textbox`textboxid'.text = {}
		gr_edit .plotregion1.plotregion1[`byplotcounter'].textbox`textboxid'.text.Arrpush Annual Change = `texttrend'

	}
}

* Add "Men/Women" legend
gr_edit .plotregion1.plotregion1[2].AddTextBox added_text editor 84.20748502118725 2014.24
gr_edit .plotregion1.plotregion1[2].added_text_new = 1
gr_edit .plotregion1.plotregion1[2].added_text_rec = 1
gr_edit .plotregion1.plotregion1[2].added_text[1].style.editstyle  angle(default) size(medium) color(maroon) horizontal(left) vertical(middle) margin(zero) linegap(zero) drawbox(no) boxmargin(zero) fillcolor(bluishgray) linestyle( width(thin) color(black) pattern(solid)) box_alignment(west) editcopy
gr_edit .plotregion1.plotregion1[2].added_text[1].text = {}
gr_edit .plotregion1.plotregion1[2].added_text[1].text.Arrpush Women

gr_edit .plotregion1.plotregion1[2].AddTextBox added_text editor 76 2014.24
gr_edit .plotregion1.plotregion1[2].added_text_new = 2
gr_edit .plotregion1.plotregion1[2].added_text_rec = 2
gr_edit .plotregion1.plotregion1[2].added_text[2].style.editstyle  angle(default) size(medium) color(navy) horizontal(left) vertical(middle) margin(zero) linegap(zero) drawbox(no) boxmargin(zero) fillcolor(bluishgray) linestyle( width(thin) color(black) pattern(solid)) box_alignment(west) editcopy
gr_edit .plotregion1.plotregion1[2].added_text[2].text = {}
gr_edit .plotregion1.plotregion1[2].added_text[2].text.Arrpush Men

* Remove blue background, set heading background to light blue-gray
gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
gr_edit .plotregion1.subtitle[1].style.editstyle fillcolor(ltbluishgray) editcopy
gr_edit .plotregion1.subtitle[1].style.editstyle linestyle(color(ltbluishgray)) editcopy

* Output figure
graph export "${root}/scratch/CZ trend scatters/LE trends in selected (2) cities.${img}", replace
project, creates("${root}/scratch/CZ trend scatters/LE trends in selected (2) cities.${img}") preserve


*** Plot LE trend for 4 CZs in by-plot, separately by gender
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)
	
	* Plot LE trend for 4 CZs in by-plot
	twoway	(scatter le_raceadj year, ms(o)) ///
			(lfit le_raceadj year, lc(navy)) ///
			if gnd == "`g'" & hh_inc_q==1 & inlist(loc_name,"Birmingham, AL","Cincinnati, OH","Tampa, FL","Des Moines, IA"), ///
			by(loc_name, legend(off) note("")) ///
			graphregion(color(white) fcolor(white)) bgcolor(white) ///
			xtitle("Year") ytitle("Race-Adjusted Life Expectancy") title("") ///
			xlab(2001 2014) xscale(range(2000 2015))
			
	gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
	gr_edit .plotregion1.plotregion1[1].style.editstyle boxstyle(linestyle(color(bluishgray))) editcopy	
	
	graph export "${root}/scratch/CZ trend scatters/LE trends in selected CZs - `gender'.${img}", replace
	project, creates("${root}/scratch/CZ trend scatters/LE trends in selected CZs - `gender'.${img}") preserve

}

*** Plot Q1 and Q4 trends of all CZs in Top 10 / Bottom 10 of Q1 trends
levelsof cz, local(czlist)
foreach cz of local czlist {
	
	* Get CZ name and rank
	levelsof loc_name if cz==`cz', local(czname) clean
	levelsof le_raceadj_tr_q1_rank if cz==`cz', local(czrank) clean
	
	* Generate scatter
	foreach q in 1 4 {
		twoway (scatter le_raceadj year if gnd=="M") ///
			   (scatter le_raceadj year if gnd=="F") ///
			   (lfit le_raceadj year if gnd=="M", lc(navy)) ///
			   (lfit le_raceadj year if gnd=="F", lc(maroon)) ///
			   if cz==`cz' & hh_inc_q==`q', ///
			   graphregion(fcolor(white)) legend(off) ///
			   ylab(70(5)95) ///
			   xtitle("Year") ytitle("Race-Adjusted Life Expectancy") ///
			   title("`czname' - `g' Q`q'", size(medsmall))
		graph export "${root}/scratch/CZ trend scatters/Q1 Trend Rank `czrank' - `czname' - Q`q' scatter.${img}", replace
		project, creates("${root}/scratch/CZ trend scatters/Q1 Trend Rank `czrank' - `czname' - Q`q' scatter.${img}") preserve
	}
}
