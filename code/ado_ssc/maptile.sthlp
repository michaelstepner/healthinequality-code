{smcl}
{* *! version 1.02  1nov2015}{...}
{vieweralsosee "spmap" "help spmap"}{...}
{viewerjumpto "Syntax" "maptile##syntax"}{...}
{viewerjumpto "Description" "maptile##description"}{...}
{viewerjumpto "Installing geographies" "maptile##installgeo"}{...}
{viewerjumpto "Using geographies" "maptile##usegeo"}{...}
{viewerjumpto "Making new geographies" "maptile##makegeo"}{...}
{viewerjumpto "Options" "maptile##options"}{...}
{viewerjumpto "Examples" "maptile##examples"}{...}
{viewerjumpto "Saved results" "maptile##saved_results"}{...}
{viewerjumpto "Author" "maptile##author"}{...}
{viewerjumpto "Acknowledgements" "maptile##acknowledgements"}{...}
{title:Title}

{pstd}
{hi:maptile} {hline 2} Categorical maps


{marker syntax}{title:Syntax}

{pstd} Map a variable

{p 8 15 2}
{cmd:maptile}
{varname} {ifin}{cmd:,}
 {cmdab:geo:graphy(}{it:{help maptile##usegeo:geoname}}{cmd:)} [{it:options}]


{pstd} Helper programs:
{bf:{help maptile##cmd_install:maptile_install}},
{bf:{help maptile##cmd_geolist:maptile_geolist}},
{bf:{help maptile##cmd_geohelp:maptile_geohelp}}


{synoptset 35 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Main}
{synopt :{cmdab:geo:graphy(}{it:{help maptile##usegeo:geoname}}{cmd:)}}geographic template to map{p_end}
{synopt :{it:{help maptile##geo_options:geo_options}}}options specific to the geographic template being used{p_end}
{synopt :{cmdab:twopt(}{it:{help twoway_options}}{cmd:)}}pass {help twoway_options:twoway graph options} to graph command{p_end}

{syntab :Bins}
{synopt :{opt n:quantiles(#)}}number of quantiles (color bins); default is {bf:6}{p_end}
{synopt :{opth cutp:oints(varname)}}use values of {it:varname} as cutpoints{p_end}
{synopt :{opth cutv:alues(numlist)}}use values of {it:numlist} as cutpoints{p_end}

{syntab :Colors}
{synopt :{opt rev:color}}reverse color order{p_end}
{synopt :{opt prop:color}}space colors proportionally to the data{p_end}
{synopt :{opt shrinkc:olorscale(#)}}shrink color spectrum to fraction of full size; default is {bf:1}{p_end}
{synopt :{cmdab:rangec:olor(}{it:{help colorstyle} {help colorstyle}}{cmd:)}}manually specify color spectrum boundaries{p_end}
{synopt :{cmdab:fc:olor(}{it:{help spmap##color:spmap_colorlist}}{cmd:)}}manually specify color scheme, instead of using a color spectrum{p_end}
{synopt :{opth ndf:color(colorstyle)}}color for areas with missing data{p_end}

{syntab :Legend}
{synopt :{opt legd:ecimals(#)}}number of decimals to display in legend{p_end}
{synopt :{cmdab:legf:ormat(}{it:{help format:%fmt}}{cmd:)}}numerical format to display in legend{p_end}

{syntab :Output}
{synopt :{opt savegraph(filename)}}save map to file; format automatically detected from file extension{p_end}
{synopt :{opt replace}}overwrite the file if it already exists{p_end}
{synopt :{opt res:olution(#)}}scale the saved map image by a proportion; default is {bf:1}{p_end}

{syntab :Advanced}
{synopt :{cmdab:mapif(}{it:condition}{cmd:)}}restrict the map to a subset of areas{p_end}
{synopt :{cmdab:spopt(}{it:{help spmap:spmap_options}}{cmd:)}}pass spmap options to graph command{p_end}
{synopt :{opt geofolder(folder_name)}}folder containing maptile geographies; default is {bf:{help sysdir:PERSONAL}}/maptile_geographies{p_end}
{synopt :{opt hasdatabase}}dataset already contains the polygon {it:{help spmap##basemap2:idvar}}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:maptile} makes it easy to map a variable in Stata.  It generates choropleth maps, where each area is shaded according to the value of the variable being plotted.
By default, {cmd:maptile} divides the geographic units into equal-sized bins (corresponding to quantiles of the plotted variable), then colors the bins in increasing intensity.

{pstd}
To generate any particular map, {cmd:maptile} uses a {it:geography}, which is a template for that map.
These need to be {help maptile##installgeo:downloaded and installed}. If no geography currently exists for the region you want to map, you can {help maptile_newgeo:create a new one}.

{pstd}
{cmd:maptile} requires {bf:{help spmap:spmap}} to be installed, and is largely a convenient interface for using {cmd:spmap}.
As its help file states, "{cmd:spmap} gives the user full control over the formatting of almost every map element, thus allowing the production of highly customized maps".
When using {cmd:maptile}, most of these customizations are stored away in the geography template.
As a result, the syntax for making highly customized maps using {cmd:maptile} can be very simple.
Additionally, the geography templates can be easily shared and used by others.


{marker installgeo}{...}
{title:Installing geographies}

{pstd}
{cmd:maptile} geography templates are distributed as .ZIP files.  Many are available {browse "http://michaelstepner.com/maptile/geographies":from maptile's website}.

{marker cmd_install}{...}
{pstd}
1) To install a new geography template automatically, use:

{p 12 19 2}
{cmd:maptile_install} using {it:URL}{c |}{it:filename} [, {opt replace}]


{pmore}
When you point {cmd:maptile_install} to a URL or local ZIP file, it will automatically extract the files to the {bf:{help sysdir:PERSONAL}}/maptile_geographies folder. That is where {cmd:maptile} looks for geography templates by default.

{pmore}If you add {opt replace}, it will automatically overwrite existing files with ones from the ZIP file.

{pstd}
2) Alternatively, you can install a geography manually.

{pmore}Simply extract the geography ZIP file to any folder on your computer.
Then direct {cmd:maptile} to look in that folder using the {opt geofolder(folder_name)} option.


{marker usegeo}{...}
{title:Using geographies}

{pstd}1) Specify the geography name ({it:geoname})

{p 9 9 2}Each time you run {cmd:maptile} you need to specify the name of a geography template to use with the option {opt geo:graphy(geoname)}.

{marker cmd_geolist}{...}
{p 9 9 2}To list the names of currently installed geographies, use:

{p 15 22 2}
{cmd:maptile_geolist} [, {opt geofolder(folder_name)}]

{p 9 9 2}Running {cmd:maptile_geolist} without any options will list geographies in the {bf:{help sysdir:PERSONAL}}/maptile_geographies folder, which is where {cmd:maptile} loads geographies from automatically.


{marker geoid}{...}
{pstd}2) Ensure your dataset contains the correct geographic ID variable

{p 9 9 2}Your dataset must contain a geographic identifier variable, which associates each observation with an area on the map.

{p 9 9 2}Each geography will expect a specific geographic ID variable. For example, the geography for U.S. states might require a variable named "state" containing 2-letter state abbreviations.
The required geographic ID variable will be indicated in the geography's help file.

{marker cmd_geohelp}{...}
{p 9 9 2} To see a geography's help file, use:

{p 15 22 2}
{cmd:maptile_geohelp} {it:geoname} [, {opt geofolder(folder_name)}]


{marker geo_options}{...}
{pstd}{it:3) Use any geography-specific options desired (geo_options)}

{p 9 9 2}Some geographies provide additional options which you can add to the {cmd:maptile} command.

{p 9 9 2}For example, a geography may provide an option that lets the user choose among a variety of geographic ID variables.
As another example, some geographies of the United States provide an option to place a heavier line on state borders.

{p 9 9 2}These additional options will be detailed in the {help maptile##cmd_geohelp:geography's help file}.


{marker makegeo}{...}
{title:Making new geographies}

{pstd}{help maptile_newgeo:Instructions are provided here.}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}{opt geo:graphy(geoname)} specifies the name of the geography template that maptile will use to create the map.
The geography template must be {help maptile##installgeo:installed on your computer}.
Your dataset must contain the {help maptile##geoid:correct geographic ID variable} for the specified geography template.

{phang}{it:{help maptile##geo_options:geo_options}}:

{pmore}Some geographies provide additional options which you can add to the {cmd:maptile} command.
These additional options will be described in the {help maptile##cmd_geohelp:geography's help file}.

{phang}{cmdab:twopt(}{it:{help twoway_options}}{cmd:)} passes {help twoway_options:twoway options} through to the graph command.
These can be used to control the graph {help title options:titles},
{help legend option:legends}, etc.
See {help maptile##example_formatting:Example 3} ("Formatting") for some demonstrations.

{pmore}{help twoway_options:twoway options} are supported by all twoway graphs, and are typically added directly to the command generating the graph.
But with {cmd:maptile} all {help twoway_options:twoway options} must be enclosed within {cmd:twopt()}.

{pmore}Other formatting options are available through {cmd:spmap} using {cmdab:spopt(}{it:{help spmap:spmap_options}}{cmd:)} {help maptile##spopt:[jump down]}.
Note that technically all twoway options are passed to {cmd:spmap}, so enclosing them in {cmd:spopt()} is equivalent to enclosing them in {cmd:twopt()}.

{dlgtab:Bins}

{phang}{opt n:quantiles(#)} specifies the number of equal-sized color bins to be created.
The default is {bf:6}. The bins created match the results of {bf:{help xtile}}.
This option cannot be combined with {opt cutpoints()} or {opt cutvalues()}.

{pmore}
It is possible that fewer bins are created than specified, for example if the variable being mapped takes fewer unique values than the number of bins requested.
For more information, see the technical note on non-unique quantiles in the {manlink D pctile} manual.

{phang}{opth cutp:oints(varname)} causes {cmd:maptile} to use the values of {it:varname} as cutpoints for the color bins.
All values of {it:varname} are used, regardless of any {opt if} or {opt in} restriction.
This option cannot be combined with {opt nquantiles()} or {opt cutvalues()}.

{pmore}This option can be used with a variable created by {bf:{help pctile}} to fix a set of bins across multiple maps.
For example, when mapping a variable for numerous subpopulations (ex: wages by race) it can be desirable to hold the bins fixed in order to see an absolute comparison between the groups.
See {help maptile##example_comparisons_groups:Example 5} ("Comparisons between groups") for a click-through illustration.

{phang}{opth cutv:alues(numlist)} specifies a list of values to be used as cutpoints for the color bins.  The list must be ascending and contain no repeated values. This option cannot be combined with {opt nquantiles()} or {opt cutpoints()}.

{dlgtab:Colors}

{phang}{opt rev:color} reverses the order of the colors.
By default, bins are colored in increasing intensity, from light yellow for the lowest values to dark red for the highest values. Specifying {opt revcolor} reverses this, assigning dark red to the lowest bins and light yellow to the highest bins.

{phang}{opt prop:color} spaces the colors used for each bin proportionally to the data, using the median values of each bin.

{pmore}Consider a color spectrum located along [0,1]. Light yellow is located at 0 and dark red is located at 1.
The lowest bin always takes the light yellow located at 0, the highest bin always takes the dark red at 1.
By default, the middle bins are colored using elements of the color spectrum that are equally spaced between [0,1].
Specifying {opt propcolor} causes {cmd:maptile} to calculate the median value of each bin, and color the middle bins proportionally to the distances between them.
For example, if the bins are mostly clustered near the bottom and top of the range, then they will be mostly yellow and red, without much orange in the middle.

{pmore}There is nothing objective about the distances on the color spectrum.  The effect of {opt propcolor} is that bins whose data are relatively close together will look relatively similar in color.

{phang}{opt shrinkc:olorscale(#)} shrinks the color spectrum to a fraction of its full size. # must be between 0 and 1.

{pmore}Consider a color spectrum located along [0,1]. Light yellow is located at 0 and dark red is located at 1.
Specifying {bf:shrinkcolorscale(}0.5{bf:)} would cause {cmd:maptile} to color the bins using the spectrum from [0.25,0.75], reducing the variation in color.

{pmore}
This can be desirable when creating two maps of related variables where the range or variance of values plotted on one map is much smaller than on the other map.
Reducing the variation between the colors on one map visually indicates that the variation in the values being depicted is smaller.

{pmore}There is nothing objective about the distances on the color spectrum.
The effect of {opt shrinkcolorscale()} is that the colors used become relatively more similar to one another.

{phang}{cmdab:rangec:olor(}{it:{help colorstyle} {help colorstyle}}{cmd:)} specifies the color spectrum boundaries. These are the colors of the lowest bin and the highest bin.
All bins between the lowest and the highest will take colors on the spectrum between these two boundaries.
By default, the boundary colors are {it:yellow*0.1} and {it:red*1.65}.

{phang}{cmdab:fc:olor(}{it:{help spmap##color:spmap_colorlist}}{cmd:)} specifies the color scheme, instead of using a color spectrum.
The color scheme can either be a {help colorstyle:colorstyle list} or an {help spmap##color:{bf:spmap} color scheme}. This option cannot be combined with {opt revcolor}, {opt propcolor}, {opt shrinkcolorscale()} or {opt rangecolor()}.

{phang}{opth ndf:color(colorstyle)} specifies the color for areas with missing data.
The default is a light grey, {it:gs12}.

{dlgtab:Legend}

{phang}{opt legd:ecimals(#)} specifies the number of decimals to display in legend entries.
By default, the format of the numbers in the legend varies automatically with the magnitude of the data.
This option cannot be combined with {opt legformat()}.

{phang}{cmdab:legf:ormat(}{it:{help format:%fmt}}{cmd:)} specifies a numerical format for the numbers in the legend. By default, the format varies automatically with the magnitude of the data.
This option cannot be combined with {opt legdecimals()}.

{dlgtab:Output}

{phang}{opt savegraph(filename)} saves the map to a file.
The format is automatically detected from the extension specified [ex: {bf:.gph .png .eps}],
and either {cmd:graph save} or {cmd:graph export} is run.
If no file extension is specified {bf:.gph} is assumed.

{pmore}
It is usually preferable to save maps in a bitmap format ({bf:.png} or {bf:.tiff}).
Many maps have an enormous file size when saved in a vector image format ({bf:.ps .eps .wmf .emf .pdf}).
This happens because the map has very detailed information on the shapes of complicated borders and no details are lost when saving in a vector format.

{phang}{opt replace} specifies that the file being saved should overwrite any existing file.

{phang}{opt res:olution(#)} scales the saved map image by the specified factor, which must be greater than 0. The default scaling factor is {bf:1}.

{dlgtab:Advanced}

{phang}{cmdab:mapif(}{it:condition}{cmd:)} shows only the subset of areas selected by the if {it:condition} on the map.
It is important to understand how {opt mapif()} differs from an {bf:if} or {bf:in} statement.

{pmore}
An {bf:if} or {bf:in} statement selects what data is {it:used}. Observations excluded are treated as if the data is missing. They will therefore show up in grey on the map, and will not be included when computing quantiles.

{pmore}
{opt mapif()} selects what areas are {it:shown}, without affecting what data is used.
The quantiles are computed using all non-missing observations, whether or not they are shown on the map.
To additionally exclude the hidden areas from being used when calculating quantiles, it is necessary to repeat the {it:condition} using both {bf:if} and {opt mapif()}.

{pmore}These differences are demonstrated in {help maptile##example_subsets_regions:Example 4} ("Subsets of regions").

{marker spopt}{...}
{phang}{cmdab:spopt(}{it:{help spmap:spmap_options}}{cmd:)} passes {help spmap:spmap options} through to the {cmd:spmap} graph command.
In addition to the standard {help twoway_options:twoway options}, {cmd:spmap} provides specialized options to customize the appearance of the generated map.
See {help maptile##example_binning:Example 1} ("Binning") for a demonstration which alters the appearance of the legend.

{pmore}Note that {cmd:spmap} supports {help twoway_options:twoway options}, so enclosing twoway options in {cmd:twopt()} or {cmd:spopt()} are fully equivalent.

{phang}{opt geofolder(folder_name)} indicates the folder where the maptile geography template is located.
By default, {cmd:maptile} installs geographies to {bf:{help sysdir:PERSONAL}/maptile_geographies} and loads them from that directory.
However, you may decide to keep the geography template files elsewhere on your computer.

{phang}{opt hasdatabase} specifies that the polygon ID variable ({it:{help spmap##basemap2:idvar}}) should not be merged onto the dataset, as it already exists in the dataset.
Manually merging the polygon ID variable onto the dataset can save a bit of processing time when creating numerous maps using the same geography.
But typically the gains are minimal.


{marker examples}{...}
{title:Examples}

{pstd}Install a geography template for U.S. States.{p_end}
{phang2}. {stata `"maptile_install using "http://files.michaelstepner.com/geo_state.zip""'}{p_end}

{pstd}Load state-level 1980 U.S. Census data.{p_end}
{phang2}. {stata sysuse census}{p_end}

{pstd}Rename the geographic ID vars to match the variable names required by the {it:state} geography template.{p_end}
{phang2}. {stata rename (state state2) (statename state)}{p_end}


{marker example_binning}{...}
{pstd}{bf:Example 1: Binning}

{pstd}Plot the percentage of the population that are small children in each state.{p_end}
{phang2}. {stata gen babyperc=poplt5/pop*100}{p_end}
{phang2}. {stata maptile babyperc, geo(state)}{p_end}

{pstd}Small children are most common in the Western US.
But the bin of states with the highest percentage of children is much higher than the other 5 bins.{p_end}

{pstd}Try coloring each bin proportionally to its median value.{p_end}
{phang2}. {stata maptile babyperc, geo(state) propcolor}{p_end}
{phang2}. {stata matrix list r(midpoints)}{p_end}

{pstd}Most US states have a fairly similar proportion of children, but the highest group stands out.{p_end}

{pstd}Instead of grouping the states into quantile bins, now try coloring states individually and displaying a full spectrum in the legend.{p_end}
{phang2}. {stata maptile babyperc, geo(state) spopt(legstyle(3)) cutvalues(5(0.5)13)}{p_end}

{pstd}The proportion of children is very homogeneous across states, with Utah as a major exception.
Three other states also stand out a bit from the rest.{p_end}


{pstd}{bf:Example 2: Coloring}

{pstd}How do marriage rates vary across the US?{p_end}
{phang2}. {stata gen marriagerate=marriage/pop*100}{p_end}
{phang2}. {stata maptile marriagerate, geo(state)}{p_end}

{pstd}Quickly investigate that wide top bin (1.28-14.28).{p_end}
{phang2}. {stata sum marriagerate, d}{p_end}
{phang2}. {stata list if marriagerate>2}{p_end}
{phang2}. {stata maptile marriagerate, geo(state) propcolor}{p_end}

{pstd}Nevada is a huge outlier (because so many non-residents go to Las Vegas and get married).
But more broadly, the bins are quite evenly spaced.{p_end}

{pstd}Highlight the places with low marriage rates by reversing the colors, so that states with low marriage rates are dark red.{p_end}
{phang2}. {stata maptile marriagerate, geo(state) revcolor}{p_end}

{pstd}Let's make the colors a little splashier.  Try the "Reds" color scheme built into {cmd:spmap}.{p_end}
{phang2}. {stata maptile marriagerate, geo(state) nq(4) fcolor(Reds)}{p_end}

{pstd}It could be splashier still. Let's manually definine a pink color spectrum.{p_end}
{phang2}. {stata maptile marriagerate, geo(state) rangecolor(pink*0.1 pink*1.2)}{p_end}


{marker example_formatting}{...}
{pstd}{bf:Example 3: Formatting}

{pstd}Plot the percentage of the population living in an urban area{p_end}
{phang2}. {stata gen urbanperc=popurban/pop*100}{p_end}
{phang2}. {stata maptile urbanperc, geo(state)}{p_end}

{pstd}Let's add a legend title.{p_end}
{phang2}. {stata maptile urbanperc, geo(state) legd(0) twopt(legend(title("Percent Urban" "Population")))}{p_end}

{pstd}Alternatively, we can label the quantiles from Most Rural to Most Urban.{p_end}
{phang2}. {stata maptile urbanperc, geo(state) twopt(legend(lab(2 "Most Rural") lab(3 "") lab(4 "") lab(5 "") lab(6 "") lab(7 "Most Urban")))}{p_end}

{pstd}Note that numbering of legend entries starts at 2.{p_end}

{pstd}We can also give the map an explanantory title.{p_end}
{phang2}. {stata maptile urbanperc, geo(state) legd(0) twopt(title("Percentage of State Population Living in Urban Areas"))}{p_end}


{marker example_subsets_regions}{...}
{pstd}{bf:Example 4: Subsets of regions}

{pstd}This example illustrates the differences between using {opt if} and {opt mapif()} to select a subset of areas.{p_end}

{pstd}Start by creating a map of the median age in each state.{p_end}
{phang2}. {stata maptile medage, geo(state)}{p_end}

{pstd}Suppose we want to focus on the Northeast.  Using an {opt if} statement controls what data are {bf:used}.{p_end}
{phang2}. {stata maptile medage if region==1, geo(state)}{p_end}

{pstd}All the observations outside the Northeast were treated as if they were missing.
Only the Northeastern data was used to compute the quantiles.{p_end}

{pstd}Now let's zoom in on the Northeast.  Using {opt mapif()} controls what data are {bf:shown}.{p_end}
{phang2}. {stata maptile medage, geo(state) mapif(region==1)}{p_end}

{pstd}Only the Northeast is shown on the map.
But all observations were used to compute the quantiles.{p_end}

{pstd}To generate a map of only Northeastern data, we need to combine an {opt if} statement with {opt mapif()}{p_end}
{phang2}. {stata maptile medage if region==1, geo(state) mapif(region==1)}{p_end}

{pstd}This map shows the Northeast, categorized using the quantiles of the Northeastern states.{p_end}


{marker example_comparisons_groups}{...}
{pstd}{bf:Example 5: Comparisons between groups}

{pstd}Load a dataset of US mortality rates by state and race.{p_end}
{phang2}. {stata "use http://files.michaelstepner.com/USmortality_by_state_race.dta"}{p_end}

{pstd}Look at how the mortality rates of white Americans and black Americans vary across states.{p_end}
{phang2}. {stata maptile mort_white, geo(state) twopt(name(white))}{p_end}
{phang2}. {stata maptile mort_black, geo(state) twopt(name(black))}{p_end}

{pstd}Comparing the two maps provides a {bf:relative} comparison of the two groups.
The first map shows where white Americans have high mortality rates relative to other
white Americans. The second map shows how black Americans fare relative to other black Americans.
Looking at the two maps together, we can see that black Americans have relatively high mortality in the same states as white Americans.{p_end}

{pstd}But we might also be interested in an {bf:absolute} comparison between the two groups.
How does the mortality of black Americans compare to that of white Americans?
To perform an absolute comparison, we need to hold the bins fixed.{p_end}

{pstd}Generate a variable containing the quantiles of the distribution of white mortality:{p_end}
{phang2}. {stata pctile mortwhite_breaks=mort_white, nq(6)}{p_end}

{pstd}Map both white and black mortality using the same bins:{p_end}
{phang2}. {stata maptile mort_white, geo(state) twopt(name(whiteABS)) cutp(mortwhite_breaks)}{p_end}
{phang2}. {stata maptile mort_black, geo(state) twopt(name(blackABS)) cutp(mortwhite_breaks)}{p_end}

{pstd}In nearly every state, black Americans have higher mortality rates than white Americans.{p_end}


{marker saved_results}{...}
{title:Saved Results}

{pstd}
{cmd:maptile} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(breaks)}}list of cut points between bins{p_end}
{synopt:{cmd:r(midpoints)}}median value within each group ({it:if {opt propcolor} specified}){p_end}


{marker author}{...}
{title:Author}

{pstd}Michael Stepner{p_end}
{pstd}stepner@mit.edu{p_end}


{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}{cmd:maptile} was built on the shoulders of giants.  Maps are generated using
{cmd:spmap}, written by Maurizio Pisati. The geography template shapefiles were made using
{cmd:shp2dta}, written by Kevin Crow, as well as {cmd:mergepoly}, written by Robert Picard.
