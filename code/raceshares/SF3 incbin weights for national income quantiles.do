* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "$root/data/derived/raceshares/Bin weights on SF3 income bins for local quantiles/"

/***

Generates the weights required to assign people from income bins into
quantiles of the national income distribution. Each weight corresponds to the
fraction of bin B's population assigned to quantile Q.

To map from 16 income bins into an arbitrary number of quantiles, we fill each
quantile successively.  We start with the lowest quantile, and fill it with
people starting from the lowest bin.  When a bin runs out we start filling from
the next bin, when a quantile is full we switch to filling the next quantile.
Therefore each quantile contains exactly the correct fraction of the national
population.

Note that with this method, the racial demographics of each quantile are slightly
off because we are filling with the *average* characteristics of the bin rather
than the *marginal* characteristics of the bin.

***/

************************

cap program drop quantile_binweights
program define quantile_binweights

	/***
		Input: a dataset of (county) race pop by Age Bin x 16 Income Bins
		
		Output: a dataset with weights corresponding to the fraction of bin B's
				population assigned to quantile Q of the national income distribution.
		
	***/

	syntax using/, nq(integer) qvar(name) [saving(string)]
	
	***** Prepare data on relative frequencies of income bins by Age Bin
	
	* Load data
	project, uses(`"`using'"')
	use `"`using'"', clear
	
	* Create national income distribution by agebin, collapsing over counties
	isid cty hh_inc_bin agebin
	collapse (sum) pop_total, by(hh_inc_bin agebin)
	
	* Convert from population counts to relative frequencies, by agebin
	qui gen double frac_total=.
	qui levelsof agebin, local(ages)
	foreach a of local ages {
		sum pop_total if agebin==`a', meanonly
		qui replace frac_total=pop_total/r(sum) if agebin==`a'
	}
	
	
	***** Compute bin weights for each quantile

	* Confirm the loaded dataset contains expected data
	isid agebin hh_inc_bin
	assert inrange(hh_inc_bin,1,16)
	sort agebin hh_inc_bin
	assert inlist(agebin,35,45,55)  // since those ages are hardcoded into reshape cmd below
	
	
	foreach a of local ages {
	
		* Save vectors of relative frequency percentages
		tempname runningfreq stablefreq
		mkmat frac_total if agebin==`a', matrix(`runningfreq')
		matrix `runningfreq' = `runningfreq' * 100  // will be slowly emptied
		matrix `stablefreq' = `runningfreq'  // will remain untouched
		
		* Save empty matrix of bin weights
		tempname weight
		matrix `weight'=J(`nq',16,0)
		
		* Construct bin weights (in percentage points)
		
		local targetpercentage = 100 / `nq'
		
		forvalues q=1/`nq' {
		
			local runningsum=0
		
			forvalues b=1/16 {
		
				local binfreq `runningfreq'[`b',1]  // just a pointer, not the value
		
				if (`runningsum' == `targetpercentage' | `binfreq'==0) continue
		
				if (`runningsum' + `binfreq' < `targetpercentage') {
					matrix `weight'[`q',`b'] = `binfreq'
					local runningsum = `runningsum' + `binfreq'
					matrix `binfreq' = 0
				}
				else {  // `runningsum' + `binfreq' >= `targetpercentage'
					matrix `weight'[`q',`b'] = `targetpercentage' - `runningsum'
					local runningsum = `targetpercentage'
					matrix `binfreq' = `binfreq' - `weight'[`q',`b']
				}
		
			}
		}
		
		* Convert from percentage points to weightings of each bin
		forvalues q=1/`nq' {
			forvalues b=1/16 {
		
				matrix `weight'[`q',`b'] = `weight'[`q',`b'] / (`stablefreq'[`b',1])
				
			}
		}
		
		* Preserve pointer to the weighting matrix
		local binweight_a`a' `weight'
	
	}
	
	***** Create dataset of bin weights
	
	* Load bin weights from matrices to dataset
	clear
	set obs `nq'
	gen byte `qvar' = _n
	
	foreach a of local ages {
		svmat `binweight_a`a'', names("binweight_a`a'_b")
	}
	
	* Reshape Age and Income Bin long
	reshape long binweight_a35_b binweight_a45_b binweight_a55_b, i(`qvar') j(hh_inc_bin)
	reshape long binweight_a@_b, i(`qvar' hh_inc_bin) j(agebin)
	rename binweight_a_b binweight
	
	* Output
	if `"`saving'"'!="" {
		save13 `"`saving'"', replace
		project, creates(`"`saving'"')
	}
	
end



****************************************************************************
*** Generate bin weights for different quantiles of national income dist ***
****************************************************************************

**** Quartiles
quantile_binweights using "$root/data/derived/raceshares/cty_racepopBY_workingagebin_hhincbin.dta", nq(4) qvar(hh_inc_q) ///
	saving("$root/data/derived/raceshares/Bin weights on SF3 income bins for local quantiles/binweights_quartiles.dta")
	
*** Ventiles
quantile_binweights using "$root/data/derived/raceshares/cty_racepopBY_workingagebin_hhincbin.dta", nq(20) qvar(hh_inc_v) ///
	saving("$root/data/derived/raceshares/Bin weights on SF3 income bins for local quantiles/binweights_ventiles.dta")
