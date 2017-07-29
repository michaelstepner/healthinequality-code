program define wsample

	version 13.1
	syntax newvarname, wt(varname)
	
	qui gen byte `varlist'=.
	mata: draw_wsample("`wt'", "`varlist'")
	
end

version 13.1
set matastrict on

mata:

void draw_wsample(string scalar wt, string scalar gen) {
	// Inputs:
	//  - a variable containing sampling weights,
	//  - an empty variable to store number of times each record is sampled.
	// Requires:
	//  - the weights to be non-missing
	// Outputs:
	//  - number of times each record is sampled, using random sampling with
	//		replacement. each record's probability of being sampled is equal to
	//		its relative sample weight. number of draws = number of records = _N
	

	// Get column number of weight and to-generate vars
	real scalar wtcol
	wtcol = st_varindex(wt)
	
	real scalar gencol
	gencol = st_varindex(gen)
	
	// Compute total weight
	stata("sum " + wt + ", meanonly")
	
	real scalar totwt
	totwt = st_numscalar("r(sum)")
	
	// Generate random draws, uniform from 0 to totwt
	real draws
	draws = runiform(st_nobs(), 1) * totwt
	_sort(draws, 1)
	
	// Store number of times each unit has been drawn
	real scalar timesdrawn
	
	real scalar runningdraws
	runningdraws=1
	
	real scalar runningweight
	runningweight=0

	for (obs=1; obs<=st_nobs(); obs++) {
	
		// Update "running weight" and "times drawn"
		runningweight = runningweight + _st_data(obs,wtcol)
		timesdrawn=0
	
		// Determine number of times this unit was drawn
		while (runningdraws<=st_nobs()) {
			if (draws[runningdraws,1] <= runningweight) {
				timesdrawn++
				runningdraws++
			}
			else break
		}
				
		// Store number of draws
		_st_store(obs, gencol, timesdrawn)
		
	}
	
}

end
