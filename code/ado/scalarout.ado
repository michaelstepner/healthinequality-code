program define scalarout

	syntax using, num(real) id(string) [fmt(string) replace]
	
	* Replace or Append?
	if ("`replace'"=="replace") local overwrite replace
	else local overwrite append
	
	* Open file
	tempname file
	file open `file' `using', write text `overwrite'
	
	* Write CSV line
	if (substr("`fmt'",-1,1)=="c") file write `file' `""`id'",""' `fmt' (`num') `"""' _n
	else file write `file' `""`id'","' `fmt' (`num') _n
	
	* Close file
	file close `file'

end
