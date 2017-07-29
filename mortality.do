
*** Initialization ***
version 13.1
set more off
set varabbrev off

project, doinfo
local pdir=r(pdir)
adopath ++ "`pdir'/code/ado_ssc"
adopath ++ "`pdir'/code/ado"

project, original("`pdir'/code/ado/scheme-leap.scheme")
set scheme leap

cap mkdir "`pdir'/scratch"

*** Load dependencies into project ***

project, relies_on("`pdir'/code/set_environment.do")
project, relies_on("`pdir'/code/ado/scalarout.ado")
project, relies_on("`pdir'/code/ado_ssc/save13.ado")

foreach dir in "ado_maptile_geo" "ado_ssc" {
	
	cd `"`pdir'/code/`dir'"'
	local files : dir "`c(pwd)'" files "*"

	foreach file in `files' {
		if substr("`file'",1,1)!="." project, relies_on("`file'")
	}

	cd `"`pdir'"'

}


******************
*** Covariates ***
******************

project, do("code/covariates/Health behavior maps.do")


*********************
*** Race shifters ***
*********************

* Figures analyzing race shifters
project, do(code/nlms/nlms_mortality_profiles_BYrace.do)
project, do(code/nlms/nlms_analyze_raceshifters_BYincq_BYcsregion.do)
project, do("code/nlms/Explore mortality profiles implied by race shifters.do")


*******************
*** Race shares ***
*******************

* National sensitivity checks
project, do("code/raceshares/national_Explore race fraction smoothing.do")
project, do("code/raceshares/national_Race share extrapolation check - nonparametric age 51 test.do")


* Local race shares
project, do("code/raceshares/Explore CZ race share maps.do")


***********************
*** Mortality rates ***
***********************

project, do("code/mortality/Plot observed mortality and survival profiles.do")
project, do("code/mortality/Sample comparison - NCHS SSA IRS.do")
project, do("code/mortality/Lag invariance.do")
project, do("code/mortality/Decompose mortality into medical v external.do")

project, do("code/mortality/Summary stats on number of obs and income.do")
project, do("code/mortality/Output income means by national income quantile.do")

*************************
*** Life Expectancies ***
*************************

project, do("code/lifeexpectancy/Plot signal by local population level.do")

project, do("code/lifeexpectancy/Generate Signal Standard Deviations.do")

project, do("code/lifeexpectancy/Check correlations in CZ LE trends.do")

project, do("code/lifeexpectancy/Plot national LE profiles by percentile.do")
project, do("code/lifeexpectancy/National LE profile sensitivity checks.do")
project, do("code/lifeexpectancy/Plot national LE trends by income.do")
project, do("code/lifeexpectancy/Plot major city LE profiles by ventile.do")
project, do(code/lifeexpectancy/le_levels_maps.do)
project, do(code/lifeexpectancy/le_trends_maps.do)
project, do(code/lifeexpectancy/LE ranked lists of states.do)
project, do(code/lifeexpectancy/le_correlations.do)
project, do("code/lifeexpectancy/State Level Inequality Correlations.do")
project, do("code/lifeexpectancy/Plot international comparison of LE at age 40.do")
project, do("code/lifeexpectancy/List top 10 and bottom 10 CZs.do")
project, do("code/lifeexpectancy/Plot CZ LE trend scatters.do")

project, do("code/lifeexpectancy/Sensitivity analyses of local LEs.do")
project, do("code/lifeexpectancy/Standard errors vs population size.do")

project, do("code/lifeexpectancy/Explore national trends at fixed income levels.do")

project, do("code/lifeexpectancy/Compute Years of Social Security Eligibility.do")

****************************************
*** Output numbered figures & tables ***
****************************************

project, do(code/assign_fig_tab_numbers.do)
