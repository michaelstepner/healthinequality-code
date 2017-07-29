* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
if (c(os)=="Windows") global img wmf
else global img png


/*** Plot NLMS Gompertz mortality-age profiles implied by estimated race shifters.
	 - Separate series for each race.
	 - Separate panel for each gender.
***/

************************
*** Generate Figures ***
************************

project, original("${root}/data/derived/NLMS/nlms_v5_s11_sampleA.dta")
use "${root}/data/derived/NLMS/nlms_v5_s11_sampleA.dta"

foreach g in "Male" "Female" {

	streg i.csdiv i.incq i.racegrp if gnd==`"`=substr("`g'",1,1)'"', dist(gompertz) nohr ancillary(i.csdiv i.incq i.racegrp) coeflegend
	
	* Note: plotting a different income quartile or census plot would just shift and pivot all the lines,
	* 		without changing their relative positions.
	
	twoway	(function y = _b[_t:_cons] + _b[gamma:_cons] * (x - 40), range(40 90)) ///
			(function y = _b[_t:_cons] + _b[_t:2.racegrp] + (_b[gamma:_cons] + _b[gamma:2.racegrp]) * (x - 40), range(40 90)) ///
			(function y = _b[_t:_cons] + _b[_t:3.racegrp] + (_b[gamma:_cons] + _b[gamma:3.racegrp]) * (x - 40), range(40 90)) ///
			(function y = _b[_t:_cons] + _b[_t:4.racegrp] + (_b[gamma:_cons] + _b[gamma:4.racegrp]) * (x - 40), range(40 90)), ///
		title(`g') xtitle("Age") ytitle("Log Mortality Rate") ///
		xlab(40(10)90) ///
		legend(ring(0) pos(4) c(1) order(2 1 3 4)) legend(lab(1 White) lab(2 Black) lab(3 Hispanic) lab(4 Asian)) ///
		graphregion(fcolor(white))
	graph export "${root}/scratch/NLMS mortality profiles by race/NLMS_raceshifter_mortality_profiles_`g'.${img}", replace
	project, creates("${root}/scratch/NLMS mortality profiles by race/NLMS_raceshifter_mortality_profiles_`g'.${img}") preserve
	
}
