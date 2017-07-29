program define compute_ci_percentiles

	syntax varlist(numeric) , by(varlist) gen(name)
	
	* Build matrix of 2.5th and 97.5th percentiles
	foreach var of local varlist {
		tempfile `var'pctiles
	
		statsby `var'25=r(r1) `var'975=r(r2), saving(``var'pctiles') ///
			by(`by'): _pctile `var', percentiles(2.5 97.5)
	}
	
	* Combine datasets of percentile values
	clear
	qui use `by' using ``:word 1 of `varlist''pctiles'
	foreach var of local varlist {
		qui merge 1:1 `by' using ``var'pctiles', assert(3) nogen
	}
	
	* Reshape percentile long
	reshape long `varlist', i(`by') j(`gen')
	replace `gen'=`gen'/10
	
end
