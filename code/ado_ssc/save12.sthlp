{smcl}
{* *! version 1.0.0  9oct2016}{...}
{viewerjumpto "Syntax" "save12##syntax"}{...}
{viewerjumpto "Description" "save12##description"}{...}
{viewerjumpto "Options" "save12##options"}{...}
{viewerjumpto "Author" "save12##author"}{...}
{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:save12} {hline 2}}Save Stata 12 dataset{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Save data in memory to file in Stata 12 format

{p 8 16 2}
{cmd:save12}
{it:{help filename}}
[{cmd:,} {it:options}]


{synoptset 17}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt nol:abel}}omit value labels from the saved dataset{p_end}
{synopt :{opt replace}}overwrite existing dataset{p_end}
{synopt :{opt all}}save {cmd:e(sample)} with the dataset; programmer's
option{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:save12} provides a consistent command to save datasets in Stata 12 format,
which facilitates collaboration between computers using different versions
of Stata. Stata 12 and later versions of Stata can produce datasets in Stata 12
format, but not using the same command. {cmd:save12} assures that the same code
shared across multiple computers will save datasets in Stata 12 format,
regardless of the host computer's version of Stata.

{pstd}
{opt save12} stores the dataset currently in memory on disk in Stata 12 format
under the name {it:{help filename}}.  If {it:filename} is not specified, the
name under which the data were last known to Stata ({cmd:c(filename)}) is used.
If {it:filename} is specified without an extension, {cmd:.dta} is used.  If your
{it:filename} contains embedded spaces, remember to enclose it in double
quotes.

{pstd}
{opt save12} has been tested to work in Stata 12, 13 and 14. It will continue to
work correctly in future versions of Stata so long as they maintain the same
{bf:{help saveold}} syntax as Stata 14, with an option of {opt version(12)}.
Stata 11 can read datasets in Stata 12 format, but cannot write datasets in
Stata 12 format.


{marker options}{...}
{title:Options}

{phang}
{opt nolabel} omits value labels from the saved dataset.
The associations between variables and value-label names, however,
are saved along with the dataset label and the variable labels.

{phang}
{opt replace} permits {opt save12} to overwrite an existing dataset.

{phang}
{opt all} is for use by programmers.  If specified, {cmd:e(sample)} will
be saved with the dataset.  You could run a regression; {cmd:save12 mydata, all};
{cmd:drop _all}; {cmd:use mydata}; and {cmd:predict yhat if e(sample)}.


{marker author}{...}
{title:Author}

{pstd}Michael Stepner{p_end}
{pstd}stepner@mit.edu{p_end}
