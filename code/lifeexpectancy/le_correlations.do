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
cap mkdir "${root}/scratch/Correlations with local life expectancy"
cap mkdir "${root}/scratch/Correlations with local life expectancy/data"

* Erase output numbers
cap erase "${root}/scratch/Correlations with local life expectancy/Reported correlations.csv"


/*** Estimate CZ-level correlations between life expectancy (levels and trends)
	 and local covariates.
***/


****************
*** Programs ***
****************

project, original("$root/code/ado/corr_reg.ado")

cap program drop report_corr_reg
program define report_corr_reg

	/*** Run a regression estimating the correlation between two variables,
		 and output the correlation and p-value to "Reported correlations.csv".
	***/

	syntax varlist(min=2 max=2 numeric) [if] [aweight fweight], [ vce(passthru) coef_fmt(string) p_fmt(string) ]
	
	*** Prep
	
	if ("`coef_fmt'"=="") local coef_fmt %9.2f
	if ("`p_fmt'"=="") local p_fmt %9.3f
	
	* Create convenient weight local
	if ("`weight'"!="") local wt [`weight'`exp']
	
	* Parse yvar and xvar
	local yvar=word("`varlist'",1)
	local xvar=word("`varlist'",2)

	*** Perform and output correlation

	corr_reg `varlist' `if' `wt', `vce'
	
	scalarout using "${root}/scratch/Correlations with local life expectancy/Reported correlations.csv", ///
		id("Corr of `:var lab `xvar'' with `:var lab `yvar'': coef") ///
		num(`=_b[vb]') fmt(`coef_fmt')
	test vb=0
	scalarout using "${root}/scratch/Correlations with local life expectancy/Reported correlations.csv", ///
		id("Corr of `:var lab `xvar'' with `:var lab `yvar'': pval") ///
		num(`=r(p)') fmt(`p_fmt')

end

cap program drop local_area_correlations
program define local_area_correlations

	/*** Input: a dataset with all the covariates we study as variables,
				and a specified variable we want to correlate with them.
				
		 Output: returns a dataset with the coefficient, std err and p-value for each correlation, 
				 and optionally generates a figure depicting a subset of the correlations.
	**/

	syntax varname, q_brfss(integer) [fig(string)]
	
	* Rename the BRFSS behavioural vars to have same varname regardless of quartile
	rename (cur_smoke_q`q_brfss' bmi_obese_q`q_brfss' exercise_any_q`q_brfss') ///
		   (cur_smoke_q bmi_obese_q exercise_any_q)
	
	* Load list of covariates used
	project, original("$root/code/covariates/list_of_covariates.do") preserve
	include "$root/code/covariates/list_of_covariates.do"
	
	*******
	*** Calculate correlations
	*******
	
	* Run regressions to estimate correlation coefficient and SE
	cap matrix drop corr_estimates
	local covarlabels ""
	foreach covar of global covars_all {
		local covarlabels `"`covarlabels' "`:var label `covar''""'
	
		di ""
		di "Covariate: `covar' {hline}"
	
		corr_reg `varlist' `covar' [w=pop2000], vce(cluster state_id)
		test vb=0
		
		matrix corr_estimates = nullmat(corr_estimates) \ (_b[vb],_se[vb],r(p))
		
	}
	
	* Store correlation coefficients and SEs in dataset
	matrix colnames corr_estimates = corr se pval
	clear
	svmat corr_estimates, names(col)
	
	gen varname=""
	gen varlabel=""
	forvalues n=1/`=_N' {
		qui replace varname = "`:word `n' of $covars_all'" in `n'
		qui replace varlabel = "`:word `n' of `covarlabels''" in `n'
		
	}
	
	*******
	*** Generate figure
	*******
	
	if ("`fig'"!="") {
		
		* Manually specify variables' order
		quietly {
			gen vnum = .
			replace vnum=30 if varname=="cur_smoke_q"
			replace vnum=29 if varname=="bmi_obese_q"
			replace vnum=28 if varname=="exercise_any_q"
			
			replace vnum=25 if varname=="puninsured2010"
			replace vnum=24 if varname=="reimb_penroll_adj10"
			replace vnum=23 if varname=="mort_30day_hosp_z"
			replace vnum=22 if varname=="med_prev_qual_z"
			
			replace vnum=19 if varname=="cs00_seg_inc"
			
			replace vnum=16 if varname=="gini99"
			replace vnum=15 if varname=="scap_ski90pcm"
			replace vnum=14 if varname=="rel_tot"
			replace vnum=13 if varname=="cs_frac_black"
			
			replace vnum=10 if varname=="unemp_rate"
			replace vnum=9 if varname=="pop_d_2000_1980"
			replace vnum=8 if varname=="lf_d_2000_1980"
			
			replace vnum=5 if varname=="cs_born_foreign"
			replace vnum=4 if varname=="median_house_value"
			replace vnum=3 if varname=="subcty_exp_pc"
			replace vnum=2 if varname=="pop_density"
			replace vnum=1 if varname=="cs_educ_ba"
		}
		
		* Generate confidence intervals
		gen ci_l = corr - 1.96*se
		gen ci_h = corr + 1.96*se
		
		forvalues i = 1/`=_N' {
			if !mi(vnum[`i']) local textlabels `textlabels' text(`=vnum[`i']' 1.1 "`:di %03.2f corr[`i']' (`:di %03.2f ci_l[`i']', `:di %03.2f ci_h[`i']')", placement(east) size(*0.5))
		}

		* Label covariates
		cap label drop varname
		lab define varname ///
			31 "Health Behaviors" ///
			30 "Q`q_brfss' Current Smokers" ///
			29 "Q`q_brfss' Obesity" ///
			28 "Q`q_brfss' Exercise Rate" ///
			26 "Health Care" ///
			25 "% Uninsured" ///
			24 "Medicare $ per Enrollee" ///
			23 "30-day Hospital Mortality Rate Index" ///
			22 "Index for Preventive Care" ///
			20 "Environmental Factors" ///
			19 "Income Segregation" ///
			17 "Inequality and Social Cohesion" ///
			16 "Gini Index" ///
			15 "Index for Social Capital" ///
			14 "% Religious" ///
			13 "% Black" ///
			11 "Labor Market Conditions" ///
			10 "Unemployment Rate in 2000" ///
			9 "% Change in Population, 1980-2000" ///
			8 "% Change in Labor Force, 1980-2000" ///
			6 "Other Factors" ///
			5 "% Immigrants" ///
			4 "Median House Value" ///
			3 "Local Gov. Expenditures" ///
			2 "Population Density" ///
			1 "% College Grads"
		lab values vnum varname

		* Plot figure of correlations
		twoway  (rspike ci_h ci_l vnum, horizontal lcolor(gs2)) ///
				(scatter vnum corr, mcolor(navy) m(S) msize(*.5)), ///
			ysize(5) ///
			ytitle("") xtit("Correlation Coefficient", size(small) margin(r=17 t=1)) title("") ///
			`textlabels' ///
			legend(off) ///
            ylab(1 2 3 4 5 6 8 9 10 11 13 14 15 16 17 19 20 22 23 24 25 26 28 29 30 31, valuelabel labsize(vsmall) nogrid angle(horizontal)) ///
			xlabel(-1 "-1" -.5 "-0.5" 0 "0" .5 "0.5" 1 "1", grid labsize(small)) xscale(range(-1 1.75)) ///
			xline(0, lc(gs12) lp(dash)) ///
			graphregion(fcolor(white))
		graph export "${root}/scratch/Correlations with local life expectancy/`fig' correlations.${img}", replace
		project, creates("${root}/scratch/Correlations with local life expectancy/`fig' correlations.${img}") preserve
		
        * Plot figure of correlations
        format corr %9.2f
        twoway  (rspike ci_h ci_l vnum, horizontal lcolor(gs2)) ///
                (scatter vnum corr, mcolor(navy) m(S) msize(*.5) ///
                                    mlabel(corr) mlabcolor(black) mlabpos(12) mlabgap(*.7) mlabsize(*.61)), ///
            ysize(6) ///
            ytitle("") xtit("Correlation Coefficient", size(small)) title("") ///
            legend(off) ///
            ylab(1 2 3 4 5 6 8 9 10 11 13 14 15 16 17 19 20 22 23 24 25 26 28 29 30 31, valuelabel labsize(vsmall) nogrid angle(horizontal)) ///
            xlabel(-1 "-1" -.5 "-0.5" 0 "0" .5 "0.5" 1 "1", grid labsize(small)) xscale(range(-1 1)) ///
            xline(0, lc(gs12) lp(dash)) ///
            graphregion(fcolor(white))
        graph export "${root}/scratch/Correlations with local life expectancy/`fig' correlations - marker labels.${img}", replace
        project, creates("${root}/scratch/Correlations with local life expectancy/`fig' correlations - marker labels.${img}") preserve
		
		* Export data underlying the figure
		order vnum varname varlabel
		export delim if !mi(vnum) using "${root}/scratch/Correlations with local life expectancy/data/`fig' correlations.csv", nolabel replace
		project, creates("${root}/scratch/Correlations with local life expectancy/data/`fig' correlations.csv") preserve
		
		drop vnum ci_l ci_h
	}
		
end

cap program drop corr_table_by_geo_gnd_quartile
program define corr_table_by_geo_gnd_quartile

	/*** Create and output a table of LE correlations with all covariates,
		 with columns for:
			- correlations with LE by Gender x Income Quartile (Q1 & Q4)
			- mean value of covariate
				- separate rows for mean of BRFSS behaviour covariates for Q1 and Q4
	***/

	syntax , geo(name)
	
	* Load life expectancies: geo by Gender x Income Quartile
	project, original("$derived/le_estimates/`geo'_leBY_gnd_hhincquartile.dta")
	use `geo' gnd hh_inc_q le_raceadj using "$derived/le_estimates/`geo'_leBY_gnd_hhincquartile.dta", clear
	
	* Reshape wide on gender and income quartile
	rename le_raceadj le_raceadj_
	reshape wide le_raceadj_, i(`geo' hh_inc_q) j(gnd) string
	
	rename le_raceadj* le_raceadj*q
	reshape wide le_raceadj_Mq le_raceadj_Fq, i(`geo') j(hh_inc_q)
	
	* Merge in covariates data
	project, original("${derived}/final_covariates/`geo'_full_covariates.dta") preserve
	merge 1:1 `geo' using "${derived}/final_covariates/`geo'_full_covariates.dta", assert(2 3) keep(3) nogen
	if ("`geo'"=="cty") rename cty_pop2000 pop2000
		
	* Calculate tables of correlations
	foreach g in "M" "F" {
		foreach q in 1 4 {
		
			tempfile corr`g'q`q'
			preserve
			
			local_area_correlations le_raceadj_`g'q`q', q_brfss(`q')
			replace varlabel="Smoking Rate in Corresponding Quantile" if varname=="cur_smoke_q"
			replace varlabel="Obesity Rate in Corresponding Quantile" if varname=="bmi_obese_q"
			replace varlabel="Exercise Rate in Corresponding Quantile" if varname=="exercise_any_q"
		
			save `corr`g'q`q''
			restore
			
		}
	}
	
	* Compute means of covariates
	collapse (mean) `:subinstr global covars_all "cur_smoke_q bmi_obese_q exercise_any_q" "cur_smoke_q1 bmi_obese_q1 exercise_any_q1 cur_smoke_q4 bmi_obese_q4 exercise_any_q4"' ///
		[w=pop2000]
	xpose, clear varname
	rename v1 mean
	rename _varname varname
	order varname
	
	tempfile corr_means
	save `corr_means'
	
	* Combine correlation coefficients and means
	foreach q in 1 4 {
		foreach g in "M" "F" {
			merge 1:1 varname using `corr`g'q`q'', keepusing(corr) nogen
			rename corr corr_`g'q`q'
		}
	}
	tempfile combined
	save `combined'
	
	* Combine variable labels, means & correlation coefficients; with rows in correct order
	use varname varlabel using `corrMq1', clear
	gen order=_n
	merge 1:1 varname using `combined', nogen
	sort order varname
	drop order
	
	* Output table of correlations
	export delim using "${root}/scratch/Correlations with local life expectancy/Correlates of LE levels by `geo' x Gender x Income Quartile.csv", replace
	project, creates("${root}/scratch/Correlations with local life expectancy/Correlates of LE levels by `geo' x Gender x Income Quartile.csv")

end


*******************************************************
*** LE levels, pooling income quartiles and genders ***
*******************************************************

*** Load data

* Load life expectancies: CZ by Gender
project, original("$derived/le_estimates/cz_leBY_gnd.dta")
use cz gnd le_raceadj using "$derived/le_estimates/cz_leBY_gnd.dta", clear

* Take unweighted average of male and female in each CZ
isid cz gnd
collapse (mean) le_*, by(cz)
label var le_raceadj "LE pooling all income quartiles"

* Merge in covariates data
project, original("${derived}/final_covariates/cz_full_covariates.dta") preserve
merge 1:1 cz using "${derived}/final_covariates/cz_full_covariates.dta", assert(2 3) keep(3) nogen


*** Paper numbers

* Correlation between Gini and LE (pooling all income quartiles)
report_corr_reg le_raceadj gini99 [w=pop2000], vce(cluster state_id) p_fmt(%9.3f)


*****************************************************
*** LE levels by Income Quartile, pooling genders ***
*****************************************************

*** Load data

* Load life expectancies: CZ by Gender x Income Quartile
project, original("$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta")
use cz gnd hh_inc_q le_raceadj using "$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta", clear
rename le_raceadj le_raceadj_q
reshape wide le_raceadj_q, i(cz gnd) j(hh_inc_q)

* Take unweighted average of male and female in each CZ
isid cz gnd
collapse (mean) le_*, by(cz)

label var le_raceadj_q1 "Q1 LE"

* Merge in covariates data
project, original("${derived}/final_covariates/cz_full_covariates.dta") preserve
merge 1:1 cz using "${derived}/final_covariates/cz_full_covariates.dta", assert(2 3) keep(3) nogen


*** Paper numbers

* Corr between segregation and difference in LE between Q1 and Q4
gen le_raceadj_diffq4q1 = le_raceadj_q4 - le_raceadj_q1
label var le_raceadj_diffq4q1 "Q4-Q1 diff in LE"

report_corr_reg le_raceadj_diffq4q1 cs00_seg_inc [w=pop2000], vce(cluster state_id) p_fmt(%9.2f)

* Corr between MANY covariates and Q1 LE
foreach var of varlist cs00_seg_inc cur_smoke_q1 bmi_obese_q1 hhinc00 cs_born_foreign cs_educ_ba subcty_exp_pc {
	report_corr_reg le_raceadj_q1 `var' [w=pop2000], vce(cluster state_id)
}


*** Fig: Correlation between LE and Income Inequality (Gini) by Quartile

* Prepare corr/SE text labels
local colors ///
	navy maroon forest_green dkorange teal cranberry lavender ///
	khaki sienna emidblue emerald brown erose gold bluishgray
	
local textlabels ""

forvalues q = 1/4 {

	* Get predicted value at x-value where we're placing the label
	qui reg le_raceadj_q`q' gini99 [aw=pop2000]
	local ytext = _b[_cons] + _b[gini99] * 0.43 + cond(`q'==1,0.5,1.2)

	* Store text label
	qui corr_reg le_raceadj_q`q' gini99 [aw=pop2000], vce(cluster state_id)
	local ci_l = _b[vb] - 1.96 * _se[vb]
	local ci_h = _b[vb] + 1.96 * _se[vb]
	local textlabels `textlabels' text(`ytext' 0.46 "Corr. = `:di %04.2f _b[vb]' (`:di %04.2f `ci_l'', `:di %04.2f `ci_h'')", color(`:word `q' of `colors'') size(*.9) place(west))

}

* Generate figure
binscatter le_raceadj_q1 le_raceadj_q2 le_raceadj_q3 le_raceadj_q4 gini99 [aw=pop2000], ///
	title("") xtitle("Gini Index in CZ") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
	msymbol(circle triangle square diamond) ///
	legend(off) ///
	`textlabels' ///
	ylabel(78(2)87) ///
	savegraph("${root}/scratch/Correlations with local life expectancy/Gini correlation with LE levels by quartile.${img}") ///
	savedata("${root}/scratch/Correlations with local life expectancy/data/Gini correlation with LE levels by quartile - binned scatterpoints") ///
	replace
project, creates("${root}/scratch/Correlations with local life expectancy/Gini correlation with LE levels by quartile.${img}") preserve
project, creates("${root}/scratch/Correlations with local life expectancy/data/Gini correlation with LE levels by quartile - binned scatterpoints.csv") preserve

* Export data underlying binscatter
export delim cz state_id le_raceadj_q1 le_raceadj_q2 le_raceadj_q3 le_raceadj_q4 gini99 pop2000 ///
	using "${root}/scratch/Correlations with local life expectancy/data/Gini correlation with LE levels by quartile - raw data.csv", ///
	replace
project, creates("${root}/scratch/Correlations with local life expectancy/data/Gini correlation with LE levels by quartile - raw data.csv") preserve 


*** Fig: Correlation between Q4 LE level and local covariates
preserve
local_area_correlations le_raceadj_q4, fig("Q4 LE levels") q_brfss(4)
restore


*** Fig: Correlation between Q1 LE level and local covariates
local_area_correlations le_raceadj_q1, fig("Q1 LE levels") q_brfss(1)


*** Output top 5 strongest correlations among "Other Factors" with Q1 LE levels
* (These determine which of the "Other Factors" appear in the figures.)
gen otherfactor=0
foreach v of global covars_other {
	replace otherfactor=1 if varname=="`v'"
}
keep if otherfactor==1
drop otherfactor

gen abscorr=abs(corr)
gsort - abscorr

keep in 1/5
drop abscorr
export delim using "${root}/scratch/Correlations with local life expectancy/Five strongest correlates of Q1 LE levels in Other Factors.csv", replace
project, creates("${root}/scratch/Correlations with local life expectancy/Five strongest correlates of Q1 LE levels in Other Factors.csv")


*****************************************************
*** LE trends by Income Quartile, pooling genders ***
*****************************************************

*** Load data

* Load life expectancy trends: CZ by Gender x Income Quartile
project, original("${derived}/le_trends/cz_letrendsBY_gnd_hhincquartile.dta")
use cz gnd hh_inc_q le_raceadj_b_year using "${derived}/le_trends/cz_letrendsBY_gnd_hhincquartile.dta", clear
rename le_raceadj_b_year le_raceadj_trend_q
reshape wide le_raceadj_trend_q, i(cz gnd) j(hh_inc_q)

* Take unweighted average of male and female in each CZ
isid cz gnd
collapse (mean) le_*, by(cz)

* Merge in covariates data
project, original("${derived}/final_covariates/cz_full_covariates.dta") preserve
merge 1:1 cz using "${derived}/final_covariates/cz_full_covariates.dta", assert(2 3) keep(3) nogen


*** Correlation between Q1 LE trend and local covariates
local_area_correlations le_raceadj_trend_q1, fig("Q1 LE trends") q_brfss(1)


**************************************************
*** LE levels by CZ x Gender x Income Quartile ***
**************************************************

corr_table_by_geo_gnd_quartile, geo(cz)


******************************************************
*** LE levels by County x Gender x Income Quartile ***
******************************************************

corr_table_by_geo_gnd_quartile, geo(cty)


*****************************************
*** Project creates: reported numbers ***
*****************************************

project, creates("${root}/scratch/Correlations with local life expectancy/Reported correlations.csv")
