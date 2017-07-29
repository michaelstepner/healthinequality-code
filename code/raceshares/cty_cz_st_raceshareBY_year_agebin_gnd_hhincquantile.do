* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

/***
	Generate County, CZ and State race shares by
	(Year x) 5-Year Age Bin x Gender (x Income Quartile).
***/

****************


project, relies_on("$root/code/ado/compute_raceshares.ado")

cap program drop produce_local_raceshares
program define produce_local_raceshares

	/*** Loads race population data that has an income quantile dimension, then
		 computes and saves race shares:
			1. by Year x Geo x Age Bin x Gender x Quantile
			2. by 		 Geo x Age Bin x Gender x Quantile
			3. by 		 Geo x Age Bin x Gender
			
		 Each set of generated race shares can be individually turned on or off.
	***/
	
	syntax , geo(name) qvar(name) dta_qstub(string) [ trends levels noinc ]

	* Load data
	project, uses("$root/data/derived/raceshares/`geo'_racepopBY_year_agebin_gnd_`dta_qstub'.dta")
	use "$root/data/derived/raceshares/`geo'_racepopBY_year_agebin_gnd_`dta_qstub'.dta", clear
	assert !mi(pop_black, pop_asian, pop_hispanic, pop_other)
	
	*** Trends, by year ***
	
	if "`trends'"=="trends" {
		* Compute race shares
		compute_raceshares, by(`geo' year agebin gnd `qvar')
		
		* Save data
		save13 "$root/data/derived/raceshares/`geo'_racesharesBY_year_agebin_gnd_`dta_qstub'.dta", replace
		project, creates("$root/data/derived/raceshares/`geo'_racesharesBY_year_agebin_gnd_`dta_qstub'.dta") preserve
	}
	
	*** Levels, pooled ***
	
	* Pool populations over all years
	isid year `geo' agebin gnd `qvar'
	collapse (sum) pop_*, by(`geo' agebin gnd `qvar')
	
	if "`levels'"=="levels" {
		* Compute race shares
		compute_raceshares, by(`geo' agebin gnd `qvar')
		
		* Save data
		save13 "$root/data/derived/raceshares/`geo'_racesharesBY_agebin_gnd_`dta_qstub'.dta", replace
		project, creates("$root/data/derived/raceshares/`geo'_racesharesBY_agebin_gnd_`dta_qstub'.dta") preserve
	}
	
	*** Levels without income dim, pooled ***
	
	if "`inc'"=="noinc" {  // note: Stata drops the "no" prefix for the local of options beginning with no
		* Pool populations over income bins
		isid `geo' agebin gnd `qvar'
		collapse (sum) pop_*, by(`geo' agebin gnd)
	
		* Compute race shares
		compute_raceshares, by(`geo' agebin gnd)
		
		* Save data
		save13 "$root/data/derived/raceshares/`geo'_racesharesBY_agebin_gnd.dta", replace
		project, creates("$root/data/derived/raceshares/`geo'_racesharesBY_agebin_gnd.dta")
	}
	
end
	
***************************
*** Compute race shares ***
***************************

* Quartile race shares by County, CZ, State
foreach geo in cty cz st {
	produce_local_raceshares, geo(`geo') qvar(hh_inc_q) dta_qstub(hhincquartile) trends levels noinc
}

* Note: some county-level cells have 0 total population, and race shares will therefore be missing

* Ventile race shares by CZ
produce_local_raceshares, geo(cz) qvar(hh_inc_v) dta_qstub(hhincventile) levels
