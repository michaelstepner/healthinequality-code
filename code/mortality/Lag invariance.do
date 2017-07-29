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

* Create required folders
cap mkdir "${root}/scratch/Lag invariance"
cap mkdir "${root}/scratch/Lag invariance/data"

/*** Examines the "lag invariance" property of mortality rates, and shows
	that this is because of the high degree of serial correlation of income.
***/
	
**************************************************
*** Income Lag Invariance - Mortality Profiles ***
**************************************************
	
* Load mortality data with all income lags
project, original("${root}/data/derived/Mortality Rates/With all income lags/mskd_national_mortratesBY_gnd_hhincpctile_age_year_WithAllLags.dta")
use "${root}/data/derived/Mortality Rates/With all income lags/mskd_national_mortratesBY_gnd_hhincpctile_age_year_WithAllLags.dta", clear

* Compute unweighted average mortality rate of 50-54 year olds in 2014
replace mortrate = mortrate * 100000
keep if inrange(age_at_d,50,54) & yod==2014

isid gnd pctile age_at_d lag
collapse (mean) mortrate, by(gnd pctile lag)
recast float mortrate, force

* Plot mortality-income profile at different income lags
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	* Plot fig
	twoway	(scatter mortrate pctile if lag==2, ms(o)) ///
			(scatter mortrate pctile if lag==5, ms(t)) ///
			(scatter mortrate pctile if lag==10, ms(s)) ///
			if gnd=="`g'", ///
			ylab(0(500)1500, gmin gmax) ///
			xtitle("Household Income Percentile")  ///
			ytitle("Deaths per 100,000") title("") ///
			legend( ///
				ring(0) pos(2) c(1) order(3 2 1) bmargin(large) ///
				label(1 "2 year lag") label(2 "5 year lag") label(3 "10 year lag") ///
			)
	graph export "${root}/scratch/Lag invariance/Mortality v Income Percentile profile of 2014 50-54yo with varying lags - `gender'.${img}", replace
	project, creates("${root}/scratch/Lag invariance/Mortality v Income Percentile profile of 2014 50-54yo with varying lags - `gender'.${img}") preserve
	
	* Export data underlying fig
	export delim if gnd=="`g'" & inlist(lag,2,5,10) ///
		using "${root}/scratch/Lag invariance/data/Mortality v Income Percentile profile of 2014 50-54yo with varying lags - `gender'.csv", replace
	project, creates("${root}/scratch/Lag invariance/data/Mortality v Income Percentile profile of 2014 50-54yo with varying lags - `gender'.csv") preserve
	
}

************************************
*** Serial Correlation of Income ***
************************************

* Load correlations
foreach g in "M" "F" {
	project, original("${root}/data/raw/IRS correlations between income lags/corr_`g'.xlsx")
	import excel using "${root}/data/raw/IRS correlations between income lags/corr_`g'.xlsx", clear ///
		firstrow
	rename A corrvar
	keep corrvar l0_pctile
	
	drop if corrvar=="mort"
	gen byte lag = real( regexs(regexm(corrvar,"^l([0-9]+)_pctile$")) )
	drop corrvar
	
	rename l0_pctile incomecorr_`g'
	
	tempfile income_corr_`g'
	save `income_corr_`g''
}

* Combine male and female serial income correlations
use `income_corr_M'
merge 1:1 lag using `income_corr_F', assert(3) nogen
order lag

twoway	(connect incomecorr_M lag, m(t)) ///
		(connect incomecorr_F lag, m(o)) ///
	if lag<=10, ///
	xtitle("Lag (x)") ///
	ytitle("Correlation Between Rank in Year t and t - x") ///
	ylabel(0 "0" .2 "0.2" .4 "0.4" .6 "0.6" .8 "0.8" 1 "1") ///	
	legend( ///
		ring(0) pos(4) c(1) bmargin(medium) ///
		label(1 "Men") label(2 "Women") ///
	)
graph export "${root}/scratch/Lag invariance/Serial correlation of income.${img}", replace 
project, creates("${root}/scratch/Lag invariance/Serial correlation of income.${img}") preserve

* Export data underlying fig
export delim if lag<=10 ///
	using "${root}/scratch/Lag invariance/data/Serial correlation of income.csv", replace
project, creates("${root}/scratch/Lag invariance/data/Serial correlation of income.csv")


