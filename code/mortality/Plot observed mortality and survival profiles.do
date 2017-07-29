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
cap mkdir "${root}/scratch/National p5 and p95 mortality and survival profiles"
cap mkdir "${root}/scratch/National p5 and p95 mortality and survival profiles/data"
cap mkdir "${root}/scratch/NCHS mortality profiles"

* Erase output numbers
cap rm "${root}/scratch/National p5 and p95 mortality and survival profiles/Gompertz R squared.csv"

/*** Plot national mortality and survival profiles at p5 and p95, by gender.
	 Plot NCHS mortality profiles in 2001, by gender.
***/

****************
*** Programs ***
****************

cap program drop manual_r2
program define manual_r2, rclass

	/*** Manually calculate the R^2 of a univariate linear relationship.
	
		 Used here to calculate the R^2 of Gompertz relationships which are
			estimated using MLE instead of OLS.
	***/

	syntax varlist(min=2 max=2) [if], int(real) slope(real)
	local y : word 1 of `varlist'
	local x : word 2 of `varlist'
	
	tempvar sqresid_y
	qui gen `sqresid_y' = ( `y' - (`int' + `x' * `slope') )^2 `if'
	
	tempvar sqdiffmean_y
	sum `y' `if', meanonly
	qui gen `sqdiffmean_y' = (`y' - r(mean))^2 `if'
		
	sum `sqresid_y', meanonly
	local RSS=r(sum)
	
	sum `sqdiffmean_y', meanonly
	local TSS=r(sum)
	
	return clear
	return scalar TSS = `TSS'
	return scalar RSS = `RSS'
	return scalar r2 = 1 - `RSS'/`TSS'
	
end

**************************************************
*** Mortality profiles at national percentiles ***
**************************************************

*** Gompertz parameters

* Load national Gompertz parameters
project, original("${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta")
use gnd pctile gomp_* using "${derived}/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta", clear

* Reshape wide on gender
rename gomp_* gomp_*_
isid pctile gnd
reshape wide gomp_int_ gomp_slope_, i(pctile) j(gnd) string

* Check that we have Gompertz parameters for each percentile
assert _N==100
sort pctile
isid pctile
assert pctile[1]==1 & pctile[100]==100

* Output
foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)
	
	* Save Gompertz parameters to matrix
	mkmat gomp_int_`g' gomp_slope_`g', matrix(gomp_`g')
	
	* Export data used in subsequent scatterplot lines
	export delim pctile gomp_int_`g' gomp_slope_`g' if inlist(pctile,5,95) ///
		using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 Gompertz parameters - `gender'.csv", ///
		replace
	project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 Gompertz parameters - `gender'.csv") preserve
	
}

*** Mortality rates

* Load national mortality rates
project, original("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use if age_at_d>=40 using "${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear

* Pool all years
isid gnd pctile age_at_d yod
collapse (mean) mortrate (rawsum) count [w=count], by(gnd pctile age_at_d)

* Plot log mortality rates for p5 and p95
gen l_mortrate=log(mortrate)

foreach gender in "Male" "Female" {

	local g=substr("`gender'",1,1)

	twoway (scatter l_mortrate age_at_d if inrange(age_at_d,40,76) & gnd=="`g'" & pctile==5) ///
		   (scatter l_mortrate age_at_d if inrange(age_at_d,40,76) & gnd=="`g'" & pctile==95, ms(T)) ///
		   (function y=gomp_`g'[5,1] + gomp_`g'[5,2] * x, range(40 90)) ///
		   (function y=gomp_`g'[95,1] + gomp_`g'[95,2] * x, range(40 90)), ///
			graphregion(fcolor(white)) xlabel(40(10)90) ///
			ytitle("Log Mortality Rate") xtitle("Age in Years") title("") ///
			yscale(range(-8.1 -2)) ///
			legend( ///
				ring(0) pos(4) c(1) bmargin(medium) ///
				order(1 2) lab(1 "5th Income Percentile") lab(2 "95th Income Percentile") ///
			)
	graph export "${root}/scratch/National p5 and p95 mortality and survival profiles/National p5 and p95 mortality profiles - `gender'.${img}", replace
	project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/National p5 and p95 mortality profiles - `gender'.${img}") preserve
	
	* Export data underlying scatterpoints
	export delim gnd pctile age_at_d l_mortrate if inrange(age_at_d,40,76) & gnd=="`g'" & inlist(pctile,5,95) ///
		using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 mortality profiles - `gender'.csv", ///
		replace
	project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 mortality profiles - `gender'.csv") preserve
}


* Numbers for paper: R^2 
isid gnd pctile age_at_d
assert inrange(age_at_d,40,76)

foreach g in "M" "F" {
	foreach p in 5 95 {
	
		manual_r2 l_mortrate age_at_d if gnd=="`g'" & pctile==`p', int(`=gomp_`g'[`p',1]') slope(`=gomp_`g'[`p',2]')
		
		scalarout using "${root}/scratch/National p5 and p95 mortality and survival profiles/Gompertz R squared.csv", ///
			id("R^2 of national Gompertz estimation: p`p' `g'") ///
			num(`=r(r2)') fmt(%4.3f)
	
	}
}

project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/Gompertz R squared.csv") preserve

************************************************
*** Survival profiles of national p5 and p95 ***
************************************************

* Keep only mortality rates for p5 and p95
keep if inlist(pctile,5,95)
assert inrange(age_at_d,40,76)
drop count l_mortrate
rename age_at_d age

* Reshape mortality rates wide on income percentile and gender
isid gnd age pctile
rename mortrate mort_p
reshape wide mort_p, i(gnd age) j(pctile)
rename mort* mort*_
reshape wide mort_p5_ mort_p95_, i(age) j(gnd) string

* Check that all ages 40-76 are present
assert _N==37
assert age[1]==40 & age[37]==76

* Extend to age 120
set obs 81
replace age = _n + 39 if mi(age)

* Reshape long on gender
reshape long
rename mort_p*_ mort_p*

* Merge in CDC mortality rates
project, original("${root}/data/derived/Mortality Rates/CDC-SSA Life Table/national_CDC_SSA_mortratesBY_gnd_age.dta") preserve
merge m:1 gnd age using "${root}/data/derived/Mortality Rates/CDC-SSA Life Table/national_CDC_SSA_mortratesBY_gnd_age.dta", ///
	keepusing(cdc_mort) ///
	assert(1 2 3) keep(1 3)  // ages<40 are _merge==2, age 120 is _merge==1
assert age==120 if _merge==1
drop _merge

* Generate mortality rates from Gompertz parameters (until 90) and CDC (90+)
foreach p in 5 95 {
	gen mort_fit_p`p' = .

	foreach g in "M" "F" {
		replace mort_fit_p`p' = exp(gomp_`g'[`p',1] + gomp_`g'[`p',2] * age) if age<90 & gnd=="`g'"  // 89 is mortality from [89,90)
	}
	replace mort_fit_p`p' = cdc_mort if age>=90
	assert inrange(mort_fit_p`p',0,1) if age!=120
}

* Generate survival curves for each mortality profile
isid gnd age
sort gnd age
foreach mort of varlist mort_* {
	local surv=subinstr("`mort'","mort_","surv_",1)
	gen `surv' = 1 if age==40
	bys gnd: replace `surv' = `surv'[_n-1] * (1-`mort'[_n-1]) if age>40  // mortality rates are mortality between [x,x+1)
	replace `surv' = `surv' * 100  // convert into percent
}

* Plot survival curves
foreach gender in "Male" "Female" {

	local g = substr("`gender'",1,1)

	twoway  (scatter surv_p5 age) ///
			(scatter surv_p95 age, ms(T)) ///
			(line surv_fit_p5 age if age<=90) ///
			(line surv_fit_p95 age if age<=90) ///
			(line surv_fit_p5 age if age>=90, lp(-) lc(forest_green)) ///
			(line surv_fit_p95 age if age>=90, lp(-) lc(dkorange)) ///
			if gnd=="`g'", ///
			xline(63 77 90, lc(7 143 218) lp(shortdash)) ///
			ylabel(0(20)100) xlabel(40(20)120) ///
			xtitle("Age in Years (a)") ytitle("Survival Rate (%)") title("") ///
			legend( ///
				ring(0) pos(3) c(1) order(1 2) bmargin(none) size(*.9) ///
				label(1 "5th Income Percentile") label(2 "95th Income Percentile") ///
			) ///
			text(19 51 "Income measured" "at age a-2 for" "ages 40 to 62" 19 70.3 "Income" "measured" "at age 61 for" "ages 63 to 76" ///
				19 84 "Gompertz" "extrapolation" "for ages" "77 to 90" 19 110 "NCHS and SSA" "uniform mortality rates" "for ages > 90" ///
				, color(7 143 218) size(small) justification(left) place(6)) ///
			graphregion(fcolor(white))
	graph export "${root}/scratch/National p5 and p95 mortality and survival profiles/National p5 and p95 survival profiles - `gender'.${img}", replace
	project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/National p5 and p95 survival profiles - `gender'.${img}") preserve
	
	* Export data underlying survival plot
	export delim gnd age surv_* if gnd=="`g'" ///
		using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 survival profiles - `gender'.csv", ///
		replace
	project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 survival profiles - `gender'.csv") preserve
}


*** Gompertz aggregation approximation simulation
keep if gnd=="M" & age<90
isid age
keep age gnd *_fit_*

* Actual aggregate mortality rate is fraction who die among those alive at each age
gen mort_fit_agg = (surv_fit_p5 * mort_fit_p5 + surv_fit_p95 * mort_fit_p95) / (surv_fit_p5 + surv_fit_p95)

* Gompertz approximation to aggregate mortality rate
gen log_mort_fit_agg = log(mort_fit_agg)
reg log_mort_fit_agg age

predict log_mort_pred_agg, xb
gen mort_pred_agg = exp(log_mort_pred_agg)

* Generate and output relative error
gen relerr = abs(mort_pred_agg - mort_fit_agg) / mort_fit_agg
sum relerr

scalarout using "${root}/scratch/National p5 and p95 mortality and survival profiles/Gompertz aggregation approx error sim.csv", replace ///
	id("Relative error (%) of p5 p95 men Gompertz aggregation sim") ///
	num(`=r(mean)*100') fmt(%9.1f)

* Output correlation between prediction and truth
corr mort_pred_agg mort_fit_agg

scalarout using "${root}/scratch/National p5 and p95 mortality and survival profiles/Gompertz aggregation approx error sim.csv", ///
	id("Correlation of p5 p95 men Gompertz aggregation sim") ///
	num(`=r(rho)') fmt(%9.4f)

project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/Gompertz aggregation approx error sim.csv")

********************************
*** NCHS mortality profiles  ***
********************************

* Load NCHS mortality data in 2001
project, original("${root}/data/raw/CDC Life Tables/CDC_LifeTables.dta")
use "${root}/data/raw/CDC Life Tables/CDC_LifeTables.dta", clear
keep if year==2001
keep if age>=40
isid gnd age

* Plot log mortality rates
gen l_mortrate=log(mortrate)

twoway  (scatter l_mortrate age if gnd=="M", m(triangle)) ///
		(scatter l_mortrate age if gnd=="F", m(circle)) ///
		(lfit l_mortrate age if gnd=="M", lcolor(black)) ///
		(lfit l_mortrate age if gnd=="F", lcolor(black)), ///
		xtitle("Age in Years") ytitle("Log Mortality Rate") ///
		xlab(40(10)100) ///
		legend( ///
			ring(0) pos(4) order(1 2) c(1) bmargin(medium) ///
			label(1 "Men") label(2 "Women") ///
		)
graph export "${root}/scratch/NCHS mortality profiles/NCHS mortality rates in 2001.${img}", replace
project, creates("${root}/scratch/NCHS mortality profiles/NCHS mortality rates in 2001.${img}") preserve

* Export data underlying plot
export delim using "${root}/scratch/NCHS mortality profiles/NCHS mortality rates in 2001.csv", replace
project, creates("${root}/scratch/NCHS mortality profiles/NCHS mortality rates in 2001.csv") preserve

* Output R^2 of fit lines
reg l_mortrate age if gnd=="M"
scalarout using "${root}/scratch/NCHS mortality profiles/R-squared of fit lines to NCHS mortality rates in 2001.csv", replace ///
	id("R-squared of fit line to 2001 NCHS mortality rates: men") ///
	num(`=e(r2)') fmt(%9.3f)

reg l_mortrate age if gnd=="F"
scalarout using "${root}/scratch/NCHS mortality profiles/R-squared of fit lines to NCHS mortality rates in 2001.csv", ///
	id("R-squared of fit line to 2001 NCHS mortality rates: women") ///
	num(`=e(r2)') fmt(%9.3f)

project, creates("${root}/scratch/NCHS mortality profiles/R-squared of fit lines to NCHS mortality rates in 2001.csv")


**********************************************
*** National p95 mortality profile by year ***
**********************************************

*** Mortality rates

* Load national mortality rates
project, original("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use if age_at_d>=40 using "${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear

* Generate survival curves
isid gnd pctile age_at_d yod
bys gnd pctile yod (age_at_d): gen surv=1 if _n==1
bys gnd pctile yod (age_at_d): replace surv = surv[_n-1] * (1-mortrate[_n-1]) if _n>1  // mortality rates are mortality between [x,x+1)
replace surv = surv * 100  // convert into percent

* Plot survival curves by year for p5, p50, p95
foreach p in 5 50 95 {
	foreach gender in "Male" "Female" {
	
		local g=substr("`gender'",1,1)
	
		tw  (line surv age_at_d if yod==2001) ///
			(line surv age_at_d if yod==2005) ///
			(line surv age_at_d if yod==2010) ///
			(line surv age_at_d if yod==2014) ///
			if gnd=="`g'" & pctile==`p', ///
			xtitle("Age") ytitle("Survival Rate, %") ///
			title("Survival Curves by Year for `gender's at p`p'", size(medium)) ///
			legend( ///
				lab(1 "2001") lab(2 "2005") lab(3 "2010") lab(4 "2014") ///
				rows(1) ///
			)
		graph export "${root}/scratch/National p5 and p95 mortality and survival profiles/National by year p`p' mortality profiles - `gender'.${img}", replace
		project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/National by year p`p' mortality profiles - `gender'.${img}") preserve
	
		* Export data underlying scatterpoints
		export delim gnd pctile age_at_d yod surv if gnd=="`g'" & pctile==`p' ///
			using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National by year p`p' mortality profiles - `gender'.csv", ///
			replace
		project, creates("${root}/scratch/National p5 and p95 mortality and survival profiles/data/National by year p`p' mortality profiles - `gender'.csv") preserve
		
	}
}
