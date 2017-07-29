
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

***********************
*** Mortality rates ***
***********************

project, do("code/mortality/Construct multi-source death and population counts.do")
project, do(code/mortality/convert_IRScollapses_to_mortrates.do)

project, do(code/mortality/estimate_irs_gompertz_parameters.do)

project, do("code/mortality/Calculate aggregate deaths.do")
