program define corr_reg

	/*** Run a regression estimating the correlation between two variables.
	***/

	syntax varlist(min=2 max=2 numeric) [if] [aweight fweight], [ vce(string) ]

	*** Prep
	
	* Create convenient weight local
	if ("`weight'"!="") local wt [`weight'`exp']
	
	* Parse yvar and xvar
	local yvar=word("`varlist'",1)
	local xvar=word("`varlist'",2)
	
	*** Regressions
	
	* Regress in natural units
	reg `yvar' `xvar' `if' `wt'
	
	* Convert to Std Dev units
	qui sum `yvar' `wt' if e(sample)
	qui gen mb = (`yvar' - r(mean))/r(sd) 
	
	qui sum `xvar' `wt' if e(sample)
	qui gen vb = (`xvar' - r(mean))/r(sd)
	
	* Regress in standard deviation units, applying VCE if specified
	reg mb vb `if' `wt', vce(`vce')
	drop mb vb
	
	if ("`vce'"!="") di "Note: Standard errors depend on order of y and x with robust standard errors."

end
