* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global derived "$root/data/derived"
global cov_raw "$root/data/raw/Covariate Data"
global cov_clean "$root/data/derived/covariate_data"

* Create required folders
cap mkdir "$root/data/derived/final_covariates"

/***

This file uses covariates from 1980-2013. For calculating population change, 
we drop counties that change boundaries at all during the sample period. 
For covariates reported as population averages (smoking rates, percent 
uninsured, etc.), we keep these counties and recode as it makes sense, dropping
small new counties if they don't merge easily to 1990 counties. We also drop
counties in Alaska if the county FIPS has changed since 1990. 

From http://www.ddorn.net/data/FIPS_County_Code_Changes.pdf: 

	- Arizona, 1980s: La Paz county is created out of parts of Yuma county.
	FIPS code 4012 appears. Action: since the La Paz and Yuma counties
	map into different Commuting Zones, attribute the 1980 population of presplit
	Yuma county (FIPS 4027) partly to CZ 38100 (Yuma) and CZ 38300
	(La Paz), using a split proportional to population size in 1990 (Yuma
	106,895 vs. La Paz 13,844).
	- New Mexico, 1980s: Cibola county is created out of parts of Valencia
	county. FIPS code 35006 appears. Action: no action needed because
	Cibola and Valencia both map into the same Commuting Zone.
	- Florida, 1990s: Dade county changes name to Miami-Dade. FIPS code is
	changed from 12025 to 12086 in order to preserve alphabetical sequence
	of county codes. Action: rename code 12086 to 12025.
	- Virginia, 1990s: The independent city of South Boston merges into Halifax
	county. FIPS code 51780 disappears. Action: no action needed because
	South Boston and Halifax both map into the same Commuting Zone. 
	- Montana, 1990s: Yellowstone National Park territory is merged into
	Gallantin and Park counties. FIPS code 30113 disappears. While this
	territorial change already occurred in 1978, the Census bureau only
	became aware of it during the 1990s. Action: no action needed because
	all involved territories map to the same Commuting Zone.
	- Virginia, 2000s: The independent city of Clifton Forge merges into
	Alleghany county. FIPS code 51560 disappears. Action: no action needed
	because Clifton Forge and Alleghany both map into the same Commuting
	Zone.
	- Colorado, 2000s: Broomfield county is created out of parts of Adams,
	Boulder, Jefferson, and Weld counties. FIPS code 8014 appears.
	According to Wikipedia, Boulder county lost about 40,000 inhabitants to
	Broomfield county in 2001. In turn, Broomfield's website indicates a
	population of 42,169 for 2003 which suggests that most of Broomfield's
	population came from Boulder county. Action: assign FIPS code 8014 to
	CZ 28900 which comprises Boulder county (as well as Adams and
	Jefferson counties).

***/

****************
*** Programs ***
****************

program define merge_covariates

	/*** Merge in all the cleaned covariate datasets
		 that are common to CZ-level and County-level data.
	***/
	
	syntax, geo(string)
	
	if ("`geo'"=="cty") local assert "match master"
	else if ("`geo'"=="cz") local assert "match"
	else {
		di as error "geo must be cty or cz"
		exit 198
	}

	* add population change and labor force change
	project, uses("${cov_clean}/`geo'_cs_popchange_labforce.dta") preserve
	merge 1:1 `geo' using "${cov_clean}/`geo'_cs_popchange_labforce.dta", nogen assert(`assert')
	
	* add education variables
	project, uses("${cov_clean}/`geo'_cs_educ.dta") preserve
	merge 1:1 `geo' using "${cov_clean}/`geo'_cs_educ.dta", nogen assert(`assert')
	
	* add fraction of population by race variables
	project, uses("${cov_clean}/`geo'_cs_popbyrace.dta") preserve
	merge 1:1 `geo' using "${cov_clean}/`geo'_cs_popbyrace.dta", nogen assert(`assert')
	
	* add health/mortality covariates
	project, uses("${cov_clean}/`geo'_cs_puninsured.dta") preserve
	merge 1:1 `geo' using "${cov_clean}/`geo'_cs_puninsured.dta", nogen assert(`assert')
	project, uses("${cov_clean}/`geo'_dartmouth.dta") preserve
	merge 1:1 `geo' using "${cov_clean}/`geo'_dartmouth.dta", nogen assert(`assert')
	
	* add BRFSS (and by income)
	project, uses("${cov_clean}/`geo'_brfss_byincq.dta") preserve
	merge 1:1 `geo' using "${cov_clean}/`geo'_brfss_byincq.dta", nogen assert(match master)  // not observed for all CZs
	
	* add Hospital Compare 30-day mortality rates
	project, uses("${cov_clean}/`geo'_hospitalcompare_30day.dta") preserve
	merge 1:1 `geo' using "${cov_clean}/`geo'_hospitalcompare_30day.dta", nogen assert(`assert')

end

program define prep_desired_vars

	syntax, extrakeepvars(varlist)
	
	*** Keep only desired variables
	keep `extrakeepvars' ///
		statename state_id stateabbrv ///
		intersects_msa ///
		cs_frac_black cs_frac_hisp ///
		pop_density ///
		cs_race_theil_2000 cs00_seg_inc cs00_seg_inc_pov25 cs00_seg_inc_aff75 frac_traveltime_lt15 ///
		gini99 poor_share inc_share_1perc frac_middleclass hhinc00 ///
		taxrate subcty_total_taxes_pc subcty_total_expenditure_pc tax_st_diff_top20 ///
		ccd_exp_tot ccd_pup_tch_ratio score_r dropout_r ///
		num_inst_pc tuition gradrate_r cs_educ_ba ///
		unemp_rate pop_d_2000_1980 lf_d_2000_1980 cs_labforce cs_elf_ind_man ///
		mig_inflow mig_outflow cs_born_foreign ///
		scap_ski90pcm rel_tot ///
		crime_total ///
		cs_fam_wkidsinglemom ///
		median_rent median_house_value ///
		s_rank e_rank_b ///
		primcarevis_10 diab_hemotest_10 diab_eyeexam_10 diab_lipids_10 mammogram_10 amb_disch_per1000_10 med_prev_qual_z ///
		adjmortmeas_amiall30day adjmortmeas_chfall30day adjmortmeas_pnall30day mort_30day_hosp_z ///
		cur_smoke* bmi_obese* exercise_any* ///
		puninsured2010 reimb_penroll_adj10
	rename subcty_total_expenditure_pc subcty_exp_pc
	
	*** Change units
	foreach v in rel_tot cs_frac_black cs_frac_hisp cs_born_foreign {
		replace `v' = `v'*100
	}
	
	*** Label Variables
	
	* Race
	label variable cs_frac_black  "% Black"
	label variable cs_frac_hisp  "% Hispanic"
	
	* Population Density
	label variable pop_density "Population Density"
	
	* Segregation
	label variable cs_race_theil_2000 "Racial Segregation"
	label variable cs00_seg_inc  "Income Segregation"
	label variable cs00_seg_inc_pov25  "Segregation of Poverty (<p25)"
	label variable cs00_seg_inc_aff75  "Segregation of Affluence (>p75)"
	label variable frac_traveltime_lt15  "Fraction with Commute < 15 Mins"
	
	* Income Distribution
	label variable hhinc00 "Mean Household Income"
	label variable poor_share  "Poverty Rate"
	label variable inc_share_1perc "Top 1% Income Share"
	label variable gini99 "Gini Index (Within Bottom 99%)"
	label variable frac_middleclass "Fraction Middle Class (between p25 and p75)"
	
	* Tax
	label variable taxrate "Local Tax Rate"
	label variable subcty_total_taxes_pc "Local Tax Revenue per capita"
	label variable subcty_exp_pc "Local Government Expenditures"
	label variable tax_st_diff_top20 "Tax Progressivity"
	
	* K-12 Education
	label variable ccd_exp_tot "School Expenditure per Student"
	label variable ccd_pup_tch_ratio "Student Teacher Ratio"
	label variable score_r "Test Score Percentile (income adjusted)"
	label variable dropout_r "High School Dropout Rate (income adjusted)"
	
	* College
	label variable num_inst_pc "Number of Colleges per Capita"
	label variable tuition "College Tuition"
	label variable gradrate_r "College Graduation Rate (income adjusted)"
	label variable cs_educ_ba "% College Grads"
	
	* Local Labor Market
	label variable cs_labforce "Labor Force Participation"
	label variable cs_elf_ind_man "Share Working in Manufacturing"
	label variable unemp_rate "Unemployment Rate in 2000"
	label variable pop_d_2000_1980 "% Change in Population, 1980-2000"
	label variable lf_d_2000_1980 "% Change in Labor Force, 1980-2000"
	
	* Migration
	label variable mig_inflow "Migration Inflow Rate"
	label variable mig_outflow "Migration Outflow Rate"
	label variable cs_born_foreign "% Immigrants"
	
	* Social Capital
	label variable scap_ski90pcm "Index for Social Capital"
	label variable rel_tot "% Religious"
	
	* Crime
	label variable crime_total "Total Crime Rate"
	
	* Family Structure
	label variable cs_fam_wkidsinglemom "Fraction of Children with Single Mothers"
	
	* Housing
	label variable median_rent "Median Monthly Rent"
	label variable median_house_value "Median House Value"
	
	* Intergenerational Mobility
	label variable s_rank "Relative Mobility (Rank-Rank Slope)"
	label variable e_rank_b "Absolute Upward Mobility"
	
	* Preventive Care
	label variable primcarevis_10 "% with at least 1 Primary Care Visit" 
	label variable diab_hemotest_10 "% Diabetic with Hemoglobin Test"
	label variable diab_eyeexam_10 "% Diabetic with Eye Exam"
	label variable diab_lipids_10 "% Diabetic with Lipids Test"
	label variable mammogram_10 "% Female Ages 67-69 with Mammogram"
	label variable amb_disch_per1000_10 "Discharges for Amb. Care Sensitive Conds."
	label variable med_prev_qual_z "Index for Preventive Care"
	
	* Acute Care
	label variable adjmortmeas_amiall30day "30-day Mortality for Heart Attacks"
	label variable adjmortmeas_chfall30day "30-day Mortality for Pneumonia"
	label variable adjmortmeas_pnall30day "30-day Mortality for Heart Failure"
	label variable mort_30day_hosp_z "30-day Hospital Mortality Rate Index"
	
	* Health Behaviors
	label variable cur_smoke_q1 "Smoking Rate in Q1"
	label variable bmi_obese_q1 "Obesity Rate in Q1"
	label variable exercise_any_q1 "Exercise Rate in Q1"
	label variable cur_smoke_q4 "Smoking Rate in Q4"
	label variable bmi_obese_q4 "Obesity Rate in Q4"
	label variable exercise_any_q4 "Exercise Rate in Q4"
	
	* Insurance Expenditures
	label variable puninsured2010 "% Uninsured"
	label variable reimb_penroll_adj10 "Medicare $ per Enrollee"

end


***********************************
*** Build full covariates files ***
***********************************

*** Make CZ-level covariates file

* IGE variables and covariates (from Equality of Opportunity Project)
project, original("${cov_raw}/cz_characteristics.dta")
use "${cov_raw}/cz_characteristics.dta", clear
drop if cz==.

project, original("${cov_raw}/ige_preferred_measures.dta") preserve
merge 1:1 cz using "${cov_raw}/ige_preferred_measures.dta", nogen assert(match)

replace inc_share_1perc = inc_share_1perc/100  // change units to fraction

* add updated CZ names
drop czname
project, uses("$root/data/derived/final_covariates/cz_names_updated.dta") preserve
merge 1:1 cz using "$root/data/derived/final_covariates/cz_names_updated.dta", nogen assert(match) ///
	keepusing(czname)
	
* add state abbreviations
project, original("${cov_raw}/cz_state_cw_1990.dta") preserve
merge 1:1 cz using "${cov_raw}/cz_state_cw_1990.dta", nogen assert(match)
replace statename = "District of Columbia" if statename=="DC"

project, original("${cov_raw}/state_database.dta") preserve
merge m:1 statename using "${cov_raw}/state_database.dta", nogen keepusing(state) assert(match)
ren state stateabbrv
	
* merge on cause of death data (age- and gender-adjusted)
project, uses("${cov_clean}/cz_NCHS_causeofdeath.dta") preserve
merge 1:1 cz using "${cov_clean}/cz_NCHS_causeofdeath.dta", nogen assert(match master)
	
* merge on other covariates
merge_covariates, geo(cz)

* Keep only desired vars, standardize units, label variables
prep_desired_vars, ///
	extrakeepvars(cz pop2000 fips czname total_mort_coll* ext_mort_coll* med_mort_coll*)

* Output CZ-covariates
compress
sort cz
save13 "${derived}/final_covariates/cz_full_covariates.dta", replace
project, creates("${derived}/final_covariates/cz_full_covariates.dta")


*** Make county-level covariates file

* IGE variables and covariates (from Equality of Opportunity Project)
project, original("${cov_raw}/cty_covariates.dta")
use "${cov_raw}/cty_covariates.dta", clear

gen s_rank = (e_rank_b_kr26_p75 - e_rank_b_kr26_p25)/0.5
ren e_rank_b_kr26_p25 e_rank_b

gen pop_density = exp(log_pop_density)

replace subcty_total_expenditure_pc = 1000 * subcty_total_expenditure_pc // report in dollar amounts

* add updated CZ names
drop cz_name
project, uses("$root/data/derived/final_covariates/cz_names_updated.dta") preserve
merge m:1 cz using "$root/data/derived/final_covariates/cz_names_updated.dta", nogen assert(match) ///
	keepusing(czname)
rename czname cz_name

* merge on other covariates
merge_covariates, geo(cty)

* Keep only desired vars, standardize units, label variables
prep_desired_vars, ///
	extrakeepvars(cty county_name cty_pop2000 cz cz_name cz_pop2000 csa csa_name cbsa cbsa_name)

* Output
compress
sort cty
save13 "${derived}/final_covariates/cty_full_covariates.dta", replace
project, creates("${derived}/final_covariates/cty_full_covariates.dta")


*** Make CZ population data
project, uses("${derived}/final_covariates/cz_full_covariates.dta")
use "${derived}/final_covariates/cz_full_covariates.dta", clear

keep cz pop2000

save13 "${derived}/final_covariates/cz_pop.dta", replace
project, creates("${derived}/final_covariates/cz_pop.dta")


*** Make state population data
project, uses("${root}/data/derived/final_covariates/cty_full_covariates.dta")
use "${root}/data/derived/final_covariates/cty_full_covariates.dta", clear

collapse (sum) pop2000=cty_pop2000, by(state_id)
rename state_id st

save13 "${derived}/final_covariates/st_pop.dta", replace
project, creates("${derived}/final_covariates/st_pop.dta")
