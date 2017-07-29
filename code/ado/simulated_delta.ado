program define simulated_delta

	/*** Draw new Gompertz parameters from the estimated multivariate normal distribution
		 with point estimates and covariance from the MLE.
	***/

	version 13.1
	syntax varlist(min=1), REPs(integer) [seed(string) keep(string)]
	local group `varlist'

	isid `group'
	expand `reps'
	bys `group': gen sample_num = _n
	order `group' sample_num
	
	set seed `seed'
	tempvar z1 z2
	gen `z1' = rnormal()
	gen `z2' = rnormal()
	
	replace gomp_slope = A_slope_1*`z1' + gomp_slope
	replace gomp_int = A_int_1*`z1' + A_int_2*`z2' + gomp_int
	
	keep `group' `keep' sample_num gomp_int gomp_slope

end
