*! version 1.02  1nov2015  Michael Stepner, stepner@mit.edu

/*** Unlicence (abridged):
This is free and unencumbered software released into the public domain.
It is provided "AS IS", without warranty of any kind.

For the full legal text of the Unlicense, see <http://unlicense.org>
*/

* Why did I include a formal license? Jeff Atwood gives good reasons:
*  http://blog.codinghorror.com/pick-a-license-any-license/


program define maptile_geohelp
	version 11
	
	set more off
	
	syntax name(name=geography id="geoname") [, geofolder(string)]
	
	* Set default directory
	if (`"`geofolder'"'=="") local geofolder `c(sysdir_personal)'maptile_geographies
	
	* Check that the geography is installed
	cap confirm file `"`geofolder'/`geography'_maptile.ado"'
	if (_rc!=0) {
		di as error "geography(`geography') specified, but it is not installed."
		
		if ("`geofolder'"=="`c(sysdir_personal)'maptile_geographies") di as text `"To see a list of installed geographies run: {stata maptile_geolist}"'
		else {
			di as text `"To see a list of installed geographies run:"'
			di as text `"   {stata maptile_geolist, geofolder(`geofolder')}"'
			di as text ""
		}
		exit 198
	}
	
	* Check that it has a help file
	cap confirm file `"`geofolder'/`geography'_maptile.smcl"'
	if (_rc!=0) {
		di as error `"{bf:`geography'} geography exists, but it does not have a help file. There is no file:"'
		di as text `" `geofolder'/`geography'_maptile.smcl"'
		exit 198
	}

	* Display the help file	
	view `"`geofolder'/`geography'_maptile.smcl"'

end
