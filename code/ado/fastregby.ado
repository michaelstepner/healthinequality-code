program define fastregby

	/*** Performs a univariate OLS regression for each by-group, storing the
		 coefficients in new dataset.
		 
		 The following commands are equivalent:
			- fastregby y x, by(byvars) clear
			- statsby, by(byvars) clear: reg y x
			
		 Except fastregby will run approximately 80 times faster.
	***/

	version 13.1
	syntax varlist(min=2 max=2 numeric), by(varlist) clear
	
	* Convert string by-vars to numeric
	foreach var of varlist `by' {
		cap confirm numeric variable `var', exact
		if _rc==0 {  // numeric var
			local bynumeric `bynumeric' `var'
		}
		else {  // string var
			tempvar `var'N
			encode `var', gen(``var'N')
			local bynumeric `bynumeric' ``var'N'
			local bystr `var'  // list of string by-vars
		}
	}
	
	* Sort using by-groups
	sort `by'
	/*
	if ("`:sortedby'"!="`by'") {
		di as error "Loaded dataset must be sorted in by-groups: `by'"
		exit 5
	}
	*/
	
	* Generate a single by-variable counting by groups
	tempvar grp
	egen `grp'=group(`bynumeric')
	
	* Perform regressions on each by-group, store in dataset
	mata: _fastregby("`varlist'", "`grp'", "`bynumeric'")
	
	* Convert string by-vars back to strings, from numeric
	foreach var in `bystr' {
		decode ``var'N', gen(`var')
	}
	order `by'
	
end


version 13.1
set matastrict on

mata:

void _fastregby(string scalar regvars, string scalar grpvar, string scalar byvars) {
	// Inputs:
	//  - a y-var and x-var for an OLS regression
	//  - a group var, for which each value represents a distinct by-group.
	//		This var must be in ascending order.
	//	- a list of numeric by-variables, whose groups correspond to the group var.
	// Outputs:
	//  - dataset of coefficients from OLS regression for each by-group
	
	// Convert variable names to column indices
	real rowvector regcols
	real scalar ycol
	real scalar xcol
	real scalar grpcol
	real rowvector bycols
	
	regcols = st_varindex(tokens(regvars))
	ycol = regcols[1]
	xcol = regcols[2]
	grpcol = st_varindex(grpvar)
	bycols = st_varindex(tokens(byvars))
	
	// Fetch number of groups
	real scalar numgrp
	numgrp = _st_data(st_nobs(),grpcol)
	
	// Preallocate matrices of group identifiers & coefs
	real matrix groups
	real matrix coefs
	groups = J(numgrp, cols(bycols), .)  // Num Groups x Num By-Vars matrix
	coefs = J(numgrp, 2, .)  // Num Groups x 2 matrix
	
	// Perform sequence of regressions
	real matrix M
	real matrix y
	real matrix X
	real scalar startobs
	real scalar curgrp
	startobs=1  // starting obsevation for current group being processed
	curgrp=_st_data(1,grpcol)  // current group being processed
	
	for (obs=1; obs<=st_nobs()-1; obs++) {
	
		if (_st_data(obs,grpcol)!=curgrp) {
			
			// compute OLS coefs: beta = inv(X'X) * X'y.
			// --> see Example 4 of -help mf_cross-
			st_view(M, (startobs,obs-1), regcols, 0)
			st_subview(y, M, ., 1)
			st_subview(X, M, ., (2\.))

			coefs[curgrp,.] = ( invsym(cross(X,1 , X,1)) * cross(X,1 , y,0) )'
			
			// store group identifiers
			groups[curgrp,.] = st_data(startobs,bycols)
			
			// update counters
			curgrp=_st_data(obs,grpcol)
			startobs=obs
			
		}
		
	}
	
	// Always perform regression for last observation
	obs=st_nobs()
	if (_st_data(obs,grpcol)==curgrp) {  // last observation is not a group to itself
	
		// increment obs, since code is written as processing the observation
		// that is 1 past the last in the group
		++obs
	
		// compute OLS coefs: beta = inv(X'X) * X'y.
		// --> see Example 4 of -help mf_cross-
		st_view(M, (startobs,obs-1), regcols, 0)
		st_subview(y, M, ., 1)
		st_subview(X, M, ., (2\.))

		coefs[curgrp,.] = ( invsym(cross(X,1 , X,1)) * cross(X,1 , y,0) )'
		
		// store group identifiers
		groups[curgrp,.] = st_data(startobs,bycols)
	
	}
	else {
		display("{error} last observation is in a singleton group")
		exit(2001)
	}
	
	// Store group identifiers in dataset
	stata("qui keep in 1/"+strofreal(numgrp))
	stata("keep "+byvars)
	st_store(.,tokens(byvars),groups)
	
	// Store coefficients in dataset
	(void) st_addvar("float", "_b_"+tokens(regvars)[2])
	(void) st_addvar("float", "_b_cons")
	st_store(., ("_b_"+tokens(regvars)[2], "_b_cons"), coefs)
	
}

end
