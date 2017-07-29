* Subcommand of simulated_delta

program define mle_gomp_est , rclass
	syntax , age(varname) mort(varname) n(varname) [if] [ vce(passthru) ]

	* Estimate the MLE
	glm `mort' `age' [fw = `n'] `if', link(log) family(binomial) from(_cons=-10 `age'=0.1) `vce'

	* Extract Variance Covariance Matrix and Save
	matrix V = e(V)
	* return scalar var_slope = V[1,1]
	* return scalar var_int = V[2,2]
	* return scalar covar_int_slope = V[2,1]

	* Perform Cholesky Decomposition on Covariance Matrix and Save Relevant Coefficients (No need for A_slope_2 since A is upper triangular)
	* Could potentially get additional speed savings by using _cholesky(V), which returns modifies the matrix in place
	matrix A = cholesky(V)
	return scalar A_slope_1 = A[1,1]
	return scalar A_int_1 = A[2,1]
	return scalar A_int_2 = A[2,2]

	* Save point estimates
	return scalar gomp_int = _b[_cons]
	return scalar gomp_slope = _b[`mort':`age']


end

