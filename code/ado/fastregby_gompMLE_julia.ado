program define fastregby_gompMLE_julia

	/*** Performs a Gompertz MLE regression for each by-group, storing the
		 coefficients and Cholesky-decomposed covariances in a new dataset.
		 
		 'debug' option prints all output from Julia. Otherwise Julia output is suppressed.
	***/

	version 13.1
	syntax varlist(min=2 max=2 numeric), count(varname numeric) by(varlist) [vce(name) force debug] clear
	if ("`vce'"!="") local vce --vce `vce'
	if ("`debug'"=="") local quietly quietly
	
	* Sort on by-variables
	sort `by'
	
	* Generate a single by-variable counting by-groups
	egen _grp = group(`by')
	
	* Perform regressions on each by-group using Julia
	tempfile deathandsurvival_data gomppar
	
	keep `by' _grp `varlist' `count'
	rename (`varlist' `count') (mort age count)
	qui export delim _grp age mort count using `deathandsurvival_data'
	di "Estimating Gompertz parameters using Julia..."
	`quietly' !${juliapath} "${root}/code/ado/estimate_gompertz.jl" `vce' --input `deathandsurvival_data' --output `gomppar'
	
	* Store association between grp var and by-vars
	keep `by' _grp
	qui duplicates drop `by' _grp, force
	tempfile bylabels
	qui save `bylabels'
	
	* Load results from Julia
	import delim using `gomppar', asdouble clear
	rename (a_slope_1 a_int_1 a_int_2) (A_slope_1 A_int_1 A_int_2)
	qui drop if gomp_int==0 & gomp_slope==0 & A_slope_1==0 & A_int_1==0 & A_int_2==0  // that's how estimate_gompertz.jl indicates error	
	
	* Replace _grp var with by-vars
	qui merge 1:1 _grp using `bylabels', assert(2 3) nogen  // _merge==2 happens when by-groups dropped due to errors
	drop _grp
	order `by'
	sort `by'

end
