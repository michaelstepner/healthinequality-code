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
cap mkdir "${root}/data/derived/le_estimates"
cap mkdir "${root}/data/derived/le_estimates/Gompertz extrapolation to 100"
cap mkdir "${root}/data/derived/le_estimates/Individual income"
cap mkdir "${root}/data/derived/le_estimates/Fixed income levels"
cap mkdir "${root}/data/derived/le_estimates/With zero incomes"
cap mkdir "${root}/data/derived/le_estimates/Largest CZs by ventile"
cap mkdir "${root}/data/derived/le_estimates/OLS Gompertz estimation"
cap mkdir "${root}/data/derived/le_estimates/Cost of Living Adjusted"
cap mkdir "${root}/data/derived/le_estimates/Expected life years until 77"


/*** Generate many sets of life expectancy estimates
		- at different levels of aggregation
		- with different sensitivity checks
		- both unadjusted and race-adjusted

	 The unadjusted LE estimates are calculated using the Gompertz Parameters
	 estimated from the IRS data, following the procedure described in the
	 Supplemental Appendix section "Gompertz Approximations to Mortality Rates".
	 
	 The race-adjusted LE estimates use the Gompertz Parameters estimated from
	 the IRS data, as well as shifters estimated from the NLMS and race shares
	 estimated from the Census.  This follows the procedure described in the
	 Appendix section "Race and Ethnicity Adjustments", "Step 3: Constructing 
	 Race-Specific Mortality Rates and Life Expectancies".

***/


project, original("${root}/code/ado/generate_le_with_raceadj.ado")

*******************************************
*** Life Expectancy Estimates, National ***
*******************************************

* National by Gender x Income Percentile
generate_le_with_raceadj, by(gnd pctile) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta") ///
	raceshares("$derived/raceshares/national_racesharesBY_age_gnd_hhincpctile.dta") ///
	saving("$derived/le_estimates/national_leBY_gnd_hhincpctile.dta")  // formerly national_LE.dta

* National by Gender x Income Percentile x Year
generate_le_with_raceadj, by(gnd pctile year) maxage_gomp_parameterfit(63) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/national_gompBY_gnd_hhincpctile_year.dta") ///
	raceshares("$derived/raceshares/national_racesharesBY_year_age_gnd_hhincpctile.dta") ///
	saving("$derived/le_estimates/national_leBY_year_gnd_hhincpctile.dta")  // formerly national_LE_byyear.dta


*** Sensitivity checks

* National by Gender x Income Percentile, Gompertz extrapolation to 100
generate_le_with_raceadj, by(gnd pctile) maxage_gomp_LEextrap(100) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/national_gompBY_gnd_hhincpctile.dta") ///
	raceshares("$derived/raceshares/national_racesharesBY_age_gnd_hhincpctile.dta") ///
	saving("$derived/le_estimates/Gompertz extrapolation to 100/national_leBY_gnd_hhincpctile_GompertzTo100.dta")  // formerly national_LE_100_cutoff.dta

* National by Gender x INDIVIDUAL Income Percentile
generate_le_with_raceadj, by(gnd indv_earn_pctile) ///
	gomporiginal gompparameters("${derived}/Gompertz Parameters/Individual income/national_gompBY_gnd_INDincpctile.dta") ///
	raceshares("$derived/raceshares/Individual income/national_racesharesBY_age_gnd_INDincpctile.dta") ///
	saving("$derived/le_estimates/Individual income/national_leBY_gnd_INDincpctile.dta")  // formerly national_LE_indiv_income.dta

* National by Gender x Income Percentile x Year; Fixed Income LEVELS
generate_le_with_raceadj, by(gnd pctile year) maxage_gomp_parameterfit(63) ///
	gomporiginal gompparameters("${derived}/Gompertz Parameters/Fixed income levels/national_gompBY_gnd_hhincpctile_year_FixedIncomeLevels.dta") ///
	raceshares("$derived/raceshares/national_racesharesBY_year_age_gnd_hhincpctile.dta") ///
	saving("$derived/le_estimates/Fixed income levels/national_leBY_year_gnd_hhincpctile_FixedIncomeLevels.dta")

* National by Gender x Income Percentile x Year; Each income bin mapped to a 1999 percentile
generate_le_with_raceadj, by(gnd pctile year) maxage_gomp_parameterfit(63) ///
	gomporiginal gompparameters("${derived}/Gompertz Parameters/Fixed income levels/national_gompBY_gnd_hhincpctile_year_BinsIn1999Percentiles.dta") ///
	raceshares("$derived/raceshares/national_racesharesBY_year_age_gnd_hhincpctile.dta") ///
	saving("$derived/le_estimates/Fixed income levels/national_leBY_year_gnd_hhincpctile_BinsIn1999Percentiles.dta")


***************************************************
*** Life Expectancy Estimates by Commuting Zone ***
***************************************************

* CZ by Gender (positive AND ZERO income)
generate_le_with_raceadj, by(cz gnd) ///
	gomporiginal gompparameters("${derived}/Gompertz Parameters/With zero incomes/cz_gompBY_gnd_With0Inc.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd.dta") ///
	saving("$derived/le_estimates/With zero incomes/cz_leBY_gnd_With0Inc.dta")

* CZ by Gender (positive income only)
generate_le_with_raceadj, by(cz gnd) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/cz_gompBY_gnd.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd.dta") ///
	saving("$derived/le_estimates/cz_leBY_gnd.dta")  // formerly cz_le.dta

* CZ by Gender x Income Quartile
generate_le_with_raceadj, by(cz gnd hh_inc_q) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/cz_gompBY_gnd_hhincquartile.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/cz_leBY_gnd_hhincquartile.dta")  // formerly cz_le_quartile.dta

* CZ by Gender x Income Quartile x Year
generate_le_with_raceadj, by(cz gnd hh_inc_q year) maxage_gomp_parameterfit(63) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/cz_gompBY_gnd_hhincquartile_year.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_year_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/cz_leBY_year_gnd_hhincquartile.dta")  // formerly cz_le_quartile_yod.dta

* CZ by Gender x Income Ventile
generate_le_with_raceadj, by(cz gnd hh_inc_v) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/cz_gompBY_gnd_hhincventile.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincventile.dta") ///
	saving("$derived/le_estimates/Largest CZs by ventile/cz_leBY_gnd_hhincventile.dta")  // formerly cz_le_ventile.dta


*** Sensitivity checks

* CZ by Gender x Income Quartile; Gompertz extrapolation to 100
generate_le_with_raceadj, by(cz gnd hh_inc_q) maxage_gomp_LEextrap(100) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/cz_gompBY_gnd_hhincquartile.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/Gompertz extrapolation to 100/cz_leBY_gnd_hhincquartile_GompertzTo100.dta")  // formerly cz_le_quartile_100_cutoff.dta

* CZ by Gender x Income Quartile; OLS Gompertz parameters
generate_le_with_raceadj, by(cz gnd hh_inc_q) ///
	gomporiginal gompparameters("${derived}/Gompertz Parameters/OLS/cz_gompBY_gnd_hhincquartile_OLS.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/OLS Gompertz estimation/cz_leBY_gnd_hhincquartile_OLS.dta")  // formerly cz_le_quartile_OLS.dta
	
* CZ by Gender x Income Quartile; Income-Controlled OLS Gompertz parameters
generate_le_with_raceadj, by(cz gnd hh_inc_q) ///
	gomporiginal gompparameters("${derived}/Gompertz Parameters/OLS/cz_gompBY_gnd_hhincquartile_IncomeControl.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/OLS Gompertz estimation/cz_leBY_gnd_hhincquartile_OLSIncomeControl.dta")  // formerly cz_le_quartile_IncomeControl.dta

* CZ by Gender x Income Quartile; Cost of Living Adjusted
generate_le_with_raceadj, by(cz gnd hh_inc_q) ///
	gomporiginal gompparameters("${derived}/Gompertz Parameters/Cost of Living Adjusted/cz_gompBY_gnd_hhincquartile_COLIadjusted.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/Cost of Living Adjusted/cz_leBY_gnd_hhincquartile_COLIadjusted.dta")  // formerly cz_le_quartile_coli.dta

*** CZ by Gender x Income Quartile; life years until 77 (no extrapolation)

* Generate dummy 'CDC mortrates' that have 100% mortality
clear
set obs 2
gen gnd=cond(_n==1,"M","F")
expand 120
bys gnd: gen age=_n-1
gen cdc_mort=1
tempfile cdc_noextrap
save `cdc_noextrap'

generate_le_with_raceadj, by(cz gnd hh_inc_q) maxage_gomp_LEextrap(77) ///
	cdc_mortrates(`cdc_noextrap') ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/cz_gompBY_gnd_hhincquartile.dta") ///
	raceshares("$derived/raceshares/cz_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/Expected life years until 77/cz_leBY_gnd_hhincquartile_GompertzTo77.dta")

	
	
*******************************************
*** Life Expectancy Estimates by County ***
*******************************************

* County by Gender
generate_le_with_raceadj, by(cty gnd) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/cty_gompBY_gnd.dta") ///
	raceshares("$derived/raceshares/cty_racesharesBY_agebin_gnd.dta") ///
	saving("$derived/le_estimates/cty_leBY_gnd.dta")  // formerly cty_le.dta

* County by Gender x Income Quartile
generate_le_with_raceadj, by(cty gnd hh_inc_q) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/cty_gompBY_gnd_hhincquartile.dta") ///
	raceshares("$derived/raceshares/cty_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/cty_leBY_gnd_hhincquartile.dta")  // formerly cty_le_quartile.dta


******************************************
*** Life Expectancy Estimates by State ***
******************************************

* State by Gender
generate_le_with_raceadj, by(st gnd) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/st_gompBY_gnd.dta") ///
	raceshares("$derived/raceshares/st_racesharesBY_agebin_gnd.dta") ///
	saving("$derived/le_estimates/st_leBY_gnd.dta")

* State by Gender x Income Quartile
generate_le_with_raceadj, by(st gnd hh_inc_q) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/st_gompBY_gnd_hhincquartile.dta") ///
	raceshares("$derived/raceshares/st_racesharesBY_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/st_leBY_gnd_hhincquartile.dta")

* State by Gender x Income Quartile x Year
generate_le_with_raceadj, by(st gnd hh_inc_q year) maxage_gomp_parameterfit(63) ///
	gomporiginal gompparameters("$derived/Gompertz Parameters/st_gompBY_gnd_hhincquartile_year.dta") ///
	raceshares("$derived/raceshares/st_racesharesBY_year_agebin_gnd_hhincquartile.dta") ///
	saving("$derived/le_estimates/st_leBY_year_gnd_hhincquartile.dta")  // formerly st_le_quartile_yod.dta

