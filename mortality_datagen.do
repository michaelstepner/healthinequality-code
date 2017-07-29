
*** Initialization ***
version 13.1
set more off
set varabbrev off

project, doinfo
local pdir=r(pdir)
adopath ++ "`pdir'/code/ado_ssc"
adopath ++ "`pdir'/code/ado"

cap mkdir "`pdir'/data/derived"
cap mkdir "`pdir'/scratch"

*** Load dependencies into project ***

project, relies_on("`pdir'/code/set_environment.do")
project, relies_on("`pdir'/code/ado_ssc/save13.ado")

******************
*** Covariates ***
******************

project, do(code/covariates/cz_names.do)

project, do(code/covariates/clean_pop_labforce_change1980to2000.do)
project, do(code/covariates/clean_educ.do)
project, do(code/covariates/clean_uninsurance.do)
project, do(code/covariates/clean_racefractions.do)
project, do(code/covariates/clean_dartmouthatlas.do)
project, do(code/covariates/clean_brfss.do)
project, do(code/covariates/clean_hospquality.do)
project, do(code/covariates/clean_causeofdeath.do)

project, do(code/covariates/combine_all_covariates.do)


*********************
*** Race shifters ***
*********************

* Prepare NLMS data
project, do(code/nlms/nlms_loaddata.do)
project, do(code/nlms/nlms_createsample.do)

* Generate race shifters
project, do(code/nlms/nlms_generate_shifters.do)

* Bootstrap race shifters
project, do(code/nlms/nlms_bootstrap_shifters.do)


*******************
*** Race shares ***
*******************

** National
project, do(code/raceshares/national_racepopBY_year_age_gnd.do)  // load population data

project, do(code/raceshares/national_racefracBY_workingage_gnd_incpctile.do)  // compute income distributions
project, do(code/raceshares/national_racepopBY_year_age_gnd_incpctile.do)  // impute income dimension in pop data

project, do(code/raceshares/national_raceshareBY_year_age_gnd_incpctile.do)  // pooled 2001-2014 and by-year race shares
project, do(code/raceshares/national_raceshareBY_gnd.do)  // reference race shares

** Local

* Local race populations
project, do(code/raceshares/cty_racepopBY_year_agebin_gnd.do)  // county pop without income dim from Inter/Postcensal estimates

* Local income distributions
project, do(code/raceshares/cty_racepopBY_workingagebin_hhincbin.do)  // HH counts with income bins from Census 2000 SF3 tables
project, do("code/raceshares/Explore income distribution over 16 income bins in County SF3 data.do")
project, do("code/raceshares/SF3 incbin weights for national income quantiles.do")
project, do(code/raceshares/cty_cz_st_racefracBY_workingagebin_hhincquantile.do)
project, do(code/raceshares/cty_cz_st_racepopBY_year_agebin_gnd_hhincquantile.do)

* Local race shares
project, do(code/raceshares/cty_cz_st_raceshareBY_year_agebin_gnd_hhincquantile.do)


***********************
*** Mortality rates ***
***********************

project, do(code/mortality/construct_cdc_mortrates.do)


*************************
*** Life Expectancies ***
*************************

project, do(code/lifeexpectancy/generate_life_expectancies.do)
project, do(code/lifeexpectancy/bootstrap_le.do)
project, do(code/lifeexpectancy/compute_LE_trends.do)
project, do(code/lifeexpectancy/generate_bootstrap_confidence_estimates.do)

project, do("code/lifeexpectancy/Estimate NCHS State LEs pooling income groups.do")

**************************
*** Online Data Tables ***
**************************

project, do(code/create_online_tables.do)
