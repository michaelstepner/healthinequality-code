* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global v4 "${root}/data/raw/NLMS"
global v5 "${root}/data/raw/NLMS v5"

* Create necessary folders
cap mkdir "$root/data/derived/NLMS"

/*** Load raw NLMS data into Stata format
***/

************************************
*** Load NLMS PUMS v5, Sample 11 ***
************************************

*** Brief summary of PUMS Release 5 data, derived from docs

/*
The NLMS PUMS v5 combines CPS and Census data with death certificates, over the period 1973-2011.
We use the NLMS public-use files.

File 11 contains a subset of the 39 NLMS cohorts that can be followed prospectively for 11 years.
In lieu of identifying the CPS year and starting point of mortality follow-up for each file,
all of the records in File 11 have been assigned an imaginary starting point conceptually
identified as April 1, 1990. These records are then tracked forward for 11 years to observe
whether person in the file has died.


Weights for Release 5 of File 11 are normalized to the U.S. non-institutionalized population on April 1, 1990.
[There is an inconsistency on this point in the documentation we received from the NLMS,
which we clarified with Norman Johnson at the Census Bureau.]
*/


*** Documentation

project, relies_on("${v5}/docs/Reference Manual Version 5.pdf")
project, relies_on("${v5}/docs/Read_me.pdf")


*** Load data into Stata

* Load raw data
project, original("${v5}/read_pubfile5.dct")
project, original("${v5}/11.dat")
project, original("${v4}/state_codes_nlms_fips.dta")  // note: crosswalk is same in v4 and v5

infile using "${v5}/read_pubfile5.dct", using("${v5}/11.dat") clear

* Merge on FIPS codes
merge m:1 stater using "${v4}/state_codes_nlms_fips.dta", keepusing(statefips) nogen assert(3)

* Output
compress
isid record
sort record
save13 "$root/data/derived/NLMS/nlms_v5_s11_raw.dta", replace
project, creates("$root/data/derived/NLMS/nlms_v5_s11_raw.dta")


