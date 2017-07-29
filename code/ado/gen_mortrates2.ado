program define gen_mortrates2

	/*** Input is a loaded dataset that is:
			- Identified by
				`varlist' x `age' x `year'
			- Containing variables:
				- `age', the age at which income is measured
				- `n', the count of people in that cell
				- deadby_1_Mean to deadby_18_Mean containing the cumulative
					fraction of people who were alive at the time income was
					measured, but have died by the start of the n'th year later.
					
		 The variable specified in age() must either be:
			- named age, containing exact years
			- OR named agebin, containing 5-year agebins and a 4-year agebin
				whose income is measured at 58-61 => 2-year mortality measured 60-63.
				
				These agebins should be labeled by the mean age at which
				**income** is measured.
	***/

	syntax varlist, age(varname) year(varname) n(varname) [ all_lags ]
	local by `varlist'
	if ("`n'"!="count") rename `n' count
	isid `by' `age' `year'
	
	* Check no one dies in first year
	assert deadby_1_Mean==0
	
	* Check expected years are present
	forvalues i=1/18 {
		confirm numeric var deadby_`i'_Mean
	}
	
	* Check maximum age
	sum `age', meanonly
	if ("`age'"=="age") assert r(max)==61  // maximum age is exactly 61 (last working age)
	else if ("`age'"=="agebin") assert r(max)==59.5  // maximum agebin is 58-61
	else {
		di as error "age() variable must either be age or agebin."
		exit 198
	}
	local maxage=r(max)
	
	* Reshape long on how many years income is lagged
	reshape long deadby_@_Mean, i(`by' `age' `year') j(lag)
	label var lag "Income Lag"
	
	* Only use 2-year lags except for age 61/agebin 60, which we use throughout retirement
	if ("`all_lags'"=="") drop if lag > 2 & `age' < `maxage'
	else local lag lag  // lag will be an identifying variable

	* Calculate mortality rates & count of surviving population
	by `by' `age' `year' (lag): gen double mortrate = (deadby__Mean - deadby__Mean[_n-1]) / (1 - deadby__Mean[_n-1] )
	by `by' `age' `year' (lag): replace count = count[1] * (1 - deadby__Mean[_n-1]) if lag>1
	compress count
	label var mortrate "Mortality Rate"
	label var count "Denominator of mortrate = people alive at beginning of year"
	
	* Clean data
	assert lag==1 | mi(deadby__Mean) if mi(mortrate)
	drop if mi(mortrate)
	
	* Generate age and year of death
	gen age_at_d = `age' + lag
	gen int yod = `year' + lag
	drop `age' `year'
	compress age_at_d
	
	label var age_at_d "Age at Death"
	label var yod "Year of Death"
	
	* Check no data past 2014
	capture assert yod<=2014
	if _rc!=0 {  // check that data past 2014 is missing and can be thrown away
		assert deadby__Mean==0 | deadby__Mean==. if yod>2014
		drop if yod>2014
	}
	
	* Output
	drop deadby__Mean
	order `by' age_at_d yod lag mortrate count
	isid `by' age_at_d yod `lag'
	sort `by' age_at_d yod `lag'
	label data ""
end
