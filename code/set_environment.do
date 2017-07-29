version 13.1
clear all
set more off
pause on

global root "${mortality_root}"

adopath ++ "$root/code/ado_ssc"
adopath ++ "$root/code/ado"

* Disable project (since running do-files directly)
cap program drop project
program define project
	di "Project is disabled, skipping project command. (To re-enable, run -{stata program drop project}-)"
end
