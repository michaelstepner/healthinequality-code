
*** Initialization ***
version 13.1
set more off
set varabbrev off

project, doinfo
local pdir=r(pdir)
adopath ++ "`pdir'/code/ado_ssc"
adopath ++ "`pdir'/code/ado"

confirmcmd using "`pdir'/code/requirements.txt"  // check that required commands are installed


******************

project, do("code/tests/Explore runtimes for estimating race shifters.do")

project, do("code/tests/Test Julia Gompertz matches Stata Gompertz.do")
project, do("code/tests/Test gen_mortrates.do")
project, do("code/tests/Check completeness of mortality data.do")

project, do("code/tests/Simulate various methods of deriving LE from Gompertz parameters.do")

