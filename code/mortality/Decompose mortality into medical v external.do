* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "${root}/scratch/Decompose mortality into medical v external"

************

* Load data
project, original("${root}/data/derived/final_covariates/cz_full_covariates.dta")
use "${root}/data/derived/final_covariates/cz_full_covariates.dta", clear
keep cz *_mort_coll* pop2000

rename ext* external*
rename med* medical*

* Run regressions
clear matrix
foreach c in 0 1 {
	foreach m in "external" "medical" {
	
		reg `m'_mort_coll`c' total_mort_coll`c' [w=pop2000], robust
		matrix reg_decompose = nullmat(reg_decompose), ///
			(_b[total_mort_coll`c'] \ _se[total_mort_coll`c'] \ e(N))
			
		local cols `cols' `m'_coll`c'
	}
}

* Store regression results in dataset
matrix colnames reg_decompose = `cols'
clear
svmat reg_decompose, names(col)

gen result=""
replace result = "coef" in 1
replace result = "se" in 2
replace result = "N" in 3
order result

* Output
export delim using "${root}/scratch/Decompose mortality into medical v external/Regressions decomposing mortality rates into medical vs external causes.csv", ///
	replace
project, creates("${root}/scratch/Decompose mortality into medical v external/Regressions decomposing mortality rates into medical vs external causes.csv")
