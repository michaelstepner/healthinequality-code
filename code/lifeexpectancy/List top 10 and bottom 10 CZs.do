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
cap mkdir "${root}/scratch/Top 10 and Bottom 10 locations"

/*** Identify the Top 10 and Bottom 10 locations among the largest 100, for:
		- CZs and Counties
		- LE levels and LE trends
		- for Q1 and Q4
***/

****************
*** Programs ***
****************

project, original("${root}/code/ado/compute_ci_percentiles.ado")


cap program drop produce_t10b10_table
program define produce_t10b10_table

	syntax , geo(name) q(integer) type(string)
	
	if !inlist("`geo'","cty","cz") {
		di as error "geo() must by cty or cz"
		exit 198
	}
	
	if ("`type'"=="levels") {
		local folder 	le_estimates
		local letype 	le
		local loadvar 	le_raceadj
		local var 		le_raceadj
		local fmt		%9.1f
	}
	else if ("`type'"=="trends") {
		local folder	le_trends
		local letype	letrends
		local loadvar	le_raceadj_b_year
		local var		le_raceadj_tr
		local fmt		%9.2f
	}
	else {
		di as error "type() must by levels or trends"
		exit 198
	}
	
	*** Identify Top 10 / Bottom 10
	
	* Load life expectancies: `geo' by Gender x Income Quartile
	project, original("$derived/`folder'/`geo'_`letype'BY_gnd_hhincquartile.dta")
	use `geo' gnd hh_inc_q `loadvar' using "$derived/`folder'/`geo'_`letype'BY_gnd_hhincquartile.dta", clear
	if ("`loadvar'"!="`var'") rename `loadvar' `var'
	
	rename `var' `var'_q
	reshape wide `var'_q, i(`geo' gnd) j(hh_inc_q)
	
	* Identify Top 10/Bottom 10
	identify_t10b10 `var'_q`q', geo(`geo')

	*** Calculate point estimates
	
	* Merge in point estimates
	keep `geo' loc_name `var'_q`q'_rank
	project, original("$derived/`folder'/`geo'_`letype'BY_gnd_hhincquartile.dta") preserve
	merge 1:m `geo' using "$derived/`folder'/`geo'_`letype'BY_gnd_hhincquartile.dta", ///
		assert(2 3) keep(3) nogen ///
		keepusing(`geo' gnd hh_inc_q `loadvar')
	if ("`loadvar'"!="`var'") rename `loadvar' `var'
	
	* Reshape and generate desired vars	
	prep_for_t10b10 `var', geo(`geo')
	
	* Store
	tempfile point_ests
	save `point_ests'
	
	*** Calculate bootstrap estimates
	
	* Fetch bootstrap estimates for T10/B10
	keep `geo'
	project, original("$derived/`folder'/bootstrap/bootstrap_`geo'_`letype'BY_gnd_hhincquartile.dta") preserve
	merge 1:m `geo' using "$derived/`folder'/bootstrap/bootstrap_`geo'_`letype'BY_gnd_hhincquartile.dta", ///
		assert(2 3) keep(3) nogen ///
		keepusing(`geo' gnd hh_inc_q sample_num `loadvar')
	if ("`loadvar'"!="`var'") rename `loadvar' `var'
	
	* Reshape and generate desired vars	
	prep_for_t10b10 `var', geo(`geo') sample_num
	
	*** Output Top 10 / Bottom 10 table with CIs
	
	* Merge in point estimates
	merge 1:1 `geo' using `point_ests', assert(3) nogen
	order `geo' loc_name `var'_q`q'_rank
	
	* Output table
	output_t10b10 `var', geo(`geo') q(`q') label(LE `type') fmt(`fmt')

end


cap program drop identify_t10b10
program define identify_t10b10

	/*** Given a dataset that is identified CZ/County x Gender,
		 identify the Top 10 and Bottom 10 areas among the largest 100
		 for a specified variable.
	***/
	
	syntax varname, geo(name)
	local var `varlist'
		
	* Check loaded dataset has required structure
	isid `geo' gnd
	keep `geo' gnd `var'
	
	* Reshape wide on gender
	rename `var' `var'_
	reshape wide `var'_, i(`geo') j(gnd) string

	* Take unweighted average of men and women
	gen `var' = (`var'_F + `var'_M) / 2
	drop `var'_F `var'_M
	
	* Merge in populations and place names
	if ("`geo'"=="cz") {
		project, original("${derived}/final_covariates/cz_full_covariates.dta") preserve
		merge 1:1 cz using "${derived}/final_covariates/cz_full_covariates.dta", ///
			assert(2 3) keep(3) nogen ///
			keepusing(pop2000 czname stateabbrv)
			
		gen loc_name = czname + ", " + stateabbrv
		drop czname stateabbrv
	}
	else {  // cty
		project, original("${derived}/final_covariates/cty_full_covariates.dta") preserve
		merge 1:1 cty using "${derived}/final_covariates/cty_full_covariates.dta", ///
			nogen assert(2 3) keep(3) ///
			keepusing(cty_pop2000 county_name stateabbrv)
		rename cty_pop2000 pop2000
		
		gen loc_name = county_name + ", " + stateabbrv
		replace loc_name = "Washington, DC" if stateabbrv == "DC"
		drop county_name stateabbrv
	}
	
	* Keep 100 largest places
	gsort -pop2000
	assert pop2000[100]!=pop2000[101]  // no tie for 100th place
	keep if _n<=100

	* Keep top 10 and bottom 10
	gsort -`var'
	gen `var'_rank = _n
	drop in 11/90

end

cap program drop prep_for_t10b10
program define prep_for_t10b10

	/*** Given a dataset that is identified:
			- CZ/County x Gender x Income Quartile (x Bootstrap Sample #)
			
		 Return the dataset:
			- Reshaped wide on Gender x Income Quartile
			- With a variable for Q4-Q1 difference in specified variable's
				unweighted average over men and women
			- (In 2.5th and 97.5th percentiles if the original dataset had 
				bootstrap samples.)
	***/

	syntax varname, geo(name) [sample_num]
	local var `varlist'
	
	* Check dataset has expected structure
	isid `geo' gnd hh_inc_q `sample_num'
	
	* Reshape wide on Income Quartile and Gender
	rename `var' `var'_q
	reshape wide `var'_q, i(`geo' gnd `sample_num') j(hh_inc_q)
	rename (`var'_q1 `var'_q2 `var'_q3  `var'_q4) (`var'_q1_ `var'_q2_ `var'_q3_ `var'_q4_)
	reshape wide `var'_q1_ `var'_q2_ `var'_q3_ `var'_q4_, i(`geo' `sample_num') j(gnd) string
	
	* Take unweighted average of men and women
	forvalues q=1/4 {
		gen `var'_q`q' = (`var'_q`q'_F + `var'_q`q'_M) / 2
	}
	
	* Generate Q4-Q1 difference
	gen `var'_diffq4q1 = `var'_q4 - `var'_q1
	
	* Compute bootstrap 2.5th and 97.5th percentiles
	if ("`sample_num'"=="sample_num") {
		compute_ci_percentiles `var'_*, by(`geo') gen(p)
		rename `var'_* `var'_*_p
		replace p=p*10
		ds `var'*
		reshape wide `r(varlist)', i(`geo') j(p)
		rename (*_p25 *_p975) (p25_* p975_*)
	}
		
end

cap program drop output_t10b10
program define output_t10b10
	
	syntax name(name=var), geo(name) q(integer) label(string) fmt(string)
	
	* Check dataset has expected structure
	isid `geo'

	* Generate bootstrap CIs
	ds `geo' loc_name *_rank p25* p975*, not
	local pointvars=r(varlist)
	foreach v of local pointvars {
		gen `v'_ciL = 2*`v' - p975_`v'
		gen `v'_ciH = 2*`v' - p25_`v'
		drop p975_`v' p25_`v'
	}
	
	* Output table
	foreach v in `var'_q`q' `var'_diffq4q1 `var'_q`q'_M `var'_q`q'_F {
		gen `v'_s = string(`v', "`fmt'") + " (" + string(`v'_ciL, "`fmt'") + ", " ///
						+ string(`v'_ciH, "`fmt'") + ")"
	}
	
	sort `var'_q`q'_rank
	
	export delim `geo' `var'_q`q'_rank loc_name `var'_q`q'_s `var'_q`q'_M_s `var'_q`q'_F_s `var'_diffq4q1_s ///
		using "${root}/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 `geo' - Q`q' `label'.csv", replace
	project, creates("${root}/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 `geo' - Q`q' `label'.csv") preserve
		
end


***********************
*** Generate Tables ***
***********************

*** Levels

produce_t10b10_table, geo(cz) q(4) type(levels)
produce_t10b10_table, geo(cty) q(1) type(levels)
produce_t10b10_table, geo(cty) q(4) type(levels)

produce_t10b10_table, geo(cz) q(1) type(levels)

* Paper numbers
sort le_raceadj_q1_rank
assert _N==20
scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	replace ///
	id("Difference in Q1 LE level between top and bottom CZ in 100 largest") ///
	num(`=le_raceadj_q1[1]-le_raceadj_q1[20]') fmt(%9.2f)

*** Trends

produce_t10b10_table, geo(cz) q(4) type(trends)

produce_t10b10_table, geo(cz) q(1) type(trends)

* Paper numbers
gen tot_change_q1 = le_raceadj_tr_q1 * (2014-2001)

sort le_raceadj_tr_q1_rank
assert _N==20

scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	id("Change in Q1 LE level from 2001-2014 in *top* CZ among 100 largest") ///
	num(`=tot_change_q1[1]') fmt(%9.2f)
	
scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	id("Change in Q1 LE level from 2001-2014 in *bottom* CZ among 100 largest") ///
	num(`=tot_change_q1[20]') fmt(%9.2f)

sum tot_change_q1 if loc_name=="Cincinnati, OH"
assert r(N)==1
scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	id("Change in Q1 LE level from 2001-2014 in Cincinnati, OH") ///
	num(`=r(mean)') fmt(%9.2f)
	
sum tot_change_q1 if loc_name=="Birmingham, AL"
assert r(N)==1
scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	id("Change in Q1 LE level from 2001-2014 in Birmingham, AL") ///
	num(`=r(mean)') fmt(%9.2f)
	
sum tot_change_q1 if loc_name=="Tampa, FL"
assert r(N)==1
scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	id("Change in Q1 LE level from 2001-2014 in Tampa, FL") ///
	num(`=r(mean)') fmt(%9.2f)

	
gen tot_change_diffq4q1 = le_raceadj_tr_diffq4q1 * (2014-2001)
levelsof loc_name in 20
scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	id("Change in Q4-Q1 gap in LE level from 2001-2014 in *bottom* CZ among 100 largest (`: di `r(levels)'')") ///
	num(`=tot_change_diffq4q1[20]') fmt(%9.2f)


*** Reported number: CZs with high Q1 LE have low gap between Q4-Q1

* Load data
project, original("$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta")
use cz gnd  hh_inc_q le_raceadj using "$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta", clear

* Reshape wide on quartile
rename le_raceadj le_raceadj_q
reshape wide le_raceadj_q, i(cz gnd) j(hh_inc_q)

* Take unweighted average of men and women
collapse (mean) le_raceadj_q*, by(cz)

* Calculate Q4-Q1 gap
gen le_raceadj_diffq4q1 = le_raceadj_q4 - le_raceadj_q1

* Merge in CZ populations
project, original("${root}/data/derived/final_covariates/cz_pop.dta") preserve
merge 1:1 cz using "${root}/data/derived/final_covariates/cz_pop.dta", ///
	assert(2 3) keep(3) nogen

* Calculate correlation between Q1 LE level and Q4-Q1 LE gap
corr_reg le_raceadj_diffq4q1 le_raceadj_q1 [w=pop2000]

scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	id("Correlation between Q1 LE level and Q4-Q1 LE gap") ///
	num(`=_b[vb]') fmt(%9.2f)
	
test vb=0
scalarout using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", ///
	id("Correlation between Q1 LE level and Q4-Q1 LE gap: p-value = ") ///
	num(`=r(p)') fmt(%9.4f)


*** Project creates: reported numbers
project, creates("${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv")


*********************
*** National rows ***
*********************

*** Programs

cap program drop nat_levels_by_quartile
program define nat_levels_by_quartile

	syntax using/, saving(string)
	
	* Load data
	project, original(`"`using'"')
	use `"`using'"', clear
	
	* Check if bootstrapped sample
	cap confirm variable sample_num
	if (_rc==0) local sample_num sample_num
	else if (_rc!=111) confirm variable sample_num
	
	* Collapse to quartiles
	gen hh_inc_q=ceil(pctile/25)
	isid gnd pctile `sample_num'
	collapse (mean) le_raceadj, by(gnd hh_inc_q `sample_num')
	
	* Save data
	save13 `"`saving'"', replace
	project, creates(`"`saving'"')
	
end

cap program drop nat_trends_by_quartile
program define nat_trends_by_quartile

	syntax using/, saving(string)
	
	* Load data
	project, original(`"`using'"')
	use `"`using'"', clear
	
	* Check if bootstrapped sample
	cap confirm variable sample_num
	if (_rc==0) local sample_num sample_num
	else if (_rc!=111) confirm variable sample_num
	
	* Collapse to quartiles
	gen hh_inc_q=ceil(pctile/25)
	isid gnd pctile year `sample_num'
	collapse (mean) le_raceadj, by(gnd hh_inc_q year `sample_num')
	
	* Estimate trends
	statsby _b _se, by(gnd hh_inc_q `sample_num') clear : reg le_raceadj year
	rename _b* le_raceadj_b*
	rename _se* le_raceadj_se*
	
	* Save data
	save13 `"`saving'"', replace
	project, creates(`"`saving'"')
	
end


cap program drop produce_t10b10_nat_row
program define produce_t10b10_nat_row

	syntax , q(integer) type(string)
	local geo national

	if ("`type'"=="levels") {
		local folder	"${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_estimates"
		local letype 	le
		local loadvar 	le_raceadj
		local var 		le_raceadj
		local fmt		%9.1f
	}
	else if ("`type'"=="trends") {
		local folder	"${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_trends"
		local letype	letrends
		local loadvar	le_raceadj_b_year
		local var		le_raceadj_tr
		local fmt		%9.2f
	}
	else {
		di as error "type() must by levels or trends"
		exit 198
	}

	
	*** Calculate point estimates
	
	* Load
	project, uses("`folder'/`geo'_`letype'BY_gnd_hhincquartile.dta")
	use gnd hh_inc_q `loadvar' using "`folder'/`geo'_`letype'BY_gnd_hhincquartile.dta", clear
	if ("`loadvar'"!="`var'") rename `loadvar' `var'
	gen byte national=1
	
	* Reshape and generate desired vars
	prep_for_t10b10 `var', geo(national)

	* Store
	tempfile point_ests
	save `point_ests'

	*** Calculate bootstrap estimates

	* Load
	project, uses("`folder'/bootstrap/bootstrap_`geo'_`letype'BY_gnd_hhincquartile.dta")
	use gnd hh_inc_q sample_num `loadvar' using "`folder'/bootstrap/bootstrap_`geo'_`letype'BY_gnd_hhincquartile.dta", clear
	if ("`loadvar'"!="`var'") rename `loadvar' `var'
	gen byte national=1
	
	* Reshape and generate desired vars	
	prep_for_t10b10 `var', geo(national) sample_num

	*** Output Top 10 / Bottom 10 table with CIs
	
	* Merge in point estimates
	merge 1:1 national using `point_ests', assert(3) nogen

	* Generate missing T10B10 vars, since this is national
	gen `var'_q`q'_rank=1
	gen loc_name = "US Mean"
	order `geo' loc_name `var'_q`q'_rank
	
	* Output table
	output_t10b10 `var', geo(`geo') q(`q') label(LE `type') fmt(`fmt')
	
end


*** Create folders
cap mkdir "${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data"
cap mkdir "${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_estimates"
cap mkdir "${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_estimates/bootstrap"
cap mkdir "${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_trends"
cap mkdir "${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_trends/bootstrap"


*** Create national LE quartile datasets

** National levels by Gender x Quartile: point estimates
nat_levels_by_quartile ///
	using "${derived}/le_estimates/national_leBY_gnd_hhincpctile.dta", ///
	saving("${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_estimates/national_leBY_gnd_hhincquartile.dta")

** National levels by Gender x Quartile: bootstrap samples
nat_levels_by_quartile ///
	using "${derived}/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincpctile.dta", ///
	saving("${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_estimates/bootstrap/bootstrap_national_leBY_gnd_hhincquartile.dta")

** National trends by Gender x Quartile: point estimates and OLS SEs
nat_trends_by_quartile ///
	using "${derived}/le_estimates/national_leBY_year_gnd_hhincpctile.dta", ///
	saving("${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_trends/national_letrendsBY_gnd_hhincquartile.dta")


*** Create national rows for T10/B10 tables

** Levels
produce_t10b10_nat_row, q(1) type(levels)
produce_t10b10_nat_row, q(4) type(levels)

** Trends (OLS CIs)

* Load data
project, uses("${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_trends/national_letrendsBY_gnd_hhincquartile.dta")
use "${root}/scratch/Top 10 and Bottom 10 locations/national quartile LE data/le_trends/national_letrendsBY_gnd_hhincquartile.dta", clear
drop *_cons
rename le_raceadj_b_year le_raceadj_tr
rename le_raceadj_se_year SE_le_raceadj_tr

* Reshape wide on Income Quartile and Gender
gen byte national=1

rename *le_raceadj_tr *le_raceadj_tr_q
reshape wide le_raceadj_tr_q SE_le_raceadj_tr_q, i(national gnd) j(hh_inc_q)

rename *le_raceadj_tr_q* *le_raceadj_tr_q*_
ds *le_raceadj_tr_q*_
reshape wide `r(varlist)', i(national) j(gnd) string

* Take unweighted average of men and women
forvalues q=1/4 {
	gen le_raceadj_tr_q`q' = (le_raceadj_tr_q`q'_F + le_raceadj_tr_q`q'_M) / 2
	gen SE_le_raceadj_tr_q`q' = sqrt( (SE_le_raceadj_tr_q`q'_F^2 + SE_le_raceadj_tr_q`q'_M^2) / 4 )
}

* Generate Q4-Q1 difference
gen le_raceadj_tr_diffq4q1 = le_raceadj_tr_q4 - le_raceadj_tr_q1
gen SE_le_raceadj_tr_diffq4q1 = sqrt(SE_le_raceadj_tr_q4^2 + SE_le_raceadj_tr_q1^2)

* Compute upper & lower 95% confidence intervals
foreach var of varlist le_raceadj_tr* {
	gen ciH_`var' = `var' + 1.96*SE_`var'
	gen ciL_`var' = `var' - 1.96*SE_`var'
}

* Generate missing T10B10 vars, since this is national
gen le_raceadj_tr_q1_rank=1
gen le_raceadj_tr_q4_rank=1
gen loc_name = "US Mean"
order national loc_name le_raceadj_tr_q*_rank

* Output row
local fmt %9.2f
local var le_raceadj_tr
local geo national
local label LE trends

foreach q in 1 4 {
	* Output table
	foreach v in `var'_q`q' `var'_diffq4q1 `var'_q`q'_M `var'_q`q'_F {
		gen `v'_s = string(`v', "`fmt'") + " (" + string(ciL_`v', "`fmt'") + ", " ///
						+ string(ciH_`v', "`fmt'") + ")"
	}
	
	sort `var'_q`q'_rank
	
	export delim `geo' `var'_q`q'_rank loc_name `var'_q`q'_s `var'_q`q'_M_s `var'_q`q'_F_s `var'_diffq4q1_s ///
		using "${root}/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 `geo' - Q`q' `label'.csv", replace
	project, creates("${root}/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 `geo' - Q`q' `label'.csv") preserve
	
	drop `var'_q`q'_s `var'_diffq4q1_s `var'_q`q'_M_s `var'_q`q'_F_s

}
