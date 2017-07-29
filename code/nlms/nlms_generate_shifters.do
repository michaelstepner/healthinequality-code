* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set working directory
cd "$root/data/derived/NLMS"

* Create required folders
cap mkdir "$root/data/derived/NLMS/raceshifters"

/*** Estimate the differences in Gompertz intercept and slope by race,
	 relative to the non-Black non-Hispanic group.
	 
	 Generate the estimates for three different by-groups:
	 - Sex
	 - Sex x Income Quartile
	 - Sex x Census Region
***/

****************
*** Programs ***
****************

program define nlms_estimate_raceshifters

	/*** Given an NLMS panel, estimate the Gompertz parameters for each race
		 while controlling for Income Quartile and Census Divsion.
		 
		 Return the race shifters, which are the differences in Gompertz
		 parameters relative to the non-Black non-Hispanic group.
		 
		 Has options for 3 by-groups:
			- by Sex
			- by Sex x Income Quartile
			- by Sex x Census Region
		 
	***/
		
	syntax using/, [ bootstrap replace stderr save_bysex(string) save_bysexincq(string) save_bysexcsregion(string) ]

	*****************
	*** Load data ***
	*****************
	
	* Load NLMS sample
	use `"`using'"', clear
	
	* If bootstrapping: assign the number of draws for each observation,
	* using weights to determine probability of draw
	if ("`bootstrap'"!="") {
	
		wsample num_draws, wt(wt)
		keep if num_draws>0  // for speed, drop unnecessary obs
		
		streset [fw=num_draws], noshow
		drop wt startage endage inddea  // for speed, drop unnecessary vars
		
	}
	
	******************************
	*** Estimate race shifters ***
	******************************

	*** Specify parameters to save
	local save_est ///
diff_gomp_int_black = _b[_t:2.racegrp] ///
diff_gomp_int_hisp = _b[_t:3.racegrp] ///
diff_gomp_int_asian = _b[_t:4.racegrp] ///
diff_gomp_slope_black = _b[gamma:2.racegrp] ///
diff_gomp_slope_hisp = _b[gamma:3.racegrp] ///
diff_gomp_slope_asian = _b[gamma:4.racegrp]

	if ("`stderr'"=="stderr") local save_est `save_est' ///
se_int_black = _se[_t:2.racegrp] ///
se_int_hisp = _se[_t:3.racegrp] ///
se_int_asian = _se[_t:4.racegrp] ///
se_slope_black = _se[gamma:2.racegrp] ///
se_slope_hisp = _se[gamma:3.racegrp] ///
se_slope_asian = _se[gamma:4.racegrp] ///

	*** Run regressions

	* by Sex
	if ("`save_bysex'"!="") statsby `save_est', saving(`save_bysex', `replace') ///
		by(gnd): streg i.csdiv i.incq i.racegrp, dist(gompertz) nohr ancillary(i.csdiv i.incq i.racegrp)

	* by Sex x Income Quartile
	if ("`save_bysexincq'"!="") statsby `save_est', saving(`save_bysexincq', `replace') ///
		by(gnd incq): streg i.csdiv i.racegrp, dist(gompertz) nohr ancillary(i.csdiv i.racegrp)
	
	* by Sex x Census Region
	if ("`save_bysexcsregion'"!="") statsby `save_est', saving(`save_bysexcsregion', `replace') ///
		by(gnd csregion): streg i.csdiv i.incq i.racegrp, dist(gompertz) nohr ancillary(i.csdiv i.incq i.racegrp)
	
	***************************
	*** save13 and add note ***
	***************************
	
	* If not bootstrapping, reopen each saved file and save13 it, with a note
	if ("`bootstrap'"=="") {
	
		foreach file in "`save_bysex'" "`save_bysexincq'" "`save_bysexcsregion'" {
			if ("`file'"=="") continue // skip by-group if wasn't specified
			
			use "`file'", clear
			label data "NOTE: Gompertz intercepts in this data correspond to intercepts at age 40."
			save13 `"`file'"', replace
		}
		
	}
	
end


***************************************
*** Generate Gompertz race shifters ***
***************************************

project, uses("nlms_v5_s11_sampleA.dta")

nlms_estimate_raceshifters using "nlms_v5_s11_sampleA.dta", stderr ///
	save_bysex("raceshifters/raceshifters_v5A_BYsex.dta") ///
	save_bysexincq("raceshifters/raceshifters_v5A_BYsex_incq.dta") ///
	save_bysexcsregion("raceshifters/raceshifters_v5A_BYsex_csregion.dta") ///
	replace

project, creates("raceshifters/raceshifters_v5A_BYsex.dta")
project, creates("raceshifters/raceshifters_v5A_BYsex_incq.dta")
project, creates("raceshifters/raceshifters_v5A_BYsex_csregion.dta")

