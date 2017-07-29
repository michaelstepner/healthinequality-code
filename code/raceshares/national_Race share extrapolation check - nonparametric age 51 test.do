* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set global aliases
global racedata $root/data/derived/raceshares

* Create required folders
cap mkdir "$root/scratch/Age 51 Retirement Age Extrapolation Test"

/*** Check how well we do predicting race shares in retirement ages,
	 by treating 52 as the retirement age instead of 62 and seeing
	 how well we predict race shares from 52-61.

	 Explanation:

		 We only measure contemporaneous income in the Census, so we
		 don't know how the race shares of 62-year-olds by their income
		 when they were 61.  We therefore use the income distribution
		 at age 61 to impute the income dimension at all retirement ages.
	
		 In practice, we can't test how well this approximation works
		 because the true race shares for retirees by working income are
		 unobsevable. (If they were observable, we'd be using them.)
	
		 We therefore do a test where we treat 52 as the retirement age,
		 use the racial income distributions at age 51 to impute income
		 for ages 52-61, and compare the resulting race shares to the
		 true race shares.

***/

***********************


*******************************************************************
*** Nonparametric extrapolation check with age 51 extrapolation ***
*******************************************************************

* Load race shares based on age 51 extrapolation
project, original("$racedata/Age 51 Retirement Age Extrapolation Test/national_racesharesBY_age_gnd_hhincpctile_51test.dta")
use "$racedata/Age 51 Retirement Age Extrapolation Test/national_racesharesBY_age_gnd_hhincpctile_51test.dta", clear
rename raceshare_* raceshare_51test_*

* Merge true race shares, based on observed age 51-61 income distributions
project, original("$racedata/national_racesharesBY_age_gnd_hhincpctile.dta") preserve
merge 1:1 age gnd pctile using "$racedata/national_racesharesBY_age_gnd_hhincpctile.dta", ///
	keep(match) assert(2 3) nogen

* Check that race shares match exactly at age==51, since we're using age 51 race fracs
foreach r in black asian hispanic other {
	assert abs(raceshare_51test_`r'-raceshare_`r')<10^-6 if age==51
}

* Output figures
foreach income_pctile in 1 10 25 50 75 90 99 {
	foreach race in black asian hispanic other {		
		tw  (connect raceshare_`race' age) ///
			(connect raceshare_51test_`race' age, lpattern(dash)) ///
			if pctile == `income_pctile', ///
			by(gnd, title(`race' p`income_pctile')) ///
			legend(lab(1 "Observed") lab(2 "Extrapolated")) ///
			xlab(51(2)61) ///
			xtitle(Age) ytitle(Race Share)
		graph export "$root/scratch/Age 51 Retirement Age Extrapolation Test/raceshare_51test_p`income_pctile'_`race'.png", replace
		project, creates("$root/scratch/Age 51 Retirement Age Extrapolation Test/raceshare_51test_p`income_pctile'_`race'.png") preserve
	}
}
