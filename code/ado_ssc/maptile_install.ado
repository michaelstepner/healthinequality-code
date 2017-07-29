*! version 1.02  1nov2015  Michael Stepner, stepner@mit.edu

/*** Unlicence (abridged):
This is free and unencumbered software released into the public domain.
It is provided "AS IS", without warranty of any kind.

For the full legal text of the Unlicense, see <http://unlicense.org>
*/

* Why did I include a formal license? Jeff Atwood gives good reasons:
*  http://blog.codinghorror.com/pick-a-license-any-license/


program define maptile_install
	version 11
	
	syntax using/, [replace]
	
	* Ensure that the directories exist
	cap mkdir "`c(sysdir_personal)'"
	cap mkdir "`c(sysdir_personal)'maptile_geographies"
	
	* Copy/download the specified geography
	qui copy `"`using'"' `"`c(sysdir_personal)'maptile_geographies/temp.zip"', replace
	
	* Change to the target directory
	local cwd `c(pwd)'
	di as text ""
	cd `"`c(sysdir_personal)'maptile_geographies"'
	
	* Extract the geography
	unzipfile temp.zip, `replace'
	erase temp.zip

	* Change back to original directory
	qui cd `"`cwd'"'
	
	* Suggest reading help file
	di as text ""
	di as text "To see the help file of the geography template, run:"
	di as text "    {cmd:maptile_geohelp} {it:geoname}"
	
end
