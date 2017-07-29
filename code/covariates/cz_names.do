* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global raw "$root/data/raw"
global derived "$root/data/derived"

* Create required folders
cap mkdir "$root/data/derived"
cap mkdir "$root/data/derived/final_covariates"

************

* Load Census 2000 Data
project, original("${raw}/Covariate Data/SUB-EST00INT.csv")
import delimited "${raw}/Covariate Data/SUB-EST00INT.csv", clear
gen cty = state*1000 + county

* Convert 2000-2014 Inter/Postcensal counties to 1999 counties
	* see https://www.census.gov/geo/reference/county-changes.html
drop if cty == 15005 // Kalawao, Hawaii (pop ~90)
recode cty (12086 = 12025) // Miami-Dade FIPS change
recode cty (8014 = 8013) // Broomfield County created from Boulder, CO
recode cty (2282 = 2231) (2275 2195 = 2280) (2230 2105 = 2231) ///
	(2198 = 2201) (2068 = 2290) // County changes in Alaska

project, original("${raw}/Covariate Data/cty_covariates.dta") preserve
merge m:1 cty using "${raw}/Covariate Data/cty_covariates.dta", keepusing(cty county_name cz cz_name statename state_id stateabbrv) 
collapse (sum) popestimate2000 , by(name cz sumlev statename cz_name)
ren cz_name czname_old
keep if !mi(cz)

* String Parsing
replace name = substr(name,1,strlen(name)-6) if lower(substr(name,-5,.)) == "(pt.)"
replace name = substr(name,1,strlen(name)-12) if lower(substr(name,-11,.)) == "and borough"
replace name = substr(name,1,strlen(name)-10) if lower(substr(name,-9,.)) == "(balance)"
replace name = substr(name,1,strlen(name)-12) if lower(substr(name,-11,.)) == "government"

* Subset to cities and towns, Hawaiian Counties, townships with no large cities, and counties with no subdivisions
gen toDrop = 0
replace toDrop = 1 if sumlev <= 50
replace toDrop = 1 if substr(name,-6,.) == "County"
replace toDrop = 1 if substr(name,-6,.) == "Parish"
replace toDrop = 1 if lower(substr(name,1,7)) == "balance"
replace toDrop = 0 if sumlev == 50 & statename == "Hawaii"  //Note that the Hawaiian counties appear to have no subdivisions in the data
bys cz: replace toDrop = 0 if _N == 1
drop if toDrop
gen city_pop = popestimate2000 if lower(substr(name,-8,.)) != "township"
egen max_city_pop = max(city_pop), by(cz)
replace toDrop = 1 if max_city_pop > 60e3 & lower(substr(name,-8,.)) == "township"
drop if toDrop
drop toDrop

* Keep the largest city
gsort cz -popestimate2000
by cz: keep if _n == 1

* More String Parsing
gen suffix = word(name,-1)
gen czname = substr(name,1,length(name) - length(suffix) - 1)
replace czname = name if substr(name,1,8) == "Township"
replace czname = substr(czname,1,strpos(czname,"-")-1) if strpos(czname,"-") & suffix != "city"
replace czname = substr(czname,1,strpos(czname,"/")-1) if strpos(czname,"/")
replace czname = substr(czname,1,length(czname) - length(word(czname,-1)) - 1) if lower(word(czname,-1)) == "charter"
replace czname = "Boise" if czname == "Boise City"
replace czname = "Galesburg" if czname == "Galesburg City"
replace czname = "New York City" if czname == "New York"
replace czname = "Washington DC" if statename == "District Of Columbia"

* Save 
order cz czname statename
keep cz czname statename czname_old
save13 "${derived}/final_covariates/cz_names_updated.dta", replace
project, creates("${derived}/final_covariates/cz_names_updated.dta")

