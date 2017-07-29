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
cap mkdir "${root}/scratch/National income means by quantile"
cap mkdir "${root}/scratch/Income means at national percentiles"

* Erase output numbers
cap erase "${root}/scratch/Income means at national percentiles/Income means at national p5 and p95 by gender.csv"

/*** Output mean income by national income percentile, ventile, and quartile, 
by gender, pooling across years and ages.
***/

****************************************
*** Mean income by income percentile ***
****************************************

* Load national mortality rates
project, original("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use if age_at_d>=40 using "${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear

* Pool all years and ages (years 2001-2014, ages 40-76)
collapse (mean) hh_inc (rawsum) count [w=count], by(gnd pctile)

* Export data
save13 "${root}/scratch/National income means by quantile/National income means by percentile.dta", ///
	replace
project, creates("${root}/scratch/National income means by quantile/National income means by percentile.dta") preserve

*** Paper numbers
foreach g in "M" "F" {
	foreach p in 5 95 {

		sum hh_inc if gnd=="`g'" & pctile==`p'
		assert r(N)==1
		scalarout using "${root}/scratch/Income means at national percentiles/Income means at national p5 and p95 by gender.csv", ///
			id("National mean income at p`p' pooling ages and years: `g'") ///
			num(`=r(mean)') fmt(%12.0fc)
	}
}
project, creates("${root}/scratch/Income means at national percentiles/Income means at national p5 and p95 by gender.csv")


**************************************
*** Mean income by income quartile ***
**************************************

* Load national mortality rates
project, original("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use if age_at_d>=40 using "${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear

* Collapse to quartiles, pooling all years and ages (years 2001-2014, ages 40-76)
gen quartile=ceil(pctile/25)
collapse (mean) hh_inc (rawsum) count [w=count], by(gnd quartile)

* Export data 
save13 "${root}/scratch/National income means by quantile/National income means by quartile.dta", ///
	replace
project, creates("${root}/scratch/National income means by quantile/National income means by quartile.dta")


*************************************
*** Mean income by income ventile ***
*************************************

* Load national mortality rates
project, original("${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use if age_at_d>=40 using "${derived}/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear

* Collapse to ventiles, pooling all years and ages (years 2001-2014, ages 40-76)
gen ventile=ceil(pctile/5)
collapse (mean) hh_inc (rawsum) count [w=count], by(gnd ventile)

* Export data 
save13 "${root}/scratch/National income means by quantile/National income means by ventile.dta", ///
	replace
project, creates("${root}/scratch/National income means by quantile/National income means by ventile.dta")

