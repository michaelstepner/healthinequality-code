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
cap mkdir "${root}/scratch/National LE profiles"
cap mkdir "${root}/scratch/National LE profiles/data"

* Erase output numbers
cap erase "${root}/scratch/National LE profiles/National LE concavity numbers p10 p15 p90 p95 p100.csv"

/*** Profile of national life expectancies by income percentile,
	 separately by gender.
***/


**********************
*** Generate plots ***
**********************

* Generate income mean labels for reported percentiles, by gender
project, uses("${root}/scratch/National income means by quantile/National income means by percentile.dta") preserve
use "${root}/scratch/National income means by quantile/National income means by percentile.dta", clear
sort gnd pctile

foreach g in "M" "F" {
	preserve
	keep if gnd=="`g'"
	forval p = 20(20)80 {
		local text_`p'_`g' "$`: di %2.0f hh_inc[`p']/1000'k"
		di "`text_`p'_`g''"
	}
	
	local text_100_`g' "$`: di %2.1f hh_inc[100]/1000000'M"
	di "`text_100_`g''"
	
	restore
}


* Load national LEs
project, original("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta")
use gnd pctile le_raceadj ciL_le_raceadj ciH_le_raceadj ///
	using "$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta", clear

* Create text for top and bottom percentiles
local text ""

foreach g in "F" "M" {

	local text_point `"`text_point' " ""'
	local text_ci `"`text_ci' " ""'

	local gender=cond("`g'"=="M","Men","Women")

	foreach p in 1 100 {
	
		local percentile=cond(`p'==1,"Bottom 1%","Top 1%")
	
		sum le_raceadj if gnd=="`g'" & pctile==`p', meanonly
		assert r(N)==1
		local point : di %4.1f r(mean)
		
		sum ciL_le_raceadj if gnd=="`g'" & pctile==`p', meanonly
		assert r(N)==1
		local ciL : di %4.1f r(mean)
		
		sum ciH_le_raceadj if gnd=="`g'" & pctile==`p', meanonly
		assert r(N)==1
		local ciH : di %4.1f r(mean)

		local text_point `"`text_point' "`gender', `percentile': `point'""'
		local text_ci `"`text_ci' "`gender', `percentile': `point' (`ciL', `ciH')""'
	}
}

* Point estimates
twoway  (scatter le_raceadj pctile if gnd=="M", ms(t)) ///
		(scatter le_raceadj pctile if gnd=="F", ms(o)), ///
		graphregion(fcolor(white)) ///
		ylabel(70(5)90) ///
		title("") xtitle("Household Income Percentile") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
		legend(off) ///
		text(89.3 93 "Women", color(maroon) place(west)) ///
		text(83 93 "Men", color(navy) place(west)) ///
		text(72.6 101 `text_point', size(*.9) justification(right) placement(west))
graph export "${root}/scratch/National LE profiles/National LE by Income Percentile and Gender - point estimates.${img}", replace
project, creates("${root}/scratch/National LE profiles/National LE by Income Percentile and Gender - point estimates.${img}") preserve
		
* Confidence intervals
twoway	(rspike ciH_le_raceadj ciL_le_raceadj pctile if gnd=="M", lwidth(medthick)) ///
		(rspike ciH_le_raceadj ciL_le_raceadj pctile if gnd=="F", lwidth(medthick)), ///
		graphregion(fcolor(white)) ///
		ylabel(70(5)90) ///
		title("") xtitle("Household Income Percentile") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
		legend(off) ///
		xlabel(0 `" "0" "Women" "Men" "' ///
			20 `" "20" "`text_20_F'" "`text_20_M'" "' ///
			40 `" "40" "`text_40_F'" "`text_40_M'" "' ///
			60 `" "60" "`text_60_F'" "`text_60_M'" "' ///
			80 `" "80" "`text_80_F'" "`text_80_M'" "' ///
			100 `" "100" "`text_100_F'" "`text_100_M'" "', labs(small)) ///
		text(89.3 93 "Women", color(maroon) place(west)) ///
		text(83 93 "Men", color(navy) place(west)) ///
		text(72.6 101 `text_ci', size(*.9) justification(right) placement(west))
graph export "${root}/scratch/National LE profiles/National LE by Income Percentile and Gender - confidence intervals.${img}", replace
project, creates("${root}/scratch/National LE profiles/National LE by Income Percentile and Gender - confidence intervals.${img}") preserve

* Export data underlying figures
export delim using "${root}/scratch/National LE profiles/data/National LE by Income Percentile and Gender.csv", ///
	replace
project, creates("${root}/scratch/National LE profiles/data/National LE by Income Percentile and Gender.csv") preserve


*************************************
*** Plot LE vs. Income in Dollars ***
*************************************

* Save income means by percentile, pooling across genders
project, uses("${root}/scratch/National income means by quantile/National income means by percentile.dta") preserve
use "${root}/scratch/National income means by quantile/National income means by percentile.dta", clear

isid gnd pctile
collapse (mean) hh_inc, by(pctile)

sort pctile
assert _N==100
foreach p in 10 15 90 95 100 {
	scalarout using "${root}/scratch/National LE profiles/National LE concavity numbers p10 p15 p90 p95 p100.csv", ///
		id("Income at p`p', averaging men and women") ///
		num(`=hh_inc[`p']') fmt(%14.0fc)
}

* Load national LEs
project, original("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta")
use gnd pctile le_raceadj ciL_le_raceadj ciH_le_raceadj ///
	using "$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta", clear
	
* Merge in income means by percentile
project, uses("${root}/scratch/National income means by quantile/National income means by percentile.dta") preserve
merge 1:1 gnd pctile using ///
	"${root}/scratch/National income means by quantile/National income means by percentile.dta", ///
	assert(3) nogen

* Point estimates
twoway  (scatter le_raceadj hh_inc if gnd=="M" & pctile<100, ms(t)) ///
		(scatter le_raceadj hh_inc if gnd=="F" & pctile<100, ms(o)), ///
		graphregion(fcolor(white)) ///
		ylabel(70(5)90) ///
		xlabel(0 "0" 100000 "100,000" 200000 "200,000" 300000 "300,000" 400000 "400,000" 500000 "500,000") ///
		title("") xtitle("Mean Household Income by Percentile ($)") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
		legend( ///
				ring(0) pos(4) c(1) bmargin(medium) ///
				order(2 1) lab(1 "Men") lab(2 "Women") ///
			)
graph export "${root}/scratch/National LE profiles/National LE by Income and Gender.${img}", replace
project, creates("${root}/scratch/National LE profiles/National LE by Income and Gender.${img}") preserve

* Confidence intervals
twoway	(rspike ciH_le_raceadj ciL_le_raceadj hh_inc if gnd=="M" & pctile<100, lwidth(medthick)) ///
		(rspike ciH_le_raceadj ciL_le_raceadj hh_inc if gnd=="F" & pctile<100, lwidth(medthick)), ///
		ylabel(70(5)90) ///
		xlabel(0 "0" 100000 "100,000" 200000 "200,000" 300000 "300,000" 400000 "400,000" 500000 "500,000") ///
		title("") xtitle("Mean Household Income by Percentile ($)") ytitle("Expected Age at Death for 40 Year Olds in Years") ///
		legend(off) ///
		text(88.6 130000 "Women", color(maroon) place(west)) ///
		text(81.8 130000 "Men", color(navy) place(west))
graph export "${root}/scratch/National LE profiles/National LE by Income and Gender - confidence intervals.${img}", replace
project, creates("${root}/scratch/National LE profiles/National LE by Income and Gender - confidence intervals.${img}") preserve


* Export data underlying figures
export delim using "${root}/scratch/National LE profiles/National LE by Income and Gender.csv", ///
	replace
project, creates("${root}/scratch/National LE profiles/National LE by Income and Gender.csv") preserve


**********************************
*** Generate numbers for paper ***
**********************************

*******
*** Difference between top 1% and bottom 1%, by gender
*******

** Programs

project, original("${root}/code/ado/compute_ci_percentiles.ado")
cap program drop prep_diff_top1bot1
program define prep_diff_top1bot1

	syntax , [sample_num]

	keep if inlist(pctile,1,100)
	
	* Reshape wide on percentile
	isid gnd pctile `sample_num'
	rename le_raceadj le_raceadj_p
	reshape wide le_raceadj_p, i(gnd `sample_num') j(pctile)
	
	* Generate difference between top 1% and bottom 1%
	gen le_raceadj_Dtop1bot1 = le_raceadj_p100 - le_raceadj_p1
	
	* Compute bootstrap 2.5th and 97.5th percentiles
	if ("`sample_num'"=="sample_num") {
		compute_ci_percentiles le_raceadj_Dtop1bot1, by(gnd) gen(p)
		rename le_raceadj* le_raceadj*_p
		replace p=p*10
		reshape wide le_raceadj_Dtop1bot1_p, i(gnd) j(p)
		rename (*_p25 *_p975) (p25_* p975_*)
	}

end

** Point estimate

* Load national LE levels
project, original("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta")
use gnd pctile le_raceadj ///
	using "$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta", clear

* Compute Top 1 - Bottom 1 difference
prep_diff_top1bot1

* Store
tempfile point_ests
save `point_ests'

** Confidence interval

* Load bootstrapped national LE levels
project, original("$derived/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile.dta")
use gnd pctile sample_num le_raceadj ///
	using "$derived/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile.dta", clear

* Compute CI of Top 1 - Bottom 1 difference
prep_diff_top1bot1, sample_num

** Output

* Merge together point estimate and CI
merge 1:1 gnd using `point_ests', assert(3) nogen

foreach v of varlist le_raceadj_Dtop1bot1 {
	gen `v'_ciL = 2*`v' - p975_`v'
	gen `v'_ciH = 2*`v' - p25_`v'
	drop p975_`v' p25_`v'
}

* Output numbers
gen le_raceadj_p1_str=""
gen le_raceadj_p100_str=""
gen le_raceadj_Dtop1bot1_str=""
forvalues i=1/`=_N' {

	local fmt %4.1f

	replace le_raceadj_p1_str = trim(string(le_raceadj_p1[`i'],"`fmt'")) in `i'
	replace le_raceadj_p100_str = trim(string(le_raceadj_p100[`i'],"`fmt'")) in `i'

	local pnt = trim(string(le_raceadj_Dtop1bot1[`i'],"`fmt'"))
	local ciL = trim(string(le_raceadj_Dtop1bot1_ciL[`i'],"`fmt'"))
	local ciH = trim(string(le_raceadj_Dtop1bot1_ciH[`i'],"`fmt'"))
	replace le_raceadj_Dtop1bot1_str = "`pnt' (`ciL', `ciH')" in `i'
	
}

export delim gnd le_raceadj_p1_str le_raceadj_p100_str le_raceadj_Dtop1bot1_str ////
	using "${root}/scratch/National LE profiles/National gap in LE between top and bottom 1 percent.csv", replace
project, creates("${root}/scratch/National LE profiles/National gap in LE between top and bottom 1 percent.csv")


*******
*** Difference between genders at top 1% and bottom 1%
*******

** Programs

project, original("${root}/code/ado/compute_ci_percentiles.ado")
cap program drop prep_diff_malefemale
program define prep_diff_malefemale

	syntax , [sample_num]

	keep if inlist(pctile,1,100)
	
	* Reshape wide on gender
	rename le_raceadj le_raceadj_
	reshape wide le_raceadj_, i(pctile `sample_num') j(gnd) string
	
	* Compute gap between women and men
	gen le_raceadj_diffFM = le_raceadj_F - le_raceadj_M
	
	* Compute bootstrap 2.5th and 97.5th percentiles
	if ("`sample_num'"=="sample_num") {
		compute_ci_percentiles le_raceadj_diffFM, by(pctile) gen(p)
		rename le_raceadj* le_raceadj*_p
		replace p=p*10
		reshape wide le_raceadj_diffFM_p, i(pctile) j(p)
		rename (*_p25 *_p975) (p25_* p975_*)
	}

end

** Point estimate

* Load national LE levels
project, original("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta")
use gnd pctile le_raceadj ///
	using "$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta", clear

* Compute gap between men and women at Top and Bottom 1%
prep_diff_malefemale

* Store
tempfile point_ests
save `point_ests'


** Confidence interval

* Load bootstrapped national LE levels
project, original("$derived/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile.dta")
use gnd pctile sample_num le_raceadj ///
	using "$derived/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile.dta", clear

* Compute gap between men and women at Top and Bottom 1%
prep_diff_malefemale, sample_num


** Output

* Merge together point estimate and CI
merge 1:1 pctile using `point_ests', assert(3) nogen

foreach v of varlist le_raceadj_diffFM {
	gen `v'_ciL = 2*`v' - p975_`v'
	gen `v'_ciH = 2*`v' - p25_`v'
	drop p975_`v' p25_`v'
}

* Output numbers
gen le_raceadj_diffFM_str=""
label var le_raceadj_diffFM_str "Difference between Female and Male LE"
forvalues i=1/`=_N' {

	local fmt %4.1f
	local pnt = trim(string(le_raceadj_diffFM[`i'],"`fmt'"))
	local ciL = trim(string(le_raceadj_diffFM_ciL[`i'],"`fmt'"))
	local ciH = trim(string(le_raceadj_diffFM_ciH[`i'],"`fmt'"))
	
	replace le_raceadj_diffFM_str = "`pnt' (`ciL', `ciH')" in `i'
	
}

export delim pctile le_raceadj_diffFM_str ////
	using "${root}/scratch/National LE profiles/Gap between Female and Male LE at top and bottom 1 percent.csv", replace
project, creates("${root}/scratch/National LE profiles/Gap between Female and Male LE at top and bottom 1 percent.csv")


*******
*** Compute p15-p10, p90-p95 and p95-p100 differences
*******

* Load data, pooling over genders
project, original("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta")
use gnd pctile le_raceadj using "$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta", clear

isid gnd pctile
collapse (mean) le_raceadj, by(pctile)


* Output differences in LE between percentiles 5 apart
sort pctile
assert _N==100

scalarout using "${root}/scratch/National LE profiles/National LE concavity numbers p10 p15 p90 p95 p100.csv", ///
	id("Life Expectancy Gap between p15 and p10") ///
	num(`=le_raceadj[15]-le_raceadj[10]') fmt(%9.1f)

scalarout using "${root}/scratch/National LE profiles/National LE concavity numbers p10 p15 p90 p95 p100.csv", ///
	id("Life Expectancy Gap between p95 and p90") ///
	num(`=le_raceadj[95]-le_raceadj[90]') fmt(%9.1f)
	
scalarout using "${root}/scratch/National LE profiles/National LE concavity numbers p10 p15 p90 p95 p100.csv", ///
	id("Life Expectancy Gap between p100 and p95") ///
	num(`=le_raceadj[100]-le_raceadj[95]') fmt(%9.1f)

project, creates("${root}/scratch/National LE profiles/National LE concavity numbers p10 p15 p90 p95 p100.csv")


*******
*** Racial LE gaps
*******

project, original("$root/data/derived/le_estimates/national_leBY_gnd_hhincpctile.dta")
use "$root/data/derived/le_estimates/national_leBY_gnd_hhincpctile.dta", clear

isid gnd pctile
collapse (mean) le*, by(gnd)
gsort - gnd

foreach r in b h a {
	gen le_gap_`r'w = le_`r' - le_w
}

export delim gnd le_gap_* ////
	using "${root}/scratch/National LE profiles/Racial gap in average LE.csv", replace
project, creates("${root}/scratch/National LE profiles/Racial gap in average LE.csv")
