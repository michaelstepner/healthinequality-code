*! version 1.02  1nov2015  Michael Stepner, stepner@mit.edu

/*** Unlicence (abridged):
This is free and unencumbered software released into the public domain.
It is provided "AS IS", without warranty of any kind.

For the full legal text of the Unlicense, see <http://unlicense.org>
*/

* Why did I include a formal license? Jeff Atwood gives good reasons:
*  http://blog.codinghorror.com/pick-a-license-any-license/


program define maptile_geolist
	version 11
	
	set more off
	
	syntax [, geofolder(string)]
	
	* Set default directory
	if (`"`geofolder'"'=="") local geofolder `c(sysdir_personal)'maptile_geographies
	
	* Check that the specified directory exists (based on confirmdir.ado code by Dan Blanchette)
	local current_dir `"`c(pwd)'"'
	quietly capture cd `"`geofolder'"'
	if _rc!=0 {
		di as error `"unable to load directory `geofolder'"'
		exit 198
	}
	quietly cd `"`current_dir'"'
	

	* Store all relevant files in local
	local geos : dir `"`geofolder'"' files "*_maptile.ado"
	
	* Output geo_names
	if (`"`geos'"'=="") di as text "no geography templates found"
	else {
		di `: subinstr local geos "_maptile.ado" "   ", all'
	}
	
end
