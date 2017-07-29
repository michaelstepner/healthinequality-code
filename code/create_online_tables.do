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
global online "${root}/results/Online Tables"

* Create required folders
cap mkdir "${root}/results"
cap mkdir "${root}/results/Online Tables"

* Add required ado files to project
project, relies_on("${root}/code/ado_ssc/save12.ado")

****************
*** Programs ***
****************

cap program drop combine_counts_and_LE
program define combine_counts_and_LE

	syntax, by(namelist) type(string) [ withmeaninc ] ///
			counts(string) le(string)
			
	if !inlist("`type'","levelspooled","levelsbyyear","trends") {
		di as error "type() must either be levelspooled, levelsbyyear or trends"
		exit 198
	}

	if !regexm(`"`: subinstr local counts "\" "/", all'"',`"^`=subinstr(c(tmpdir),"\","/",.)'"') project, original(`"`counts'"')  // avoid tempfiles
	project, uses(`"`le'"')
	
	* Load counts
	if ("`type'"=="levelspooled") {  // neither Levels x Year nor Trends
		use `"`counts'"' if age_at_d >= 40, clear
		assert inrange(age_at_d,40,76)
	}
	else {
		use `"`counts'"' if inrange(age_at_d, 40, 63), clear
	}
	rename yod year
		
	if ("`withmeaninc'"=="") collapse (rawsum) count, by(`by')
	else collapse (rawsum) count (mean) hh_inc [w=count], by(`by')
	recast long count
	
	tempfile counts
	save `counts'
	
	* Load race-adjusted and unadjusted LE; point estimate and SD
	use `"`le'"', clear
	isid `by'
	if ("`type'"=="trends") {
		keep `by' le_agg_b_year le_raceadj_b_year sd_le_agg_b_year sd_le_raceadj_b_year
		ren *b_year *slope
	}
	else keep `by' le_agg le_raceadj sd_le_agg sd_le_raceadj
	
	* Merge together counts & LEs
	merge 1:1 `by' using "`counts'", assert(2 3) keep(3) nogen  // _merge==2 happens for masked data
	order `by' count
	sort `by'
	
end

cap program drop reshape_wide_gnd_quartile
program define reshape_wide_gnd_quartile

	syntax, targetid(namelist)
	
	* Reshape income quartile wide
	cap confirm variable hh_inc_q
	if _rc==0 {
		ds `targetid' gnd hh_inc_q, not
		foreach var of varlist `r(varlist)' {
			rename `var' `var'_q
		}
		
		ds `targetid' gnd hh_inc_q, not
		reshape wide `r(varlist)', i(`targetid' gnd) j(hh_inc_q)
	}
	else if _rc==111 {  // no income quartile var, label data as pooled
		ds `targetid' gnd, not
		foreach var of varlist `r(varlist)' {
			rename `var' `var'_pool
		}
	}
	else confirm variable hh_inc_q  // unexpected error, throw it
	
	* Reshape gender wide
	ds `targetid' gnd, not
	foreach var of varlist `r(varlist)' {
		rename `var' `var'_
	}
	
	ds `targetid' gnd, not
	reshape wide `r(varlist)', i(`targetid') j(gnd) string
	
end


******************************
*** Generate Online Tables ***
******************************


*** Online Data Table 1
* National life expectancy estimates (pooling 2001-14) for men and women, by income percentile

* Prepare mean income for 40-year-olds
project, original("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use "${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear
gen age_of_inc = age_at_d - lag

keep if age_of_inc == 40 

isid gnd pctile yod
collapse (mean) hh_inc_age40 = hh_inc, by(gnd pctile)

tempfile age40income
save `age40income'

* Combine counts and LEs
combine_counts_and_LE, type(levelspooled) by(gnd pctile) withmeaninc ///
	counts("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta") ///
	le("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile.dta")
merge 1:1 gnd pctile using `age40income', assert(3) nogen
	
* Output
assert inrange(pctile,1,100)
assert _N==200
order gnd pctile count hh_inc*
sort gnd pctile
recast float hh_inc hh_inc_age40, force
save12 "${online}/health_ineq_online_table_1.dta", replace 
project, creates("${online}/health_ineq_online_table_1.dta")


*** Online Data Table 2
* National by-year life expectancy estimates for men and women, by income percentile

combine_counts_and_LE, type(levelsbyyear) by(gnd pctile year) withmeaninc ///
	counts("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta") ///
	le("$derived/le_estimates_stderr/national_SEleBY_gnd_hhincpctile_year.dta")

* Output
assert inrange(pctile,1,100)
assert _N==`=200*14'
order gnd pctile year count hh_inc
sort gnd pctile year
recast float hh_inc, force
save12 "${online}/health_ineq_online_table_2.dta", replace
project, creates("${online}/health_ineq_online_table_2.dta")


*** Online Data Table 3
* State-level life expectancy estimates for men and women, by income quartile

* Load state names
project, uses("$derived/final_covariates/cty_full_covariates.dta")
use statename state_id stateabbrv using "$derived/final_covariates/cty_full_covariates.dta", clear
rename state_id st
duplicates drop
tempfile st
save "`st'"

* Combine counts and LEs
combine_counts_and_LE, type(levelspooled) by(st gnd hh_inc_q) ///
	counts("${derived}/Mortality Sample Counts/st_mortcountsBY_gnd_hhincquartile_age_year.dta") ///
	le("$derived/le_estimates_stderr/st_SEleBY_gnd_hhincquartile.dta")

* Reshape wide on gender and quartile
reshape_wide_gnd_quartile, targetid(st)

* Merge in state names
merge 1:1 st using `st', assert(3) nogen

* Output
assert _N==51
order st stateabbrv statename
order sd*, last
order count*, last
sort st
save12 "${online}/health_ineq_online_table_3.dta", replace
project, creates("${online}/health_ineq_online_table_3.dta")


*** Online Data Table 4
* State-level estimates of trends in life expectancy for men and women, by income quartile

* Load state names
project, uses("$derived/final_covariates/cty_full_covariates.dta")
use statename state_id stateabbrv using "$derived/final_covariates/cty_full_covariates.dta", clear
rename state_id st
duplicates drop
tempfile st
save "`st'"

* Combine counts and LEs
combine_counts_and_LE, type(trends) by(st gnd hh_inc_q) ///
	counts("${derived}/Mortality Sample Counts/st_mortcountsBY_gnd_hhincquartile_age_year.dta") ///
	le("$derived/le_trends_stderr/st_SEletrendsBY_gnd_hhincquartile.dta") 

* Reshape wide on gender and quartile
reshape_wide_gnd_quartile, targetid(st)

* Merge in state names
merge 1:1 st using `st', assert(3) nogen

* Output
assert _N==51
order st stateabbrv statename
order sd*, last
order count*, last
sort st
save12 "${online}/health_ineq_online_table_4.dta", replace
project, creates("${online}/health_ineq_online_table_4.dta")


*** Online Data Table 5
* State-level by-year life expectancy estimates for men and women, by income quartile

* Load state names
project, uses("$derived/final_covariates/cty_full_covariates.dta")
use statename state_id stateabbrv using "$derived/final_covariates/cty_full_covariates.dta", clear
rename state_id st
duplicates drop
tempfile st
save "`st'"

* Combine counts and LEs
combine_counts_and_LE, type(levelsbyyear) by(st gnd hh_inc_q year) ///
	counts("${derived}/Mortality Sample Counts/st_mortcountsBY_gnd_hhincquartile_age_year.dta") ///
	le("$derived/le_estimates_stderr/st_SEleBY_gnd_hhincquartile_year.dta")


* Reshape wide on gender and quartile
reshape_wide_gnd_quartile, targetid(st year)

* Merge in state names
merge m:1 st using `st', assert(3) nogen

* Output
assert _N==`=51*14'
order st stateabbrv statename year
order sd*, last
order count*, last
sort st year
save12 "${online}/health_ineq_online_table_5.dta", replace
project, creates("${online}/health_ineq_online_table_5.dta")


*** Online Data Table 6
* CZ-level life expectancy estimates for men and women, by income quartile

combine_counts_and_LE, type(levelspooled) by(cz gnd hh_inc_q) ///
	counts("${derived}/Mortality Sample Counts/cz_mortcountsBY_gnd_hhincquartile_age_year.dta") ///
	le("$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile.dta")

reshape_wide_gnd_quartile, targetid(cz)

* Merge in CZ characteristics
project, uses("$derived/final_covariates/cz_full_covariates.dta") preserve
merge 1:1 cz using "$derived/final_covariates/cz_full_covariates.dta", assert(2 3) keep(3) ///
	keepusing(czname pop2000 fips statename stateabbrv) nogen

* Output
sort cz
order cz czname pop2000 fips statename stateabbrv
order sd*, last
order count*, last 
save12 "${online}/health_ineq_online_table_6.dta", replace
project, creates("${online}/health_ineq_online_table_6.dta")


*** Online Data Table 7
* CZ-level life expectancy estimates for men and women, by income ventile

** Combine counts and LEs
combine_counts_and_LE, type(levelspooled) by(cz gnd hh_inc_v) ///
	counts("${derived}/Mortality Sample Counts/czLARGE_mortcountsBY_gnd_hhincventile_agebin_year.dta") ///
	le("$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincventile.dta")

rename hh_inc_v hh_inc_q
reshape_wide_gnd_quartile, targetid(cz)
rename *_q* *_v*

* Merge in CZ characteristics
project, uses("$derived/final_covariates/cz_full_covariates.dta") preserve
merge 1:1 cz using "$derived/final_covariates/cz_full_covariates.dta", assert(2 3) keep(3) ///
	keepusing(czname pop2000 fips statename stateabbrv) nogen

* Output
sort cz
order cz czname pop2000 fips statename stateabbrv
order sd*, last
order count*, last 
save12 "${online}/health_ineq_online_table_7.dta", replace
project, creates("${online}/health_ineq_online_table_7.dta")


*** Online Data Table 8
* CZ-level estimates of trends in life expectancy for men and women, by income quartile

* Combine counts and LEs
combine_counts_and_LE, type(trends) by(cz gnd hh_inc_q) ///
	counts("${derived}/Mortality Sample Counts/cz_mortcountsBY_gnd_hhincquartile_age_year.dta") ///
	le("$derived/le_trends_stderr/cz_SEletrendsBY_gnd_hhincquartile.dta") 

* Reshape wide on gender and quartile
reshape_wide_gnd_quartile, targetid(cz)

* Merge in CZ characteristics
project, uses("$derived/final_covariates/cz_full_covariates.dta") preserve
merge 1:1 cz using "$derived/final_covariates/cz_full_covariates.dta", assert(2 3) keep(3) ///
	keepusing(czname pop2000 fips statename stateabbrv) nogen

* Output
sort cz
order cz czname pop2000 fips statename stateabbrv
order sd*, last
order count*, last 
save12 "${online}/health_ineq_online_table_8.dta", replace
project, creates("${online}/health_ineq_online_table_8.dta")


*** Online Data Table 9
* CZ-level by-year life expectancy estimates for men and women, by income quartile

combine_counts_and_LE, type(levelsbyyear) by(cz gnd hh_inc_q year) ///
	counts("${derived}/Mortality Sample Counts/cz_mortcountsBY_gnd_hhincquartile_age_year.dta") ///
	le("$derived/le_estimates_stderr/cz_SEleBY_gnd_hhincquartile_year.dta")

reshape_wide_gnd_quartile, targetid(cz year)

* Merge in CZ characteristics
project, uses("$derived/final_covariates/cz_full_covariates.dta") preserve
merge m:1 cz using "$derived/final_covariates/cz_full_covariates.dta", assert(2 3) keep(3) ///
	keepusing(czname pop2000 stateabbrv) nogen

* Output
sort cz year
order cz czname pop2000 stateabbrv
order sd*, last
order count*, last 
save12 "${online}/health_ineq_online_table_9.dta", replace
project, creates("${online}/health_ineq_online_table_9.dta")


*** Online Data Table 10
* CZ-level characteristics described in eTable 9

* Load list of covariates used
project, original("$root/code/covariates/list_of_covariates.do")
include "$root/code/covariates/list_of_covariates.do"

* Load covariate data
project, uses("$derived/final_covariates/cz_full_covariates.dta")
use "$derived/final_covariates/cz_full_covariates.dta", clear

global covars_all : subinstr global covars_all "cur_smoke_q" "cur_smoke_q*", word
global covars_all : subinstr global covars_all "bmi_obese_q" "bmi_obese_q*", word
global covars_all : subinstr global covars_all "exercise_any_q" "exercise_any_q*", word

* Output
keep cz fips statename stateabbrv czname pop2000 ${covars_all}
order cz czname pop2000 fips statename stateabbrv ${covars_all}
sort cz
save12 "${online}/health_ineq_online_table_10.dta", replace
project, creates("${online}/health_ineq_online_table_10.dta")


*** Online Data Table 11
* County-level life expectancy estimates for men and women, by income quartile

combine_counts_and_LE, type(levelspooled) by(cty gnd hh_inc_q) ///
	counts("${derived}/Mortality Sample Counts/cty_mortcountsBY_gnd_hhincquartile_age_year.dta") ///
	le("$derived/le_estimates_stderr/cty_SEleBY_gnd_hhincquartile.dta")

reshape_wide_gnd_quartile, targetid(cty)

* Merge in local characteristics
project, uses("$derived/final_covariates/cty_full_covariates.dta") preserve
merge 1:1 cty using "$derived/final_covariates/cty_full_covariates.dta", assert(2 3) keep(3) ///
	keepusing(county_name cty_pop2000 cz cz_name cz_pop2000 statename state_id stateabbrv) nogen

* Output
sort cty
order sd*, last
order count*, last
order cty county_name cty_pop2000 cz cz_name cz_pop2000 statename state_id stateabbrv
save12 "${online}/health_ineq_online_table_11.dta", replace
project, creates("${online}/health_ineq_online_table_11.dta")


*** Online Data Table 12
* County-level characteristics described in eTable 9

project, uses("$derived/final_covariates/cty_full_covariates.dta")
use  "$derived/final_covariates/cty_full_covariates.dta", clear

keep cty county_name cty_pop2000 cz cz_name cz_pop2000 statename state_id stateabbrv ///
	 csa csa_name cbsa cbsa_name intersects_msa ${covars_all}
	 
order cty county_name cty_pop2000 cz cz_name cz_pop2000 statename state_id stateabbrv ///
	csa csa_name cbsa cbsa_name intersects_msa ${covars_all}

sort cty
save12 "${online}/health_ineq_online_table_12.dta", replace
project, creates("${online}/health_ineq_online_table_12.dta")


*** Online Data Table 13
* International estimates of mean life expectancy at age 40, by country for men and women

project, relies_on("${root}/data/raw/WHO/source.txt")  // data source
project, relies_on("${root}/data/raw/WHO/GetMortWho.py")  // python download script
project, relies_on("${root}/data/raw/WHO/WHOTables.csv")  // extract from WHO
project, relies_on("${root}/data/raw/WHO/load_international_LEat40.do")  // clean & convert extract

project, original("${root}/data/raw/WHO/International_LEat40_in2013.dta")
use "${root}/data/raw/WHO/International_LEat40_in2013.dta", clear

rename le_raceadj le_
reshape wide le_, i(country) j(gnd) string

save12 "${online}/health_ineq_online_table_13.dta", replace
project, creates("${online}/health_ineq_online_table_13.dta")


*** Online Data Table 14
* Comparison of population and death counts in tax data and NCHS data

project, original("${root}/data/derived/Mortality Rates/NCHS-SSA-IRS Deaths and Populations/death_and_pop_counts_multisource.dta")
use "${root}/data/derived/Mortality Rates/NCHS-SSA-IRS Deaths and Populations/death_and_pop_counts_multisource.dta", clear

save12 "${online}/health_ineq_online_table_14.dta", replace 
project, creates("${online}/health_ineq_online_table_14.dta")


*** Online Data Table 15
* National mortality rates by gender, age, year, and household income percentile

project, original("${root}/data/derived/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use "${root}/data/derived/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear

save12 "${online}/health_ineq_online_table_15.dta", replace 
project, creates("${online}/health_ineq_online_table_15.dta")


*********************
*** Export to CSV ***
*********************

forval i=1/15 { 
	project, uses("${online}/health_ineq_online_table_`i'.dta")
	use "${online}/health_ineq_online_table_`i'.dta", clear 
	
	export delim using "${online}/health_ineq_online_table_`i'.csv", replace
	project, creates("${online}/health_ineq_online_table_`i'.csv")
}


***********************
*** Export to Excel ***
***********************

cap erase "${online}/health_ineq_all_online_tables_raw.xlsx"
forval i=1/15 { 
	project, uses("${online}/health_ineq_online_table_`i'.dta")
	use "${online}/health_ineq_online_table_`i'.dta", clear 
	export excel using "${online}/health_ineq_all_online_tables_raw.xlsx", first(var) sheetrep sh("Online Data Table `i'")
}
project, creates("${online}/health_ineq_all_online_tables_raw.xlsx")
