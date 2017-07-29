program define compute_raceshares
	/*** Compute race shares in each By Group x Income Percentile cell
	***/

	syntax , by(varlist)
	
	* Verify that file is identified at By Group x Income Percentile level
	isid `by'

	* Generate race shares
	foreach race in black asian hispanic other {
	
		* Compute race share in each cell
		gen double raceshare_`race' = pop_`race' / (pop_black + pop_asian + pop_hispanic + pop_other)
		label var raceshare_`race' "Share of `race' in -`by'- cell"
		
	}
	
	* Check that race shares sum to 1 in each cell OR all are missing because total population is 0 in the cell
	assert abs(raceshare_black + raceshare_asian + raceshare_hispanic + raceshare_other - 1) < 10^-6 | ///
		(pop_black + pop_asian + pop_hispanic + pop_other)==0
	
	* Set order
	order `by' pop_* raceshare_*
	
end
