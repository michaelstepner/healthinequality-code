{smcl}
{* *! version 1.02  1nov2015}{...}
{vieweralsosee "maptile" "help maptile"}{...}
{viewerjumpto "Naming" "maptile_newgeo##naming"}{...}
{viewerjumpto "Building" "maptile_newgeo##building"}{...}
{viewerjumpto "Installing" "maptile_newgeo##installing"}{...}
{viewerjumpto "Distributing" "maptile_newgeo##distributing"}{...}

{pstd}
{hi:maptile} {hline 2} Instructions for creating a new geography template


{marker naming}{...}
{title:Naming your new geography}

{pstd}
The first step is to choose a name for your new geography (a {it:geoname}).  It may consist of
lowercase letters, numbers, and underscores.


{marker building}{...}
{title:Building your new geography}

{pstd}
A maptile geography consists of four files:

{pstd}1) {it:geoname}_coords.dta
{break}2) {it:geoname}_database.dta

{p 9 9 2}These two datasets are created from a shapefile using {bf:{help shp2dta}}. They are
the same files one would use to create maps using {bf:{help spmap}}.

{p 9 9 2}Typically, one obtains a shapefile for the geographic units of interest by downloading it from the
internet.  For example, the U.S. Census Bureau provides shapefiles of the United States, and Statistics
Canada provides shapefiles of Canada.

{p 9 9 2}After processing the shapefile into Stata format using {bf:{help shp2dta}}, you will have two files. The coordinates file contains 3 variables, _ID _X _Y, which define the shape of the polygons displayed
on the map and link them to a polygon ID.  The database file is simply a crosswalk between a useful geographic
ID (ex: state) and the polygon IDs that are associated with each area.

{p 9 9 2}Some post-processing is often necessary.
You will often have to adjust the database file to assign the variable name and variable type you want to each geographic ID variable, and ensure that it uses the coding that you desire.
You may also want to scale the coordinates file vertically or horizontally to adjust the aspect ratio of the map.
The program {bf:{help mergepoly}} can be used to combine geographic units into aggregated units.

{p 9 9 2}On the {browse "http://michaelstepner.com/maptile/geographies":maptile website}
you can download {it:Creation files} for existing geography templates.  You can use these as a reference to see how those shapefiles were processed.

{pstd}3) {it:geoname}_maptile.ado

{p 9 9 2}This ado-file contains all the customizations for how the map should look and handles any geography-specific options.
It is the template that directs maptile to an spmap command configured to look just right for the map you're creating.

{p 9 9 2}To create your ado-file, you should work from a reference: {bf:demo_maptile.ado} can be downloaded from the
{browse "http://michaelstepner.com/maptile/geographies":maptile website}.  This demo file contains the most
barebones code for a working geography ado-file: it handles all of maptile's options without adding any
geography-specific options.  It is annotated with comments indicating precisely which sections must to be changed.  These
comments are marked with {bf:XX}.  You should avoid changing other sections of the ado-file without
understanding what they are doing.

{p 9 9 2}By following the instructions marked with {bf:XX} in the {bf:demo_maptile.ado} template, you can create a working
geography template in 5-10 minutes without too much knowledge of how ado-files, {cmd:maptile} or {cmd:spmap} work.

{p 9 9 2}{bf:{ul:Advanced}}

{p 9 9 2}If you're ready to delve into the details, you will find that geography templates are
fully extensible and customizable.  You can add arguments to the {cmd:spmap} command in the ado-file in order to
customize the formatting of the generated map.  You can also create new options for users to specify in their
maptile command that are specific to your geography.  Any option added to a maptile command that is not listed
in the {help maptile##syntax:maptile options} will be passed to the geography ado-file.
You utilize this to add new features for customizing your maps.

{p 9 9 2}You can refer to existing geographies' ado-files for examples of geo-specific options and
the code that implements them. The {it:county1990} geography gives users an option to overlay the map with
a thicker line over the state boundaries, visually differentiating state boundaries from county boundaries.
The {it:state} geography uses a geo-specific option to accept a variety of geographic ID variables, that
identify U.S. states in different ways (2-letter abbreviations, full names, 2-digit codes).  

{pstd}4) {it:geoname}_maptile.smcl

{p 9 9 2}This file is not necessary for maptile to run; it is a help file that explains your geography to its
users. It contains a description of the map that will be created and indicates the geographic
ID variable that must exist in the user's dataset.
It also explains any geography-specific options that you have defined.

{p 9 9 2}If you are creating the geography only for your own use, you might decide not to bother creating a help
file.
But if you intend to share your geography with other people, you should write a help file to explain the
relevant information to others who will be using it.

{p 9 9 2}It is easiest to start from a reference: {bf:demo_maptile.smcl} can be downloaded from the
{browse "http://michaelstepner.com/maptile/geographies":maptile website}.
This is simply the help file for the {it:county1990} geography.

{p 9 9 2}The best way to write Stata help files is to open the .smcl file
in a basic text editor (like Notepad) and start editing.  Unfortunately there is no graphical editor for .smcl
files, and the syntax is not particularly elegant.  But if you're not doing anything fancy, it will be
straightforward to just edit the text in the {bf:demo_maptile.smcl} file.

{p 9 9 2}You can open your .smcl file in Stata's Viewer to see how it looks (File > View).  As you edit the
file, save your changes and use the {it:Refresh} button in the Viewer to see how the changes you've made are
rendered.

{p 9 9 2}One word of caution: there is a limit to the length of a line in a .smcl file.  If the lines
get too long in your raw text file they will be chopped off in the Stata Viewer. 
You should intersperse any long paragraphs with line breaks, which the Stata Viewer ignores, in order to keep
lines in the .smcl file relatively short.

{p 9 9 2}To add new formatting to the help file, there are two resources that I use often.
First, all of the syntax for .smcl formatting is documented under {bf:{help smcl}}.
Second, you can look at the help files for existing Stata commands that you use regularly to see how they are
formatted (ex: {help reg:help regress}).  If there is a format that you want to copy, find the corresponding
.sthlp file on your computer and open it in a text editor to see how the formatting was done.  


{marker installing}{...}
{title:Installing your new geography}

{pstd}There are three ways to install a geography.

{phang}1) Zip the 4 geography files listed above into a .zip file.  Point
{bf:{help maptile##cmd_install:maptile_install}} to the .zip file on your computer, and it will
automatically extract the files to the
{bf:{help sysdir:PERSONAL}}/maptile_geographies folder.
You can then use your new geography by running {cmd:maptile} with {opt geo(geoname)}.

{phang}2) Manually place the 4 geography files in the {bf:{help sysdir:PERSONAL}}/maptile_geographies folder
on your computer. You can then use your new geography by running {cmd:maptile} with {opt geo(geoname)}.

{phang}3) Place the 4 geography files together in any folder on your computer.  Then, when you run a
{cmd:maptile} command, you will need to specify {opt geo(geoname)} as well as {opt geofolder(folder_name)}
to direct maptile to look in that folder.

{pstd}If you only have 3 geography files because you've omitted the {it:geoname}_maptile.smcl help file, all
of these installation methods will still work correctly.


{marker distributing}{...}
{title:Distributing your new geography}

{pstd}Once you've done the work to find a shapefile and make a geography template that generates beautiful
maps for a new region or a new set of geographic units, I hope you'll consider sharing your geography
template with the public.  Many geography templates are hosted on the
{browse "http://michaelstepner.com/maptile/geographies":maptile website}, and with your help,
many more will be added.  This repository makes it easy for Stata users to generate maps for a large variety
of places.

{pstd}There are two conditions for hosting a geography on the
{browse "http://michaelstepner.com/maptile/geographies":maptile website}.
First, all of the files in your geography template and all inputs used in creating them 
must be in the public domain, or
subject to an open license that allows free redistribution.  For example, many of the U.S. geographies
were created using shapefiles released to the public domain by the U.S. Census Bureau.  Second, the
geography must include a .smcl help file for users.  This help file should contain a description
of the map, indicate the geographic ID variable required, and explain any geography-specific options.

{pstd}If you'd like to make your geography template available on the
{browse "http://michaelstepner.com/maptile/geographies":maptile website}, please send an
e-mail to Michael Stepner using the contact information listed on the website.
Your e-mail should include two ZIP files.  One ZIP file containing the four geography files.
And one ZIP file containing the raw shapefile that your geography is
derived from and the code you used to transform it into the database and coordinates .dta files.  You can
include them in your e-mail as attachments, or as links to Dropbox or another hosting service if the files
are too large to attach.  Both ZIP files will be posted online.

