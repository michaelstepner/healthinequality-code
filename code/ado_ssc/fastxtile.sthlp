{smcl}
{* *! version 1.22  24jul2014}{...}
{viewerjumpto "Syntax" "fastxtile##syntax"}{...}
{viewerjumpto "Description" "fastxtile##description"}{...}
{viewerjumpto "Options" "fastxtile##options"}{...}
{viewerjumpto "Saved results" "fastxtile##saved_results"}{...}
{viewerjumpto "Author" "fastxtile##author"}{...}
{viewerjumpto "Acknowledgements" "fastxtile##acknowledgements"}{...}
{viewerjumpto "Also see" "fastxtile##also-see"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:fastxtile} {hline 2}}Drop in replacement for xtile, which runs significantly faster on large datasets{p_end}
{p2colreset}{...}

{marker syntax}{title:Syntax}

{phang}
Create variable containing quantile categories

{p 8 15 2}
{cmd:fastxtile}
{it:newvar} {cmd:=} {it:{help exp}}
{ifin}
{weight}
[{cmd:,} {it:options}]


{synoptset 22 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Main}
{synopt :{opt n:quantiles(#)}}number of quantiles; default is
{cmd:nquantiles(2)}{p_end}
{synopt :{opth c:utpoints(varname)}}use values of {it:varname} as cutpoints
{p_end}
{synopt :{opt alt:def}}use alternative formula for calculating
percentiles{p_end}

{syntab :Additions in fastxtile}
{synopt :{opth cutv:alues(numlist)}}use values of {it:numlist} as cutpoints; {it:numlist} must be strictly ascending{p_end}
{synopt :{opth randvar(varname)}}use {it:varname} to sample observations when computing quantile boundaries{p_end}
{synopt :{opt randcut(#)}}upper bound on {cmd:randvar()} used to cut the sample; default is {cmd:randcut(1)}{p_end}
{synopt :{opt randn(#)}}number of observations to sample when computing quantile boundaries{p_end}
{synoptline}

{p 4 6 2}
{opt aweight}s, {opt fweight}s, and {opt pweight}s are allowed
(see {manhelp weight U:11.1.6 weight}), except when {opt altdef}, {opt cutpoints(varname)} or {opt cutvalues(numlist)}
are specified, in which case no weights are allowed.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt fastxtile} is a drop in replacement for {manhelp xtile D}.  It has the same syntax and produces identical results, but has been optimized to be more computationally efficient.  The
difference in running time is substantial in large datasets.

{pstd}
It also supports computing the quantile boundaries using a random sample of the data.
This further increases the speed, but generates approximate quantiles due to sampling error.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}{opt nquantiles(#)} specifies the number of quantiles.
It computes percentiles corresponding to percentages 100*k/m
for k=1, 2, ..., m-1, where m={it:#}.  For example, {cmd:nquantiles(10)}
requests that the 10th, 20th, ..., 90th percentiles be computed.  The default
is {cmd:nquantiles(2)}; i.e., the median is computed.

{phang}{opt altdef} uses an alternative formula for calculating percentiles.
The default method is to invert the empirical distribution function by using
averages, where the function is flat (the default is the same method used by 
{cmd:summarize}; see {manhelp summarize R}).
The alternative formula uses an interpolation method.  Weights cannot be used
when {opt altdef} is specified.

{phang}{opth cutpoints(varname)} requests that {opt fastxtile}
use the values of {it:varname}, rather than quantiles, as cutpoints for the
categories.  All values of {it:varname} are used, regardless of any {opt if}
or {opt in} restriction. This option cannot be combined with any other options.

{dlgtab:Additions in fastxtile}

{phang}{opth cutvalues(numlist)} specifies a list of values to be used as
cutpoints for the categories.  The list must be ascending and contain no
repeated values. This option cannot be combined with any other options.

{phang}{opth randvar(varname)} requests that {it:varname} be used to select a
sample of observations when computing the quantile boundaries.  Sampling increases
the speed of {opt fastxtile}, but generates approximate quantiles due to sampling error.
It is possible to omit this option and still perform random sampling from U[0,1]
as described below in {opt randcut(#)} and {opt randn(#)}.

{phang}{opt randcut(#)} specifies the upper bound on the variable contained
in {opt randvar(varname)}. Quantile boundaries are approximated using observations for which
{opt randvar()} <= #.  If no variable is specified in {opt randvar()},
a standard uniform random variable is generated. The default is {cmd:randcut(1)}.
This option cannot be combined with {opt randn(#)}.

{phang}{opt randn(#)} specifies an approximate number of observations to sample when
computing the quantile boundaries. Quantile boundaries are approximated using observations
for which a uniform random variable is <= #/N. The exact number of observations
sampled may therefore differ from #, but it equals # in expectation. When this option is
combined with {opth randvar(varname)}, {it:varname} ought to be distributed U[0,1].
Otherwise, a standard uniform random variable is generated. This option cannot be combined
with {opt randcut(#)}.


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:fastxtile} saves the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 10 14 2:Scalars}{p_end}
{synopt:{cmd:r(r}{it:#}{cmd:)}}value of {it:#}-requested percentile{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(n)}}number of sampled observations when computing quantile boundaries{p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Michael Stepner{p_end}
{pstd}stepner@mit.edu{p_end}


{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}The {cmd:fastxtile} code and documentation are based on the built-in xtile command.

{pstd}Raj Chetty provided the impetus for this program, and the idea of using random sampling to generate
approximate quantiles quickly in large datasets.

{pstd}Laszlo Sandor suggested the option {opt randn()}, pointing out that the expected error in
the size of the bins is proportional to the sample size, not the sampling rate.


{marker also-see}{...}
{title:Also see}

{psee}
Manual:  {manlink D pctile}

{psee}
{space 2}Help:  {manhelp pctile D}
{p_end}
