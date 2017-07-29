* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set global to match figures whose file type varies
if (c(os)=="Windows") global img wmf
else global img png

* Create required folders
cap mkdir "${root}/results"


/*** Copy results from /scratch over to /results folder,
	 naming them according to their number in the paper.
***/

****

cap program drop assign_result
program define assign_result

	/*** Takes a file, copies it to results folder and renames it.
	***/
	
	syntax using/, to(string) [original]
	
	* check file extension using a regular expression
	if regexm(`"`using'"',"\.[a-zA-Z0-9]+$") local ext=regexs(0)
	else {
		di as error "Could not detect file extension of using file."
		exit 198
	}
	
	* Copy over file
	if ("`original'"=="") project, uses(`"`using'"')
	else project, original(`"`using'"')
	
	copy `"`using'"' `"${root}/results/`to'`ext'"', replace
	project, creates(`"${root}/results/`to'`ext'"')

end


******************
*** Main Paper ***
******************

* Figure 1
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/National p5 and p95 mortality profiles - Male.${img}", to(Figure 1a)
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 mortality profiles - Male.csv", to(Figure 1a - point data)
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 Gompertz parameters - Male.csv", to(Figure 1a - line data)

assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/National p5 and p95 survival profiles - Male.${img}", to(Figure 1b)
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 survival profiles - Male.csv", to(Figure 1b data)


* Figure 2
assign_result using "${root}/scratch/National LE profiles/National LE by Income Percentile and Gender - confidence intervals.${img}", to(Figure 2)
assign_result using "${root}/scratch/National LE profiles/data/National LE by Income Percentile and Gender.csv", to(Figure 2)


* Figure 3
assign_result using "${root}/scratch/National LE trends/National LE trend by Quartile - Male.${img}", to(Figure 3a)
assign_result using "${root}/scratch/National LE trends/data/National LE trend by Quartile - Male.csv", to(Figure 3a)

assign_result using "${root}/scratch/National LE trends/National LE trend by Quartile - Female.${img}", to(Figure 3b)
assign_result using "${root}/scratch/National LE trends/data/National LE trend by Quartile - Female.csv", to(Figure 3b)

assign_result using "${root}/scratch/National LE trends/National LE trend by Ventile - Male.${img}", to(Figure 3c)
assign_result using "${root}/scratch/National LE trends/data/National LE trend by Ventile - Male.csv", to(Figure 3c)

assign_result using "${root}/scratch/National LE trends/National LE trend by Ventile - Female.${img}", to(Figure 3d)
assign_result using "${root}/scratch/National LE trends/data/National LE trend by Ventile - Female.csv", to(Figure 3d)


* Figure 4
assign_result using "${root}/scratch/Major city LE profiles by ventile/Major cities LE profile by Income Ventile - Male.${img}", to(Figure 4a)
assign_result using "${root}/scratch/Major city LE profiles by ventile/data/Major cities LE profile by Income Ventile - Male.csv", to(Figure 4a)

assign_result using "${root}/scratch/Major city LE profiles by ventile/Major cities LE profile by Income Ventile - Female.${img}", to(Figure 4b)
assign_result using "${root}/scratch/Major city LE profiles by ventile/data/Major cities LE profile by Income Ventile - Female.csv", to(Figure 4b)


* Figure 5
assign_result using "$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q1_Male.png", to(Figure 5a)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q1_Male.csv", to(Figure 5a)

assign_result using "$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q1_Female.png", to(Figure 5b)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q1_Female.csv", to(Figure 5b)

assign_result using "$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q4_Male.png", to(Figure 5c)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q4_Male.csv", to(Figure 5c)

assign_result using "$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q4_Female.png", to(Figure 5d)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q4_Female.csv", to(Figure 5d)


* Figure 6
assign_result using "$root/scratch/LE maps/STmap_leTrendsBY_gnd_hhincquartile_Q1_Male.png", to(Figure 6a)
assign_result using "$root/scratch/LE maps/data/STmap_leTrendsBY_gnd_hhincquartile_Q1_Male.csv", to(Figure 6a)

assign_result using "$root/scratch/LE maps/STmap_leTrendsBY_gnd_hhincquartile_Q1_Female.png", to(Figure 6b)
assign_result using "$root/scratch/LE maps/data/STmap_leTrendsBY_gnd_hhincquartile_Q1_Female.csv", to(Figure 6b)


* Figure 7
assign_result using "${root}/scratch/CZ trend scatters/LE trends in selected cities.${img}", to(Figure 7)
assign_result using "${root}/scratch/CZ trend scatters/data/LE trends in selected cities.csv", to(Figure 7)


* Figure 8
assign_result using "$root/scratch/Correlations with local life expectancy/Q1 LE levels correlations.${img}", to(Figure 8)
assign_result using "$root/scratch/Correlations with local life expectancy/data/Q1 LE levels correlations.csv", to(Figure 8)

* Figure 9
assign_result using "$root/scratch/Correlations with local life expectancy/Q4 LE levels correlations.${img}", to(Figure 9)
assign_result using "$root/scratch/Correlations with local life expectancy/data/Q4 LE levels correlations.csv", to(Figure 9)


* Table 1
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 cz - Q1 LE levels.csv", to(Table 1A)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 national - Q1 LE levels.csv", to(Table 1A - US Mean row)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 cz - Q4 LE levels.csv", to(Table 1B)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 national - Q4 LE levels.csv", to(Table 1B - US Mean row)


* Table 2
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 cz - Q1 LE trends.csv", to(Table 2A)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 national - Q1 LE trends.csv", to(Table 2A - US Mean row)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 cz - Q4 LE trends.csv", to(Table 2B)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 national - Q4 LE trends.csv", to(Table 2B - US Mean row)


* Reported numbers

assign_result using "${root}/scratch/National LE profiles/National gap in LE between top and bottom 1 percent.csv", to(Reported numbers - LE gap between top and bottom national percentile by gender)
assign_result using "${root}/scratch/National LE profiles/Gap between Female and Male LE at top and bottom 1 percent.csv", to(Reported numbers - LE gap between men and women at top and bottom percentile)
assign_result using "${root}/scratch/National LE profiles/National LE concavity numbers p10 p15 p90 p95 p100.csv", to(Reported numbers - LE concavity numbers p10 p15 p90 p95 p100)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Aggregate deaths and mortality rate by gender.csv", to(Reported numbers - aggregate deaths and mortrate) original
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Correlation between NCHS and SSA deaths.csv", to(Reported numbers - correlation between NCHS and SSA deaths)
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/Gompertz R squared.csv", to(Reported numbers - Gompertz R2)
assign_result using "${root}/scratch/Medicare and Social Security Eligibility/Years Lived Above 65.csv", to(Reported numbers - Expected years of Social Security and Medicare)

assign_result using "$root/scratch/State LE ranked lists by income quartile/State ranked LE levels Q1.csv", to(Reported numbers - State ranked LE levels Q1)
assign_result using "$root/scratch/State LE ranked lists by income quartile/State ranked LE levels Q`q' - geographic belt among 10 lowest states.png", to(Reported numbers - State ranked LE levels Q1 geographic belt)
assign_result using "$root/scratch/State LE ranked lists by income quartile/State ranked LE levels Q4.csv", to(Reported numbers - State ranked LE levels Q4)
assign_result using "$root/scratch/State LE ranked lists by income quartile/State ranked LE trends Q1.csv", to(Reported numbers - State ranked LE trends Q1)

assign_result using "${root}/scratch/Signal to Noise/Signal SD tests of equality.csv", to(Reported numbers - Signal SD tests of equality)

assign_result using "${root}/scratch/LE maps/CZ LE levels - Q1 mean in top and bottom deciles of CZs.csv", to(Reported numbers - CZ LE levels Q1 mean in top and bottom deciles of CZs)
assign_result using "${root}/scratch/LE maps/CZ LE levels - Test of equality in Q1 LE across CZs.csv", to(Reported numbers - CZ LE levels test of equality in Q1 LE across CZs)

assign_result using "${root}/scratch/Major city LE profiles by ventile/Bottom Ventile LE - Rich vs Poor Cities.csv", to(Reported numbers - Bottom Ventile LE of Rich vs Poor Cities)
assign_result using "${root}/scratch/LE maps/Southern gap.csv", to(Reported numbers - Southern Gap in LE)
assign_result using "${root}/scratch/Correlations with local life expectancy/Reported correlations.csv", to(Reported numbers - correlations)
assign_result using "${root}/scratch/State Gini Correlations/State income inequality correlations.csv", to(Reported numbers - State income inequality correlations)
assign_result using "${root}/scratch/National LE trends/National LE trends results.csv", to(Reported numbers - National LE trends)
assign_result using "${root}/scratch/Summary stats on number of observations age and income/Summary Stats.csv", to(Reported numbers - Summary stats on dataset)

assign_result using "${root}/scratch/NCHS mortality profiles/R-squared of fit lines to NCHS mortality rates in 2001.csv", to(Reported numbers - R-squared of Gompertz in NCHS mortality rates)
assign_result using "${root}/scratch/Top 10 and Bottom 10 locations/Differences between highest and lowest areas in Q1 LE level and trend.csv", to(Reported numbers - Diff in Q1 LE level and trend between highest and lowest CZs)

assign_result using "${root}/scratch/Income means at national percentiles/Income means at national p5 and p95 by gender.csv", to(Reported numbers - Income means at national p5 and p95 by gender.csv)

****************
*** Appendix ***
****************

* Appendix Figure 1
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Death counts in NCHS and SSA by Gender x Age - Male.${img}", to(Appendix Figure 1a - Men)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/data/Death counts in NCHS and SSA by Gender x Age - Male.csv", to(Appendix Figure 1a - Men)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Death counts in NCHS and SSA by Gender x Age - Female.${img}", to(Appendix Figure 1a - Women)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/data/Death counts in NCHS and SSA by Gender x Age - Female.csv", to(Appendix Figure 1a - Women)

assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Death counts in NCHS and SSA by Gender x Year - Male.${img}", to(Appendix Figure 1b - Men)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/data/Death counts in NCHS and SSA by Gender x Year - Male.csv", to(Appendix Figure 1b - Men)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Death counts in NCHS and SSA by Gender x Year - Female.${img}", to(Appendix Figure 1b - Women)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/data/Death counts in NCHS and SSA by Gender x Year - Female.csv", to(Appendix Figure 1b - Women)

* Appendix Figure 2
assign_result using "${root}/scratch/Lag invariance/Mortality v Income Percentile profile of 2014 50-54yo with varying lags - Male.${img}", to(Appendix Figure 2a - Men)
assign_result using "${root}/scratch/Lag invariance/data/Mortality v Income Percentile profile of 2014 50-54yo with varying lags - Male.csv", to(Appendix Figure 2a - Men)
assign_result using "${root}/scratch/Lag invariance/Mortality v Income Percentile profile of 2014 50-54yo with varying lags - Female.${img}", to(Appendix Figure 2a - Women)
assign_result using "${root}/scratch/Lag invariance/data/Mortality v Income Percentile profile of 2014 50-54yo with varying lags - Female.csv", to(Appendix Figure 2a - Women)

assign_result using "${root}/scratch/Lag invariance/Serial correlation of income.${img}", to(Appendix Figure 2b)
assign_result using "${root}/scratch/Lag invariance/data/Serial correlation of income.csv", to(Appendix Figure 2b)

* Appendix Figure 3
assign_result using "${root}/scratch/NCHS mortality profiles/NCHS mortality rates in 2001.${img}", to(Appendix Figure 3)
assign_result using "${root}/scratch/NCHS mortality profiles/NCHS mortality rates in 2001.csv", to(Appendix Figure 3)

* Appendix Figure 4
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/National p5 and p95 mortality profiles - Female.${img}", to(Appendix Figure 4a)
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 mortality profiles - Female.csv", to(Appendix Figure 4a - point data)
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 Gompertz parameters - Female.csv", to(Appendix Figure 4a - line data)

assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/National p5 and p95 survival profiles - Female.${img}", to(Appendix Figure 4b)
assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/data/National p5 and p95 survival profiles - Female.csv", to(Appendix Figure 4b data)


* Appendix Figure 5
assign_result using "${root}/scratch/NLMS mortality profiles by race/NLMS_raw_mortality_profiles_wOLSfitline_M.${img}", to(Appendix Figure 5a)
assign_result using "${root}/scratch/NLMS mortality profiles by race/data/NLMS_raw_mortality_profiles_wOLSfitline_M.csv", to(Appendix Figure 5a)

assign_result using "${root}/scratch/NLMS mortality profiles by race/NLMS_raw_mortality_profiles_wOLSfitline_F.${img}", to(Appendix Figure 5b)
assign_result using "${root}/scratch/NLMS mortality profiles by race/data/NLMS_raw_mortality_profiles_wOLSfitline_F.csv", to(Appendix Figure 5b)


* Appendix Figure 6
assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/NLMS_raceshifterBYincq_ALLblack.${img}", to(Appendix Figure 6a)
assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/data/NLMS_raceshifterBYincq_ALLblack.csv", to(Appendix Figure 6a)

assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/NLMS_raceshifterBYincq_ALLhisp.${img}", to(Appendix Figure 6b)
assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/data/NLMS_raceshifterBYincq_ALLhisp.csv", to(Appendix Figure 6b)

assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/NLMS_raceshifterBYincq_ALLasian.${img}", to(Appendix Figure 6c)
assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/data/NLMS_raceshifterBYincq_ALLasian.csv", to(Appendix Figure 6c)


* Appendix Figure 7
assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/NLMS_raceshifterBYcsregion_ALLblack.${img}", to(Appendix Figure 7a)
assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/data/NLMS_raceshifterBYcsregion_ALLblack.csv", to(Appendix Figure 7a)

assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/NLMS_raceshifterBYcsregion_ALLhisp.${img}", to(Appendix Figure 7b)
assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/data/NLMS_raceshifterBYcsregion_ALLhisp.csv", to(Appendix Figure 7b)

assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/NLMS_raceshifterBYcsregion_ALLasian.${img}", to(Appendix Figure 7c)
assign_result using "${root}/scratch/NLMS race shifters by incq and csregion/data/NLMS_raceshifterBYcsregion_ALLasian.csv", to(Appendix Figure 7c)

* Appendix Figure 8
assign_result using "${root}/scratch/National LE profiles/National LE by Income and Gender - confidence intervals.${img}", to(Appendix Figure 8)
assign_result using "${root}/scratch/National LE profiles/National LE by Income and Gender.csv", to(Appendix Figure 8)

* Appendix Figure 9
assign_result using "${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - raceadj vs unadj.${img}", to(Appendix Figure 9a)
assign_result using "${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - raceadj vs unadj.csv", to(Appendix Figure 9a)

assign_result using "${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - gomp90 vs gomp100.${img}", to(Appendix Figure 9b)
assign_result using "${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - gomp90 vs gomp100.csv", to(Appendix Figure 9b)

assign_result using "${root}/scratch/National LE profiles - sensitivity checks/National LE by Income Percentile and Gender - ind vs hh.${img}", to(Appendix Figure 9c)
assign_result using "${root}/scratch/National LE profiles - sensitivity checks/data/National LE by Income Percentile and Gender - ind vs hh.csv", to(Appendix Figure 9c)


* Appendix Figure 10
assign_result using "$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q2_Male.png", to(Appendix Figure 10a)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q2_Male.csv", to(Appendix Figure 10a)

assign_result using "$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q2_Female.png", to(Appendix Figure 10b)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q2_Female.csv", to(Appendix Figure 10b)

assign_result using "$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q3_Male.png", to(Appendix Figure 10c)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q3_Male.csv", to(Appendix Figure 10c)

assign_result using "$root/scratch/LE maps/CZmap_leBY_gnd_hhincquartile_Q3_Female.png", to(Appendix Figure 10d)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_gnd_hhincquartile_Q3_Female.csv", to(Appendix Figure 10d)

* Appendix Figure 11
assign_result using "${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - CZ LE levels.${img}", to(Appendix Figure 11a)
assign_result using "${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - CZ LE levels.csv", to(Appendix Figure 11a)

assign_result using "${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - County LE levels.${img}", to(Appendix Figure 11b)
assign_result using "${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - County LE levels.csv", to(Appendix Figure 11b)

assign_result using "${root}/scratch/Standard errors vs population size/Standard error vs population size binscatter - CZ LE trends.${img}", to(Appendix Figure 11c)
assign_result using "${root}/scratch/Standard errors vs population size/data/Standard error vs population size binscatter - CZ LE trends.csv", to(Appendix Figure 11c)

* Appendix Figure 12
assign_result using "$root/scratch/LE maps/CSAmap_leBY_gnd_hhincquartile_New York_Q1_Male.png", to(Appendix Figure 12a)
assign_result using "$root/scratch/LE maps/data/CSAmap_leBY_gnd_hhincquartile_New York_Q1_Male.csv", to(Appendix Figure 12a)

assign_result using "$root/scratch/LE maps/CSAmap_leBY_gnd_hhincquartile_New York_Q1_Female.png", to(Appendix Figure 12b)
assign_result using "$root/scratch/LE maps/data/CSAmap_leBY_gnd_hhincquartile_New York_Q1_Female.csv", to(Appendix Figure 12b)

assign_result using "$root/scratch/LE maps/CSAmap_leBY_gnd_hhincquartile_Detroit_Q1_Male.png", to(Appendix Figure 12c)
assign_result using "$root/scratch/LE maps/data/CSAmap_leBY_gnd_hhincquartile_Detroit_Q1_Male.csv", to(Appendix Figure 12c)

assign_result using "$root/scratch/LE maps/CSAmap_leBY_gnd_hhincquartile_Detroit_Q1_Female.png", to(Appendix Figure 12d)
assign_result using "$root/scratch/LE maps/data/CSAmap_leBY_gnd_hhincquartile_Detroit_Q1_Female.csv", to(Appendix Figure 12d)


* Appendix Figure 13
assign_result using "$root/scratch/BRFSS maps/CZ map - Smoking Rate in Q1.png", to(Appendix Figure 13a)
assign_result using "$root/scratch/BRFSS maps/data/CZ map - Smoking Rate in Q1.csv", to(Appendix Figure 13a)

assign_result using "$root/scratch/BRFSS maps/CZ map - Obesity Rate in Q1.png", to(Appendix Figure 13b)
assign_result using "$root/scratch/BRFSS maps/data/CZ map - Obesity Rate in Q1.csv", to(Appendix Figure 13b)

assign_result using "$root/scratch/BRFSS maps/CZ map - Exercise Rate in Q1.png", to(Appendix Figure 13c)
assign_result using "$root/scratch/BRFSS maps/data/CZ map - Exercise Rate in Q1.csv", to(Appendix Figure 13c)

assign_result using "$root/scratch/LE maps/CZmap_leBY_hhincquartile_Q1_pooledgender.png", to(Appendix Figure 13d)
assign_result using "$root/scratch/LE maps/data/CZmap_leBY_hhincquartile_Q1_pooledgender.csv", to(Appendix Figure 13d)


* Appendix Figure 14
assign_result using "$root/scratch/Correlations with local life expectancy/Gini correlation with LE levels by quartile.${img}", to(Appendix Figure 14)
assign_result using "$root/scratch/Correlations with local life expectancy/data/Gini correlation with LE levels by quartile - raw data.csv", to(Appendix Figure 14 - raw data)
assign_result using "$root/scratch/Correlations with local life expectancy/data/Gini correlation with LE levels by quartile - binned scatterpoints.csv", to(Appendix Figure 14 - binned scatterpoints)


* Appendix Figure 15
assign_result using "$root/scratch/Correlations with local life expectancy/Q1 LE trends correlations.${img}", to(Appendix Figure 15)
assign_result using "$root/scratch/Correlations with local life expectancy/data/Q1 LE trends correlations.csv", to(Appendix Figure 15)

* Appendix Figure 16
assign_result using "$root/scratch/International comparison of LE at 40/International comparison of LE at 40 - Men.${img}", to(Appendix Figure 16a)
assign_result using "$root/scratch/International comparison of LE at 40/data/International comparison of LE at 40 - Men.csv", to(Appendix Figure 16a)

assign_result using "$root/scratch/International comparison of LE at 40/International comparison of LE at 40 - Women.${img}", to(Appendix Figure 16b)
assign_result using "$root/scratch/International comparison of LE at 40/data/International comparison of LE at 40 - Women.csv", to(Appendix Figure 16b)


* Appendix Figure 17
assign_result using "$root/scratch/LE maps/CZmap_With0IncleBY_gnd_Male.png", to(Appendix Figure 17a)
assign_result using "$root/scratch/LE maps/data/CZmap_With0IncleBY_gnd_Male.csv", to(Appendix Figure 17a)

assign_result using "$root/scratch/LE maps/CZmap_With0IncleBY_gnd_Female.png", to(Appendix Figure 17b)
assign_result using "$root/scratch/LE maps/data/CZmap_With0IncleBY_gnd_Female.csv", to(Appendix Figure 17b)


* Appendix Table 1
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Population Counts.csv", to(Appendix Table 1A)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Death Counts.csv", to(Appendix Table 1B)
assign_result using "${root}/scratch/Deaths and population counts in IRS and other samples/Comparison across samples of Mortality Rates.csv", to(Appendix Table 1C)

* Appendix Table 2
assign_result using "${root}/data/raw/IRS correlations between income lags/Reg mortrate on income averages.csv", to(Appendix Table 2) original

* Appendix Table 3
*contains definitions, no data

* Appendix Table 4
assign_result using "${root}/scratch/National LE Trends at fixed income levels or ranks/National LE trend by Quartile Controlling for Income.csv", to(Appendix Table 4)

* Appendix Table 5
assign_result using "${root}/scratch/Signal to Noise/CZ Signal SD of LE Levels - by Gender x Quartile.csv", to(Appendix Table 5A)
assign_result using "${root}/scratch/Signal to Noise/State Signal SD of LE Trends - by Gender x Quartile.csv", to(Appendix Table 5B)

* Appendix Table 6
assign_result using "${root}/scratch/Sensitivity analyses of local LE/CZ correlations of baseline raceadj LE with alternatives - Male.csv", to(Appendix Table 6A)
assign_result using "${root}/scratch/Sensitivity analyses of local LE/CZ correlations of baseline raceadj LE with alternatives - Female.csv", to(Appendix Table 6B)
assign_result using "${root}/scratch/Sensitivity analyses of local LE/Counts of CZs in each sensitivity correlation.csv", to(Appendix Table 6 - Number of CZs in each Corr)

* Appendix Table 7
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 cty - Q1 LE levels.csv", to(Appendix Table 7A)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 national - Q1 LE levels.csv", to(Appendix Table 7A - US Mean row)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 cty - Q4 LE levels.csv", to(Appendix Table 7B)
assign_result using "$root/scratch/Top 10 and Bottom 10 locations/Top 10 and Bottom 10 national - Q4 LE levels.csv", to(Appendix Table 7B - US Mean row)

* Appendix Table 8
assign_result using "$root/scratch/Correlations with local life expectancy/Correlates of LE levels by cz x Gender x Income Quartile.csv", to(Appendix Table 8)

* Appendix Table 9
assign_result using "$root/scratch/Correlations with local life expectancy/Correlates of LE levels by cty x Gender x Income Quartile.csv", to(Appendix Table 9)

* Appendix Table 10
assign_result using "${root}/scratch/Decompose mortality into medical v external/Regressions decomposing mortality rates into medical vs external causes.csv", to(Appendix Table 10)


* Appendix numbers

assign_result using "${root}/scratch/National p5 and p95 mortality and survival profiles/Gompertz aggregation approx error sim.csv", to(Appendix numbers - Gompertz aggregation error sim)
assign_result using "${root}/scratch/LE maps/County LE levels - top and bottom counties for New York men.csv", to(Appendix numbers - New York counties top and bottom for men)
assign_result using "${root}/scratch/Standard errors vs population size/Reported SDs.csv", to(Appendix numbers - Standard errors of local LE levels and trends)
assign_result using "${root}/scratch/CZ trend correlations/Correlation between CZ LE trends raceadj and unadj.csv", to(Appendix numbers - Correlation between CZ LE trends raceadj and unadj)
assign_result using "${root}/scratch/National LE profiles/Racial gap in average LE.csv", to(Appendix numbers - Racial gap in average LE)

assign_result using "${root}/scratch/Signal to Noise/CZ LE Levels - Signal share of variance.csv", to(Appendix numbers - Signal share of variance - CZ LE Levels)
assign_result using "${root}/scratch/Signal to Noise/County LE Levels - Signal share of variance.csv", to(Appendix numbers - Signal share of variance - County LE Levels)
assign_result using "${root}/scratch/Signal to Noise/CZ LE Trends - Signal share of variance.csv", to(Appendix numbers - Signal share of variance - CZ LE Trends)
assign_result using "${root}/scratch/Signal to Noise/State LE Trends - Signal share of variance.csv", to(Appendix numbers - Signal share of variance - State LE Trends)
