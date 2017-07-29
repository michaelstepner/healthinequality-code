*******
*** List of Covariates
*******

** Variable categories

* Health Behaviors
local behavior_vars cur_smoke_q bmi_obese_q exercise_any_q

* Health Care
local insurance_vars puninsured2010 reimb_penroll_adj10
local acute_vars mort_30day_hosp_z adjmortmeas_amiall30day adjmortmeas_chfall30day adjmortmeas_pnall30day  // Acute Care
local preventive_vars med_prev_qual_z primcarevis_10 diab_hemotest_10 diab_eyeexam_10 diab_lipids_10 mammogram_10 amb_disch_per1000_10  // Preventive Care

* Environmental Factors
local segregation_vars cs00_seg_inc cs00_seg_inc_pov25 cs00_seg_inc_aff75 cs_race_theil_2000  // Segregation

* Inequality and Social Cohesion
local distribution_vars gini99 poor_share inc_share_1perc frac_middleclass  // Income Distribution
local social_vars scap_ski90pcm rel_tot  // Social Cohesion
local race_vars cs_frac_black cs_frac_hisp // Race & Ethnicity

* Labor Market Conditions
local labor_vars unemp_rate pop_d_2000_1980 lf_d_2000_1980 cs_labforce cs_elf_ind_man

* Other Factors
local migration_vars cs_born_foreign mig_inflow mig_outflow  // Migration
local localgeo_vars pop_density frac_traveltime_lt15  // Local Geography
local affluance_vars hhinc00 median_house_value  // Affluence
local k12_vars ccd_exp_tot ccd_pup_tch_ratio score_r dropout_r  // K-12 Education
local college_vars cs_educ_ba tuition gradrate_r  // College Education
local socioecon_vars e_rank_b cs_fam_wkidsinglemom crime_total  // Socioeconomics
local tax_vars subcty_exp_pc taxrate tax_st_diff_top20  // Local Taxation

** All variables
global covars_other `migration_vars' `localgeo_vars' `affluance_vars' ///
	`k12_vars' `college_vars' `socioecon_vars' `tax_vars'

global covars_all `behavior_vars' `insurance_vars' `acute_vars' `preventive_vars' ///
	`segregation_vars' `distribution_vars' `social_vars' `race_vars' `labor_vars' ///
	${covars_other}
