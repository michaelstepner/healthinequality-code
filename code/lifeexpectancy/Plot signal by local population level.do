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
cap mkdir "${root}/scratch/Signal to Noise"

/*** For each CZ or County life expectancy reported in online tables, plot
	 fraction of variance that is signal against population size.
***/


****************
*** Programs ***
****************

cap program drop plot_signalfrac_by_pop
program define plot_signalfrac_by_pop

	/*** Plot fraction of variance that is signal against population size,
		 separately by Gender x Income Quantile.
	***/

	syntax name using/, geo(name) nq(integer) label(string) [ year(name) incq(name) plotq(string) xlab(passthru) xline(passthru) xsize(passthru) ]
	local var `namelist'
	if ("`incq'"=="") local incq hh_inc_q
	if ("`plotq'"=="") local plotq 1 4

	* Load point estimates and bootstrap SDs
	project, original(`"`using'"')
	use `"`using'"', clear
	isid `geo' gnd `incq' `year'
	keep `geo' gnd `incq' `year' `var' sd_`var'
	rename sd* sdnoise*
	
	* Merge in CZ populations
	if ("`geo'"=="cz") {
		project, original("${derived}/final_covariates/cz_pop.dta") preserve
		merge m:1 `geo' using "${derived}/final_covariates/cz_pop.dta", ///
			assert(2 3) keep(3) nogen
	}
	else if ("`geo'"=="cty") {
		project, original("${derived}/final_covariates/cty_full_covariates.dta") preserve
		merge m:1 `geo' using "${derived}/final_covariates/cty_full_covariates.dta", ///
			assert(2 3) keep(3) nogen ///
			keepusing(cty_pop2000)
		rename cty_pop2000 pop2000
	}
	
	* Generate total SD, in each ventile of CZ pop
	fastxtile pop_quantile = pop2000, nq(`nq')
	egen sdtotal_`var' = sd(`var'), by(gnd `incq' `year' pop_quantile)
	
	* Decompose variance into signal and noise
	gen varnoise_`var' = sdnoise_`var'^2
	gen vartotal_`var' = sdtotal_`var'^2
	gen varsignal_`var' = vartotal_`var' - varnoise_`var'
	gen fracsignal = varsignal_`var' / vartotal_`var'
	
	* Plot fraction of variance that is signal for Q1 and Q4, by Population
	graph drop _all
	foreach gender in "Male" "Female" {
	
		local g = substr("`gender'",1,1)

		foreach q in `plotq' {
		
			if (`q'==1) local color navy
			else local color maroon
	
			binscatter fracsignal pop2000 if gnd=="`g'" & `incq'==`q' & pop_quantile<`nq', ///
				xq(pop_quantile) line(none) color(`color') ///
				ytitle("Signal Variance / Total Variance") ///
				xtitle("Population") ///
				ylab(0(0.1)1, gmin gmax) ///
				`xlab' `xline' ///
				name(`g'q`q') subtitle("`gender' Q`q'")
			local plots `plots' `g'q`q'
				
		}
		
	}
	
	graph combine `plots', rows(2) iscale(*0.8) ysize(7) `xsize' ///
		title("Signal Fraction: `label'", size(medium)) ///
		note("Note: Quantile with highest population omitted for scale.", size(vsmall))
	graph export "${root}/scratch/Signal to Noise/`label' - Signal Fraction by `geo' pop.png", replace
	graph drop `plots'
	project, creates("${root}/scratch/Signal to Noise/`label' - Signal Fraction by `geo' pop.png")
	
end


**********************
*** Generate Plots ***
**********************
	
*** CZ LE Levels, by Gender x Income Quartile
plot_signalfrac_by_pop le_raceadj using "$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile.dta", ///
	geo(cz) label(CZ LE Levels) ///
	nq(20) ///
	xlab(25e3 "25k" 250e3 "250k" 500e3 "500k" 750e3 "750k" 1e6 "1M" 1.25e6 "1.25M" 1.5e6 "1.5M", grid)

*** CZ LE Trends, by Gender x Income Quartile
plot_signalfrac_by_pop le_raceadj_b_year using "$derived/le_trends_stderr/cz_SEletrendsBY_gnd_hhincquartile.dta", ///
	geo(cz) label(CZ LE Trends) ///
	nq(6) ///
	xlab( 500e3 "500k" 1e6 "1M" 1.5e6 "1.5M" 2e6 "2M" 2.5e6 "2.5M" 3e6 "3M", grid)

*** CZ LE Levels, by Gender x Income Quartile x Year
plot_signalfrac_by_pop le_raceadj using "$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile_year.dta", ///
	year(year) ///
	geo(cz) label(CZ LE Levels by Year) ///
	nq(6) ///
	xlab( 500e3 "500k" 1e6 "1M" 1.5e6 "1.5M" 2e6 "2M" 2.5e6 "2.5M" 3e6 "3M", grid)

*** CZ LE Levels, by Gender x Income Ventile
plot_signalfrac_by_pop le_raceadj using "$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincventile.dta", ///
	incq(hh_inc_v) plotq(1 5 10 15 20) xsize(10) ///
	geo(cz) label(CZ LE Levels by Ventile) ///
	nq(10) ///
	xlab(250e3 "250k" 500e3 "500k" 1e6 "1M" 1.5e6 "1.5M" 2e6 "2M", grid)

*** County LE Levels, by Gender x Income Quartile
plot_signalfrac_by_pop le_raceadj using "$derived/le_estimates_stderr/cty_SEleBY_gnd_hhincquartile.dta", ///
	geo(cty) label(County LE Levels) ///
	nq(20) ///
	xlab(25e3 "25k" 100e3 "100k" 200e3 "200k" 300e3 "300k" 400e3 "400k" 500e3 "500k", grid)

	
