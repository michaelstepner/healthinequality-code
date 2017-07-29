program define compute_racefracs

	/***
	
	In each by-group, compute the fraction of each race's population in each income bin.
	
	For example, if black males had the same income distribution as the full population,
	they would be 0.01 of each percentile. Across income bins, the fractions sum to one.
	
	Optionally, smooth the race fractions across positive bins using lowess.
	
	***/

	syntax , by(varlist) incomevar(varname) [ racelist(namelist) lowess_bw(real -99) ]
	
	if ("`racelist'"=="") local racelist black hispanic asian other
	
	* Verify that file is identified at By Group x Income Bin level
	isid `by' `incomevar'
	
	* Generate race fractions
	foreach race in `racelist' {
	
		tempvar sumpop_`race'
		egen long `sumpop_`race''=total(pop_`race'), by(`by')
		
		qui gen double frac_of_`race'=pop_`race'/`sumpop_`race''
		label var frac_of_`race' "Fraction of `race' population in income bin"
		
	}
	
	* Smooth the noise in the race fractions across positive income bins
	if (`lowess_bw'!=-99) {
		foreach race in `racelist' {
		
			* Lowess smooth race fractions
			lowess frac_of_`race' `incomevar' if `incomevar'>0, by(`by') nograph gen(smoothfrac_of_`race') bw(`lowess_bw')
			qui replace smoothfrac_of_`race' = frac_of_`race' if `incomevar'<=0
			label var smoothfrac_of_`race' "Smoothed fraction of `race' population in income bin"
			
			* Renormalize the smoothed estimates so that the fractions will sum to 1 for each age x gnd
			tempvar sumfrac_`race' sumsmoothfrac_`race'
			qui egen double `sumfrac_`race''=total(frac_of_`race') if `incomevar'>0, by(`by')
			qui egen double `sumsmoothfrac_`race''=total(smoothfrac_of_`race') if `incomevar'>0, by(`by')
			
			qui replace smoothfrac_of_`race' = smoothfrac_of_`race'/`sumsmoothfrac_`race''*`sumfrac_`race'' if `incomevar'>0
			
			* Check that smoothfracs sum to 1
			tempvar newsumsmoothfrac_`race'
			egen float `newsumsmoothfrac_`race'' = total(smoothfrac_of_`race'), by(`by')
			assert abs(`newsumsmoothfrac_`race''-1)<10^-6
			
			* Change smoothfrac datatype from double to float (the final digits vary between runs, this rounds them away)
			qui recast float smoothfrac_of_`race', force

		}
	}
	
	* Change frac datatype from double to float (the extra precision isn't meaningful)
	qui recast float frac_of_*, force
	
end
