*! 6sep2014, Michael Stepner, stepner@mit.edu

program define _maptile_state
	syntax , [  geofolder(string) ///
				mergedatabase ///
				map spmapvar(varname) var(varname) binvar(varname) clopt(string) legopt(string) min(string) clbreaks(string) max(string) mapcolors(string) ndfcolor(string) ///
					savegraph(string) replace resolution(string) map_restriction(string) spopt(string) ///
				/* Geography-specific options */ ///
				geoid(varname) ///
			 ]
	
	if ("`mergedatabase'"!="") {
		if ("`geoid'"=="") local geoid state
		
		if inlist("`geoid'","state","statefips","statename") novarabbrev merge 1:1 `geoid' using `"`geofolder'/state_database_clean"', nogen keepusing(`geoid' _polygonid)
		else {
			di as error "with geography(state), geoid() must be 'state', 'statefips', 'statename', or blank"
			exit 198
		}
		exit
	}
	
	if ("`map'"!="") {
	
		* Avoid having a "No Data" legend item just because DC is missing (it's not visible on the map, nor is it a state)
		sum `spmapvar' if _polygonid==6, meanonly
		if (r(N)==0) {
			* add map restriction
			if (`"`map_restriction'"'!="") local map_restriction `map_restriction' & _polygonid!=6
			else local map_restriction if _polygonid!=6
		}

		spmap `spmapvar' using `"`geofolder'/state_coords_clean"' `map_restriction', id(_polygonid) ///
			`clopt' ///
			`legopt' ///
			legend(pos(5) size(*1.8)) ///
			fcolor(`mapcolors') ndfcolor(`ndfcolor') ///
			oc(black ...) ndo(black) ///
			os(vthin ...) nds(vthin) ///
			`spopt'

		* Save graph
		if (`"`savegraph'"'!="") __savegraph_maptile, savegraph(`savegraph') resolution(`resolution') `replace'
		
	}
	
end

* Save map to file
cap program drop __savegraph_maptile
program define __savegraph_maptile

	syntax, savegraph(string) resolution(string) [replace]
	
	* check file extension using a regular expression
	if regexm(`"`savegraph'"',"\.[a-zA-Z0-9]+$") local graphextension=regexs(0)
	
	* deal with different filetypes appropriately
	if inlist(`"`graphextension'"',".gph","") graph save `"`savegraph'"', `replace'
	else if inlist(`"`graphextension'"',".ps",".eps") graph export `"`savegraph'"', mag(`=round(100*`resolution')') `replace'
	else if (`"`graphextension'"'==".png") graph export `"`savegraph'"', width(`=round(3200*`resolution')') `replace'
	else if (`"`graphextension'"'==".tif") graph export `"`savegraph'"', width(`=round(1600*`resolution')') `replace'
	else graph export `"`savegraph'"', `replace'

end

