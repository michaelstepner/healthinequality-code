* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
cd "${root}/data/derived/NLMS"

if (c(os)=="Windows") global img wmf
else global img png

* Create required folders
cap mkdir "$root/scratch/NLMS race shifters by incq and csregion"
cap mkdir "$root/scratch/NLMS race shifters by incq and csregion/data"

/*** Generate figures comparing whether NLMS Gompertz race shifters are similar
	 across:
	 
	 1. Income quartiles
	 2. Census regions
	 
	 by comparing the race shifters estimated separately in each quartile/region
	 to the pooled estimate.
***/


*************************************
*** Define fig generation program ***
*************************************

cap program drop raceshifter_comparison
program define raceshifter_comparison

	/*** 1. Loads the estimated Gompertz race shifters by:
			 a. Sex
			 b. Sex x Income Quartile OR Census Region
		 
		 2. Creates figures comparing the estimates in each Quartile/Region
			to the pooled estimates; one for each race.
	***/

	syntax , compareby(name)

	*** Load shifters
	project, original("raceshifters/raceshifters_v5A_BYsex_`compareby'.dta")
	project, original("raceshifters/raceshifters_v5A_BYsex.dta")
	use "raceshifters/raceshifters_v5A_BYsex_`compareby'.dta", clear
	append using "raceshifters/raceshifters_v5A_BYsex.dta", nolabel
	
	if ("`compareby'"=="csregion") {
		label var csregion "Census Region"
		local xlab xlab(1 "Northeast" 2 "Midwest" 3 "South" 4 "West")
	}

	* Generate 95% confidence intervals
	foreach var of varlist diff_gomp_* {
		
		local sevar=subinstr("`var'","diff_gomp","se",1)
		local ciLvar=subinstr("`var'","diff_gomp","ciL",1)
		local ciHvar=subinstr("`var'","diff_gomp","ciH",1)
		
		gen `ciLvar'=`var'-1.96*`sevar'
		gen `ciHvar'=`var'+1.96*`sevar'
		
	}
	
	* Rename gender values
	replace gnd=cond(gnd=="M","Men","Women")
	
	* Reshape int/slope long
	ds *_int_*
	local ds=r(varlist)
	local reshapevars : subinstr local ds "_int" "@", all
	reshape long `reshapevars', i(gnd `compareby') j(parameter) string
	
	* Truncate CIs that extend past y-axis range
	foreach r in black hisp asian {
	
		gen		ciL_`r'_trunc = -2 if parameter=="_int" & ciL_`r'<-2
		replace ciL_`r'_trunc = -0.105 if parameter=="_slope" & ciL_`r'<-0.105
		
		gen		ciH_`r'_trunc = 2 if parameter=="_int" & ciH_`r'>2
		replace ciH_`r'_trunc = 0.105 if parameter=="_slope" & ciH_`r'>0.105
	
	}

	* Generate figs
	foreach r in black hisp asian {

		*** Produce initial fig
		twoway  (scatter diff_gomp_`r' `compareby', msize(*1.2)) ///
				(rcap ciH_`r' diff_gomp_`r' `compareby' if mi(ciH_`r'_trunc), lc(navy)) ///	
				(rspike ciH_`r'_trunc diff_gomp_`r' `compareby', lc(navy) msize(0) lpattern(-##)) ///	
				(rcap ciL_`r' diff_gomp_`r' `compareby' if mi(ciL_`r'_trunc), lc(navy)) ///	
				(rspike ciL_`r'_trunc diff_gomp_`r' `compareby', lc(navy) msize(0) lpattern(-##)) ///
				, ///
				by(parameter gnd, legend(off) note("") iytitle yrescale) ///
				ytitle("Diff. Between Slopes") ylab(, grid gmin gmax) ///
				yline(0, noextend lc(maroon)) ///
				`xlab' ///
				yscale(range(-.105 .105))

		*** Apply corrections to fig

		* Place the point estimate line in the correct place
		local plotcounter=0
		foreach par in "_int" "_slope" {
		
			foreach gender in "Men" "Women" {
			
					sum diff_gomp_`r' if parameter=="`par'" & gnd=="`gender'" & mi(`compareby'), meanonly
					assert r(N)==1
					
					local ++plotcounter
					gr_edit .plotregion1.plotregion1[`plotcounter']._xylines[1].z = `r(mean)'		
					
			}
			
		}
			
		* Correct y-axes
		gr_edit .plotregion1.yaxis1[1].reset_rule -2 2 1 , tickset(major) ruletype(range) 
		gr_edit .plotregion1.yaxis1[2].reset_rule -2 2 1 , tickset(major) ruletype(range) 
		gr_edit .plotregion1.yaxis1[3].reset_rule -.1 .1 .05 , tickset(major) ruletype(range) 
		gr_edit .plotregion1.yaxis1[4].reset_rule -.1 .1 .05 , tickset(major) ruletype(range) 	
			
		* No subtitles on bottom 2 plots
		gr_edit .plotregion1.subtitle[3].draw_view.setstyle, style(no)
		gr_edit .plotregion1.subtitle[4].draw_view.setstyle, style(no)
		
		* Correct y-titles
		gr_edit .l1title.draw_view.setstyle, style(no)  // no extra y-title
		
		gr_edit .plotregion1.yaxis1[1].title.text = {}
		gr_edit .plotregion1.yaxis1[1].title.text.Arrpush Diff. Between Intercepts
		
		* Correct subtitles
		gr_edit .plotregion1.subtitle[1].text = {}
		gr_edit .plotregion1.subtitle[1].text.Arrpush Men
		gr_edit .plotregion1.subtitle[2].text = {}
		gr_edit .plotregion1.subtitle[2].text.Arrpush Women
		
		* Remove right column y-titles and y-axes
		gr_edit .plotregion1.yaxis1[4].title.draw_view.setstyle, style(no)
		gr_edit .plotregion1.yaxis1[4].draw_view.setstyle, style(no)
		gr_edit .plotregion1.yaxis1[2].title.draw_view.setstyle, style(no)
		gr_edit .plotregion1.yaxis1[2].draw_view.setstyle, style(no)
		
		* Remove blue background, set heading background to light blue-gray
		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .plotregion1.subtitle[1].style.editstyle fillcolor(ltbluishgray) editcopy
		gr_edit .plotregion1.subtitle[1].style.editstyle linestyle(color(ltbluishgray)) editcopy
	
		*** Export fig
		graph export "${root}/scratch/NLMS race shifters by incq and csregion/NLMS_raceshifterBY`compareby'_ALL`r'.${img}", replace
		project, creates("${root}/scratch/NLMS race shifters by incq and csregion/NLMS_raceshifterBY`compareby'_ALL`r'.${img}") preserve
		
		*** Export data underlying fig
		export delim gnd `compareby' parameter diff_gomp_`r' ciL_`r' ciH_`r' ///
			using "${root}/scratch/NLMS race shifters by incq and csregion/data/NLMS_raceshifterBY`compareby'_ALL`r'.csv", replace
		project, creates("${root}/scratch/NLMS race shifters by incq and csregion/data/NLMS_raceshifterBY`compareby'_ALL`r'.csv") preserve

	}
	
end
	

************************
*** Generate Figures ***
************************
	
raceshifter_comparison, compareby(incq)
raceshifter_comparison, compareby(csregion)
