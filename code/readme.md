# Coding Style Guide
### Author: Michael Stepner

This document explains the conventions we follow throughout the code in this project.

It was originally developed to serve as a reference to collaborators working on the code—ensuring that our work followed a consistent set of conventions. This document can also serve as a reference to people working to understand or adapt the code in this project, or to people adapting these methods and conventions for use in another project.

If you look carefully at our code, you will discover that not all of the code follows all of the guidelines described below. These discrepancies occur for two reasons. First, many of these guidelines were developed and chosen over the course of the project, and not all of the code was brought up to date with the latest guidelines. Second, these guidelines serve as strong suggestions that should be followed in most cases, but there are sometimes well thought out reasons to deviate from them.

## License

This document is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/). You can adapt or redistribute the text for any non-commercial purpose, so long as you provide [attribution](https://creativecommons.org/licenses/by-nc/4.0/).

## Motivation

There are many ways to organize all the code, data, documentation, and results for a project.

When you're working alone on a short-lived project (for example: a problem set or a master's thesis), it doesn't matter that much how you organize your code and your files. Even if your code and data are scattered, you can remember for the duration of the project where you got things from, where you stored them, and how everything connects together.

But with **many people** collaborating on a project **over a long period**, the incovenience of learning and following a set of coding conventions pales in comparison to the confusion that occurs frequently absent shared conventions. In a big collaborative research project, you'll often need to answer questions like:

1. I need to start working on this project. How do I get the code running on my computer?
2. How did you download this Census data? I need to add a new variable.
3. I need to update Figure 6B. Where's the code that generates it?
4. I changed the code that generates Figure 6B. Is that going to affect the other results?
5. We're adding another year to the sample. How do I make sure all the results get updated with the new data?

The conventions described below were developed to **save time** and **reduce errors** by ensuring that each of these questions has a clear answer, and a straightforward way to find that answer.

Many teams of researchers (and software developers more generally) have faced similar issues in large-scale collaborations, and have come up with solutions that work for their team. There are many coding style guides that work well. This style guide isn't superior to the others. It describes a set of conventions that have worked well for our team. These coding conventions address the problems we've faced, in a way that minimizes hassles given the type of work we're doing and how we collaborate with each other. There are tradeoffs built into any set of conventions. The conventions described here reflect the tools and tradeoffs that have made sense for us in our work so far.

## Overview of the Health Inequality Project code

Our code consists of three "pipelines", which connect together to process our raw data into the tables, figures and numbers published in our paper. This process can be visualized from start to finish as:

**raw data** *---mortality_init, mortality_datagen--->* **derived data** *---mortality--->* **scratch**,**results**

Each pipeline is run using the [-project- command](https://ideas.repec.org/c/boc/bocode/s457685.html) in Stata, which is a [build automation tool](#automated-builds). In the **root** folder of our repository, there are three do-files:

1. `mortality_init.do` is the initial data generation pipeline. It processes raw mortality rates that we are not authorized to post publicly into more aggregated data that we can post publicly.
2. `mortality_datagen.do` is the data generation pipeline: it processes raw data into derived data.
3. `mortality.do` is the analysis pipeline: it processes raw data and derived data (mostly derived data) into results.

There is also a fourth `mortality_tests.do` pipeline that runs some unit tests, which verify that our code is working as expected. It does not need to be run to replicate our results.

*Why is the code split up into distinct "pipelines" instead of integrated into a single build? [See the answer in the appendix](#appendix).*


## Folder Organization

A good system of folder organization makes it easy to know where to put things and where to find things. Our system of organization has five main folders:

* code
* data/raw
* data/derived
* scratch
* results

The guidelines for how to organize files into these folders will be explained folder-by-folder.

### Code

All code goes in the **code** folder, with the exception of the -project- "master do-files" that define a pipeline. We've organized the **code** folder into subfolders that make sense given the structure of this project. The subfolders exist to make it easier to browse the **code** folder and find what you're looking for. These subfolders have evolved over time: it's not time-consuming to move code to a new subfolder and update the `project` build pipeline to point to the new location. So feel free to reorganize the code among subfolders whenever it will make it more organized.

There are three special subfolders:

* **code/ado** contains ado-files that were written specifically for this project. For example, we have an ado file to generate life expectancies.
* **code/ado_ssc** contains ado-files that were installed from the SSC and are used in the project. For example, we use `binscatter`.
	* Why not just ask people to install the programs from the SSC themselves? Two reasons:
		1. **Replicability**. Programs in the SSC get updated. Our code works with the version that was in the SSC when we wrote the code, but might not work with the version available 3 months or 3 years later. Or it might work, but produce a different result. Archiving the specific version of the program that we used ensures that everyone is using the same version and will be able to replicate the same result in the future.
		2. **Convenience**. Storing the dependencies within the project folder makes it as easy as possible for people to run the code on a new system. Anyone can download the code and run it immediately, without poking around trying to figure out which dependencies need to be installed.
 * **code/ado_maptile_geo** contains all the [maptile geography templates](https://michaelstepner.com/maptile/geographies/) that are used in the project. maptile geographies are just like SSC programs: they can be updated, and they need to be installed on each computer. By including them in the project folder, we ensure that the code continues to work in the future and that it can be run immediately on other computers without installing files from the internet.

Our code automatically adds **code/ado** and **code/ado_ssc** to the top of Stata's adopath so Stata finds and uses the ado files contained there. And each time we run `maptile` in the code, we use the `geofolder()` option to point to the **code/ado_maptile_geo** folder.

### Data

All data is stored in two folders:

* **data/raw**
* **data/derived**

What goes where? The key is that if you deleted everything but the **code** and **data/raw** folders, the code could run and recreate everything: all the data in **data/derived** would be regenerated, and everything in **scratch** and **results** would reappear. Data in the **raw** folder may have been derived at some earlier point, for example as a dataset associated with a published paper. When storing data under **data/raw** or **data/derived**, the question isn't how "raw" or "processed" the data is. The question is simply: was this data derived by the code in the **code** folder of this project?

All data should be placed in descriptively-named subfolders of **data/raw** and **data/derived**.

Every subfolder of **data/raw** should contain a file named **source.txt** that says how the data was obtained and on what date it was obtained. If the subfolder contains public data, the description should be detailed enough that a stranger could follow your instructions to obtain the data. If it's private data, the description should be detailed enough that a new collaborator could figure out where the data came from without contacting you. For example, **source.txt** could say: "Raj Chetty received elasticities.dta by email from Emmanuel Saez on 2015-08-19. The file is derived from Saez's paper 'The Elasticity of Taxable Income: Evidence and Implications' (2002)."

### Scratch

Over the course of a project, we'll produce many analyses—a ton of tables and figures. When everything is wrapped up, some of those will become known as "Figure 6B" or "Table 2". But until then, they'll be known as "Map of Bottom Quartile Life Expectancy" or "List of Top and Bottom 10 Commuting Zones for Life Expectancy". This is our scratch work, and it will live in the **scratch** folder.

Everything in the **scratch** folder is stored in descriptively-named subfolders, to help you navigate all of that work. Mostly these subfolders will contain figures and tables and numbers: image files and CSVs. They might also contain some datasets. There's a bit of ambiguity there: how do you decide whether a dataset belongs in **data/derived** or **scratch**? It should only be in **scratch** if the dataset is for "looking at" or if it's a temporary step in the analysis. If the dataset is going to be used again by the code, it should go in **data/derived**.

All filenames in the **scratch** folder should be descriptive. The filename specifies what the file contains (ex: `Q1 LE levels correlations.png`), not where it appears in the paper (ex: `Figure 7.png`). 

### Results

Near the end of the project, some of the figures and tables we've made will become numbered figures and tables in the paper. And we'll report some numbers in the text of the manuscript. These are stored in the **results** folder.

We use a single do-file (`code/assign_fig_tab_numbers.do`) to move files from **scratch** into **results** and relabel them. For example, it copies `scratch/Correlations with CZ life expectancy/Q1 LE levels correlations.png` to `results/Figure 7.png`.

`assign_fig_tab_numbers.do` is the ONLY do-file that should create files in **results**. This ensures that when figures are rearranged and renumbered during the editing and revision process, the only changes to the code are in `assign_fig_tab_numbers.do`. This do-file also serves as an easy reference for anyone who wants to figure out where a specific figure or table comes from.

### Recap: how information flows between folders

At the beginning, we said that the project is organized into five main folders:

* code
* data/raw
* data/derived
* scratch
* results

It should now be clear that as you run the code stored in the **code** folder, information flows in one direction between the other folders:

**data/raw** ---> **data/derived** ---> **scratch** ---> **results**

A quick summary of each folder:

* **code** contains all the code, organized into subfolders and three special folders. **code/ado**, **code/ado_ssc** and **code/ado_maptile_geo** contain programs that are reused repeatedly.
* **data/raw** contains subfolders with all the raw data required by the project. Each subfolder has a file named **source.txt** explaining where the data comes from. You should be able to delete all the folders except **code** and **data/raw** and then regenerate the rest by running the code.
* **data/derived** contains subfolders with processed data created by the code. These datasets are then used later in the code to produce results.
* **scratch** contains subfolders containing all the analyses we produced—the figures, tables, regression results, and other numbers that we wanted to look at.
* **results** contains the final set of results reported in the manuscript as numbered figures and tables or numbers stated in the text.

## Coding Style

### Short and focused do-files

Every do-file in this project should have a discrete purpose that can be explained in one sentence. Our code is therefore split up into many do-files that are:

* **Short:** a do-file is typically is less than 250 words
	* You can read a do-file from top to bottom in a few minutes and fully understand what it does.
* **Self-contained:** each do-file interacts with the code in other do-files only through the files it loads and the files it saves
	* You can edit a do-file without wondering how your edits might affect other code and results. It will only affect other code and results through the files it saves.
* **Focused:** a do-file accomplishes one discrete purpose
	* You can understand how each part of the code in a do-file contributes to accomplishing its purpose.

This style of coding will make editing code **less daunting, less time-consuming and less error-prone**. Especially when you need to edit code that you haven't touched recently, or code that was written by someone else.

The main drawback to having many separate code files is keeping track of things like: (i) what order the do-files need to be run in, (ii) how the do-files depend on each other, and (iii)  which do-files need to be run after something is changed in order to bring the results up to date. Fortunately you're not going to have to keep track of those things yourself. We'll use an [automated build system](#automated-builds) to keep track of how all our code and data depend on each other to produce the results, and to run the code necessary to update the results automatically.

#### *How to divide code into separate do-files*

A good rule of thumb is that most do-files should be fewer than 250 lines, but that are sometimes good reasons for a do-file to be longer. Don't make your code more confusing by splitting it up to meet an arbitrary rule of thumb. Just be conscientious when producing long code files and ask yourself: is this code accomplishing a single discrete purpose, or multiple discrete tasks that could be naturally split up into separate do-files?

For example, our process for generating life expectancies involves three discrete steps. (1) Load and clean up the data on mortality rates. (2) Fit a Gompertz distribution to the mortality rates to estimate Gompertz parameters. (3) Use the Gompertz parameters to estimate life expectancies. These 3 steps are accomplished in 3 separate do-files. Some of those do-files are longer than 250 lines because we perform these steps at so many different levels of aggregation (national by income percentiles, state by income quartiles, etc). We could have made the do-files shorter than 250 lines by splitting them up into separate files by level of aggregation. But splitting the code up into more do-files wouldn't have made the code easier to understand or easier to edit, so we didn't.

### Specify the Root Folder

Each do-file needs to be able to obtain the path to the **root** folder of the project: the folder that contains subfolders named **code**, **data**, **scratch** and **results**. (This path is fetched by the [do-file header](#do-file-header) described below). And the path will be different on your computer from someone else's computer, so it shouldn't be hard-coded anywhere in the code. Instead, it will be added to the configuration of your computer's copy of Stata.

1. Open Stata, and run ``doedit "`c(sysdir_personal)'/profile.do"``. This will open a do-file editor to the profile.do file in your PERSONAL folder.
2. Write a line that says `global mortality_root "<path_to_mortality_root_folder>"`. Save the do-file.
3. Close Stata and reopen Stata. When it reopens, you should see a line in the Results window that says something like "running [...]/profile.do".
4. In Stata, if you run `ls "$mortality_root/"`, you should see **code** and **data** among the printed results. If you do, then everything is set up correctly.

### File paths begin with $root

Throughout the code, we refer to all files using relative paths that begin with `$root`. For example:

```
use "$root/data/derived/le_estimates/cz_leBY_gnd_hhincquartile.dta", clear
```

The `$root` global will always contain the path to the root folder of the project *on your computer*, which is likely different from the path on someone else's computer.

### do-file header

Each do-file begins with the following 8 lines:

```
* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
    if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
    do "${mortality_root}/code/set_environment.do"
}
```

This header code allows the do-file to be run interactively *or* in a project build. The most important thing it does is ensure the global `$root` is correctly defined. For more details on what this header code does, [see the appendix](#appendix).

### Further header sections

After the 8 lines that begin every do-file, a typical do-file will then have some or all of the following sections:

```
* Set convenient globals
global derived "${root}/data/derived"

if (c(os)=="Windows") global img wmf
else global img png

* Create required folders
cap mkdir "${root}/scratch/Correlations with CZ life expectancy"
cap mkdir "${root}/scratch/Correlations with CZ life expectancy/data"

* Erase output numbers
cap erase "${root}/scratch/Correlations with CZ life expectancy/Reported correlations.csv"

* Import config
project, original("$root/code/set_bootstrap.do")
include "$root/code/set_bootstrap.do"

/*** Estimate CZ-level correlations between life expectancy (levels and trends)
     and local covariates.
***/
```

The first section, *Set convenient globals*, defines any globals we use later in the do-file.  Any globals you wish to refer to within the do-file must be defined in that same do-file (except $root, which is defined automatically in the [8 line header](#do-file-header)).  This is because `project` clears globals before running each do-file. Therefore the scope of each global is restricted to the do-file that defines it, but the global will remain in memory if you run segments of the do-file interactively—which is often useful during development and debugging.

The second section, *Create required folders*, creates any folders that you write to during the do-file if they don't already exist. If the code tries to write to folders don't exist, it will crash. Creating the folders automatically in the do-file that uses them ensures that the code will run correctly every time—even when it is run for the first time and even if you delete folders you've created in the past.

The third section, *Erase output numbers*, erases a file that we append to throughout the rest of the do-file, so that it starts from scratch each time the do-file is run.

The fourth section, *Import config*, imports some configuration settings that are used by multiple do-files. In this case, `set_bootstrap.do` defines a global specifying how many bootstrap iterations to run. By importing these settings from a shared file instead of defining the settings at the top of each do-file, we ensure that the settings are always consistent across our code and only need to be updated in one place if they change.

The final section, a comment that begins `/***` and ends `***/`, explains briefly what the do-file is going to do. This is a convention adapted from "docstrings", which are used commonly in other languages.  This comment is meant to give someone who hasn't read the do-file's code yet a quick sense of what it's going to do.

### Descriptive variable names

Variable names should clearly indicate what the variable contains. Don't try to save time typing by making variable names short. You'll save far more time for everyone who will read your code or use the dataset you've created (your future self included) if it's clear what each variable contains.

Suppose you've estimated a model and are saving the intercept and slope as variables. Don't call those variables *a* and *b*. Better to call them *intercept* and *slope*. Or if these are parameters of the Gompertz model, maybe *gomp_intercept* and *gomp_slope*.

[Gentzkow and Shapiro offer](https://web.stanford.edu/~gentzkow/research/CodeAndData.pdf) excellent rules of thumb for choosing names:

> By default, names for variables, functions, ﬁles, etc. should consist of complete words. Only use abbreviations where you are conﬁdent that a reader not familiar with your code would understand them and that there is no ambiguity. Most economists would understand that “income_percap” means income per capita, so there is no need to write out income_percapita. But income_pc could mean a lot of different things depending on the context. Abbreviations like st, cnty, and hhld are ﬁne if they are used consistently throughout a body of code. But using blk_income to represent the income in a census block could be confusing.

> Avoid having multiple objects whose names do not make clear how they are different: e.g., scripts called “state_level_analysis.do” and “state_level_analysisb.do” or variables called x and xx.

Whenever you can't make it clear enough what a variable contains from the name alone, make use of Stata's `label variable` to provide it with a descriptive label. For example, you might have yearly data with a variable called *age* that is labelled "Age on December 31st".

If you come across a confusing variable name while you're coding, you should go improve the code that created it! Whenever practical, update the code to give the variable a better name and then update all downstream code to use the new name. At the very least, you can give the variable a descriptive label without needing to update with downstream code.

### Descriptive file and folder names

Use descriptive names for files and folders to save everyone (including you) time in the future puzzling over what those files contain. Don't try to save time typing by making file names and folder names very terse—you're not going to type them out very often, and you'll often be copying and pasting anyway. Don't be afraid to use full words and spaces in your folder and file names.

Examples:

* A figure
	* `c_1.png` is a terrible filename.
	* `correlations.png` is a bad filename if you're doing more than one analysis of correlations.
	* `Q1 LE levels correlations.png` is a good filename.
* A program
	* `med_v_ext.do` is a bad filename
	* `Decompose mortality into medical v external causes.do` is a good filename
* A folder
	* `data/raw/intercensal pop` is a bad folder name
	* `data/raw/Census County Intercensal Estimates 2000-2010` is a good folder name

By naming files and folders descriptively, we're able to browse the files in the project and find things without reading the code. It should be easy for someone looking for a particular analysis to read the list of subfolders of **scratch** and pick out the one that contains what they're looking for. A well-named file could be attached to an email without renaming it, and the recipient will have a good sense of what you sent them.

### Datasets have unique IDs

Every dataset we create should have a deliberate set of unique ID variables. (There may occasionally be good reasons to break this rule, but very rarely.) Colloquially, we often call this the "level" of the data: one dataset has "person level" data, another has "person-by-year level" data, and another has "country level" data.

Knowing the unique IDs is essential to understanding any dataset. The unique IDs tell you what the dataset describes, and how it can be merged with other datasets. 

For example, we have a dataset of life expectancies by Commuting Zone, Gender and Household Income Quartile. For that dataset the variables *cz*, *gnd*, *hh_inc_q* are the unique ID variables, and their values tell us what each observation of the dataset is describing. These variables follow two rules:

1. There are no "duplicate" observations that have the same values of the unique IDs.
2. The unique ID variables have no missing values.

You can verify that these two facts are true in Stata using the `isid` command: `isid cz gnd hh_inc_q`. Sometimes a missing value in the unique IDs makes sense, in which case you can loosen rule 2 and just check rule 1 using `isid <varlist>, missok`.

It often makes sense to list the unique IDs in the filenames, especially when we store the same data saved at multiple levels of aggregation. For example, our folder of life expectancy estimates contains these files, and you can certainly tell what they contain:

```
cty_leBY_gnd_hhincquartile.dtacty_leBY_gnd.dtacz_leBY_gnd_hhincquartile.dtacz_leBY_gnd.dtacz_leBY_year_gnd_hhincquartile.dtanational_leBY_gnd_hhincpctile.dtanational_leBY_year_gnd_hhincpctile.dtast_leBY_gnd_hhincquartile.dtast_leBY_gnd.dtast_leBY_year_gnd_hhincquartile.dta
```

For more details on the virtues and history of saving data with unique IDs, I highly recommend reading *Chapter 5: Keys* of Gentzkow and Shapiro's *[Code and Data for the Social Sciences](https://web.stanford.edu/~gentzkow/research/CodeAndData.pdf)*.

### Assert what you're expecting to be true

The code you write often relies on assumptions about the data...things you know to be true. Like "variable x is never negative, so when I control for the log of x in a regression, I still have the full sample". But things that are currently true about the data can change in the future, and those changes can lead to unexpected results. So as you're coding, it's worth explicitly asserting the facts about the data that you're relying on. For example:

```
* Full sample regression of y on log(x)
assert x>0
gen log_x=log(x)
reg y log_x
```

```
* Collapse away income dimension
isid age gnd hh_inc_pctile
collapse (sum) pop_*, by(age gnd)
```

By embedding assertions like `assert` and `isid` into the code, the code will crash with an error to alert you if the assertion is ever false. These assertions can also make your code easier to read and understand by credibly stating the facts that are true about the data and required by the procedures you're running. By contrast, if you write a comment that says `* x is always positive!`, a circumspect reader would need to check the data to know whether they can believe the comment.

Every `merge` command should use the `assert()` option or `assert() keep()` options to specify which merge results are expected and desired. This care is worthwhile because merges are especially prone to change in unexpected ways, and we want to be notified if they do. It's also very useful to know what the coder who wrote the merge was expecting to happen.

Deciding which assertions need to be tested is an art that comes with debugging experience. You don't need to brainstorm all the things that could possibly go wrong with your code and add tests to check for them—it would take ages, and you'll think up scenarios that realistically will never happen. The value of a test depends on (1) how likely it is to fail at some point in the future and (2) how bad the outcome would be if it failed and no one noticed. Would the next line of code crash, or would a regression coefficient silently change? Write assertions to test for problems that worry you ("it would be bad if...") and problems you've encountered before.

Whenever you encounter and fix a bug, write a test to ensure that the bug doesn't reappear in the future if it's feasible to do so.

### Don't repeat yourself (and how to avoid it)

"Don't repeat yourself" is canonical advice given to all coders. Repetitive code is hard to read and hard to maintain, and therefore prone to hidden errors. So when you need your code to do the same thing repeatedly (for multiple groups, for multiple samples, etc), you should write a loop or a function instead of creating multiple "code clones" that do the same thing with a small twist.

For example, suppose you've written the code that performs a series of steps to estimate and generate a figure about race-adjusted life expectancy (`le_raceadj`), and now you need to produce the same figure for unadjusted life expectancy (`le_unadj`). It's tempting to copy and paste the code, and just change all instances of `le_raceadj` to `le_unadj`. But there are serious downsides to duplicating the code:

* It's easy to miss one of the elements you're supposed to change. Maybe at some point in the calculation you compute the mean of the outcome variable, but you forget to switch the variable name. The code will look almost right and run without errors, but produce the wrong result.
* Whenever you or someone else changes the procedure in the future, that change will need to be applied in multiple places. Doing so will take longer, and once again it's easy to miss one of the code clones you need to change. It's also difficult to verify that all the clones have been correctly changed.
* When reading and debugging repetitive code, it's difficult and time-consuming to verify how each clone differs from one another.  "In what ways is this 20-line block of code different from this nearly-identical 20-line block of code?" The only way to find out is to go through them line-by-line and carefully compare each line.

#### *When to avoid repetitive code*

Repetition isn't *universally* bad, and even a good practice like "don't repeat yourself" can be [taken too far](https://www.tomdalling.com/blog/software-design/fizzbuzz-in-too-much-detail/). Repetitive code becomes cumbersome and error-prone if the repeated code is long, repeated many times, or repeated in multiple code files.

It's totally reasonable to write out a simple step twice:

```
xtile incdecile_m = income if gender=="m", nq(10)
xtile incdecile_f = income if gender=="f", nq(10)
```

But if you were going to do the same step 15 times, you should write a loop:

```
forvalues y=2001/2015 {
	xtile incdecile_`y' = income if year==`y', nq(10)
}
```

And if this procedure involved many lines of code, you should use a loop even if it's only repeated twice:

```
foreach g in "m" "f" {
	assert income >= 0 if gender=="`g'"
	xtile incdecile_`g' = income if gender=="`g'" & income>0, nq(10)	
	replace incdecile_`g' = 0 if gender=="`g'" & income==0
	label var incdecile_`g' "Deciles of positive income"
}
```

#### *How to avoid repetitive code*

We regularly use three types of abstractions to eliminate repetitive code in Stata.

1. When you need to change *only one thing* in the code, you can use a loop. `foreach` and `forvalues` will loop over the same code multiple times, changing the value of a local variable each time.
2. When you need to change *multiple things* within the code, you can define a program within the do-file using `program`. Then you can pass arguments to specify the value of multiple local variables when you call the program: read `help syntax` to see how.
	* We generally put these programs at the top of the do-file, under the headers. For example, see **code/raceshares/national_racepopBY_year_age_gnd_incpctile.do**
	* Defining a program can also be useful if you need to run the same code multiple times with different code surrounding it. For example, see **code/raceshares/national_racepopBY_year_age_gnd.do**
3. When you need to repeat code across *multiple do-files*, you can define a program in an ado-file and put it in **code/ado**. The file name of the ado-file must be the same as the name of the program it defines.
	* For example, **code/raceshares/national_racefracBY_workingage_gnd_incpctile.do** uses `compute_racefracs` which is defined in **code/ado/compute_racefracs.ado** and used by multiple do-files.
	* Any ado-file placed in **code/ado** will be automatically available as a program, because our code [automatically adds that folder to Stata's adopath](#code).

Often a piece of code will progress to different levels of abstraction over time, so don't worry about choosing the right level of abstraction right off the bat. It's natural to write out the code once. Then when it needs to be repeated, turn it into a loop. Then when you realize you need to change more than one aspect of the code during each repeition, turn it into a program. Then when you realize that program is useful in multiple do-files, turn it into an ado-file.

#### *Tips and tricks*

* When some lines of code need to change between repetitions, use `if`/`else if`/`else` conditions: see `help ifcmd` for details. Note how `if` statements make it really easy to see how the code differs across repetitions, unlike copy-pasted code.

* When debugging long loops or programs interactively, it's sometimes useful to add lines of code that temporarily define the locals manually. That way you can manually run portions of the code within the loop. For example, you might temporarily change a loop as follows while debugging:

```
*foreach g in "m" "f" {
local g "m"
	...lots of code...
}
```

* When defining programs within a do-file, add a line that says `cap program drop <program_name>` just before `program define <program_name>`. This will automatically drop and redefine the program each time you run the do-file. It allows you to run the do-file multiple times interactively while debugging. Otherwise the do-file would crash when you re-run it, telling you the program has already been defined.
	* If you move the program to an ado-file, you should remove the `cap program drop` line. It is no longer necessary or useful.

* It's good practice to write a comment at the beginning of a program describing what the program does. You should put this comment right under the `program define <program_name>` line, beginning with `/***` and ending with `***/`. This is the same convention we use to describe what [each do-file does](#further-header-sections) in its header.

### Indents and line breaks

Code is much easier to read if it is well-indented and long lines of code are broken into multiple lines. There are **many** conventions for how to indent your code, and how to break long lines. And many coders have strong preferences over the conventions they use.

I'm not going to tell you exactly what to do. There is more than one way to use indents and line breaks to produce clean-looking code. Being excessively rigid about what good code looks like creates hassles for collaborators that aren't worth the stylistic benefits gained. But it is worthwhile to follow these two guidelines:

1. Within a single do-file, all code should follow the same style for indents and line breaks. If you're editing code written by someone who uses a different style, either follow their style or update the code to match your own stylistic preference.
2. When you're going to be collaborating closely with someone else on the team—regularly reading or editing each other's code—use communication and teamwork to ensure that your styles meet each other's needs so that you're collaborating effectively.

### Write dates as YYYY-MM-DD

When you write dates in code comments, in a `source.txt` file, or in file names: use the YYYY-MM-DD format, because it's [better than all the others](https://xkcd.com/1179/). It's a global standard, Americans and Europeans can read and write it without confusion about whether the date or the month comes first, and an alphabetical sort is equivalent to a chronological sort.

### Figure file types

We configure the code to automatically output figures in `.wmf` format on Windows machines, and in `.png` format otherwise.  Maps are the only exception to this convention. Maps can be enormously large files when stored in vector image formats like `.wmf`, so we always output maps as `.png` using `maptile, savegraph()`.

In order to get the code to automatically switch file formats depending on the operating system, include the following code in the do-file header:

```
* Set convenient globals
if (c(os)=="Windows") global img wmf
else global img png
```

Then use `.${img}` as your file extension when you generate figures other than map.

### Figure data in CSVs

For every figure that we include in the paper, we generate a CSV file containing the data plotted in that image.  This data should be a direct representation of what is shown in the figure.  For example:

* For a binscatter, this CSV contains the binned scatterpoints that are plotted in the figure. Not a copy of the dataset that you ran binscatter on. (See the `savedata()` option of binscatter to get the scatterpoints.) 
* For our correlation figures, this CSV contains the point estimates and lower and upper bounds for the 95% CI.

We create these CSVs for two reasons:

1. It allows us to use diffs or version control to check whether the figures have changed. It's tricky to take two image files and compare whether they've changed: the exact binary data of the image file depends on your screen resolution when you generate the image in Stata, your operating system, etc.  By generating CSVs, we know that if the CSV has changed then the figure has changed. If the CSV is the same, the figure is the same.
2. The CSVs can be used to easily look up the numbers underlying the figure.

### Outputting reported numbers

Every number that is reported in the paper should appear *directly* in a CSV file in the **results** folder.

No further calculations should be required to obtain the number in the paper.  For example, if we report a p-value then the p-value must appear in the CSV file — a coefficient and standard error are not enough.

There are three ways a number can appear in the **results** folder:

1. If the number appears directly in a Table in the paper or appendix, it can be obtained from the CSV file for that table.
2. If the number is plotted in a Figure in the paper or appendix, it can be obtained from the CSV file for that figure.
    - For example, we report the coefficient and p-values from correlations depicted in `Figure 7` in the text of the paper. Even though the p-values do not appear directly in the figure, they have been stored in the CSV associated with the figure so that they can be obtained for the text.
3. If the number does not appear in any Table or Figure, it must be output to a CSV using the `scalarout` command.
    - `code/lifeexpectancy/le_correlations.do` provides a good example of this.
        + The CSV file is erased at the top of the do-file
        + It is written to repeatedly using `scalarout` throughout the do-file
        + It is added to the project build using `project, creates()` at the end of the do-file
    - Use the `scalarout, fmt(%9.Nf)` option to round the number to the `N` decimals reported in the paper.
    - As with tables and figures, output this CSV file to a descriptive subfolder of **scratch** with a descriptive file name.
    - Then use `assign_fig_tab_numbers.do` to copy the CSV to **results**, assigning it to `Reported numbers - <description>`.

### Checklist prior to committing

We keep all of our code under version control in Github. Doing so preserves a record of every version of the code in the history of the project, and allows us to review and reverse changes between the current version and past versions. It's also how we keep our code in sync with collaborators working on different computers: by committing our changes to the repository, pushing them to the Github server, and pulling the latest version from the server.

Before you commit your changes to the repository:

1. If you've added a new do-file, make sure to add it to the pipeline's master do-file (ex: `mortality.do` for the analysis pipeline). That way it will be run when the project is built.
2. **Always build the project by running** `project <pipeline_name>, build` **before committing anything to the main branch of the repository!** That way you make sure that when someone else pulls your latest commit from the repository, they get code that works. When you commit code that doesn't build, software developers call it called "breaking the build".
    * It's frustrating and confusing when you pull broken code: you make your edits, run `project, build` and it fails. You wonder why your code is broken, then you realize it's someone else's code that broke it. You wonder if you should fix it yourself or tell them to fix it so that you can test your own code.
    * What about occasions where it makes sense to commit something, but it's not finished yet? If you're working on a big task that will take multiple days to finish, you should probably commit the incremental steps along the way even if the task is unfinished and the build is broken. In this case, make sure you're working in your own branch of the repository and that the build works before your branch is merged into the main branch.

## Automated Builds

### Before automation

A classic way to organize code for a Stata research project is to put it all in one do-file. In that style, it's clear how to generate the results: run the do-file from top to bottom. But it becomes incredibly difficult to collaborate and maintain a large project in one giant do-file. Only someone who is working on the code full time can hope to understand the structure of the entire do-file and how all the pieces fit together—and even then, only with a lot of thinking. So you'll face questions that are difficult to answer:

* Which part of the code do I need to edit to update this figure?
* If I edit this code, how will it affect the rest of the code and results?
* Do I need to wait hours for the code to run from top-to-bottom to get the latest results? No, I'll just run the snippets that need to be re-run right now...
* ...It's been a while since I ran the code from top-to-bottom: why does it crash now?
	* All the individual pieces worked when the individuals who wrote them last ran them. Why don't they work together?
	* If we rearrange the code, how is that going to affect the results?

So it's natural to split up the code into multiple do-files. But then the challenge is to figure out how all the do-files relate to each other. Once again, only someone who is working on the code full time can hope to understand the structure of the entire collection of do-files and how all the pieces fit together—and even then, only with a lot of thinking. So you'll face the same questions with a different twist:

* Which do-file do I need to edit to update this figure?
* If I edit this do-file, how will it affect the rest of the code and results?
* What order are these do-files supposed to be run in?
* Do I need to wait hours and run all the do-files to get the latest results? No, I'll just run the individual do-files that need to be re-run right now...
* ...It's been a while since I ran all the do-files from top-to-bottom: why does it crash?
	* All the individual do-files worked when the individuals who wrote them last ran them. Why don't they work together?
	* If we rearrange the do-files, how is that going to affect the results?

### After automation

In any large-scale coding project, "understanding the structure of the entire collection of do-files and how all the pieces fit together" is not a job for humans to do in their heads. It takes up our time and we're not very good at it. Instead, we'll offload that job to our computers by using an "automated build system". Doing so is new to many researchers, but we're decades behind software developers. The classic build automation tool `make` was [first written in 1976](https://en.wikipedia.org/wiki/Make_software).

Each do-file we write is not only [short and focused](#short-and-focused-do-files), it's also a self-contained module. A collaborator can edit any do-file, and know that the code only affects other code and results through the files it saves. A do-file is only affected by other code through the files it loads. And as we write our do-files, we'll tell the automated build system which files our code loads and saves. We'll also tell the automated build system what order to run our do-files in, using a build script (also called a "master do-file" or a "pipeline").

Having told the automated build system how to run our do-files and which files each do-file loads and saves, the automated build system can:

* Build the project from top-to-bottom.
* Check which files have changed since the project was last built, and only re-run the do-files that depend on files which have changed. All the results get updated, but only code that needs to be re-run gets re-run.
* Build the project twice and confirm that when you re-run the code, you get the same result. This verifies that your results are replicable.
* Tell you if the build doesn't make sense. For example if you try to use a file before you create it in the code, the build system will throw an error even if the file exists on your computer (because you previously ran the code that created it).
* Tell you about how each file connects together. For any file, it can tell you which do-file (if any) created it and which do-files use it. So you can trace out how a file was created. Or trace out how changing a file will affect other code and files.

With those tasks taken care of by software, no single person needs to understand the entire collection of do-files and how all the pieces fit together. You can focus on the do-files you're working on, which is quite managable because they're [short, focused and self-contained](#short-and-focused-do-files). If you change the output of the do-file you're editing, you can query the build software to find out which subsequent files will be affected. And after you've made your changes, you can run a build and know that all the results are updated... without waiting to re-run any code that wasn't affected by your changes.

### Builds in Stata using `project`

All of our code is run using `project`, an automated build tool for Stata [created by Robert Picard](https://ideas.repec.org/c/boc/bocode/s457685.html). There are more general automated build tools and more powerful automated build tools, but `project` is especially convenient for Stata coders. The most challenging part of using an automated build tool is correctly recording all of the files that your code depends on or creates. `project` makes it easy to record this information directly in your do-file.

I highly recommend reading `help project` to understand the full details of what `project` does and the features it offers. I'll cover the highlights here. When you run a build such as `project mortality, build`, project checks which files have changed since the last build.  It then runs any do-files whose code has changed or which depend on any files that have changed.  So, if you change the code that generates one dataset, and a different piece of code uses that dataset to generate a result, `project` will re-run both to ensure the final result is updated. Other code that doesn't depend on these results won't be re-run.

#### *Build commands*

In order to work this magic, `project` requires each do-file to specify which files it loads and which files it creates using *build commands*. You need to add these commands **every time** you load a file (such as a dataset) or create a file (a dataset, table, figure, etc). There are three main build commands:

1. `project, original(filepath)` says that you are using a file that wasn't generated in this -project- build.
	* `project, relies_on(filepath)` says that you are *referencing* a file that wasn't generated in this -project- build, such as a piece of documentation in a PDF or text file. This file you're referencing doesn't affect the code or results, you're just pointing to it as an important reference for the procedure or the data you're using. In practice, this does the same thing as `project, original(filepath)`.
2. `project, uses(filepath)` says that you are using a file that was generated in this -project- build.
3. `project, creates(filepath)` says that you just created this file.

By default, each of these build commands will **automatically clear the dataset in memory**. Ordinarily this isn't problematic, because most often your code will look something like this:

```
project, original("$root/data/raw_data/some data.dta")
use "$root/data/raw_data/some data.dta", clear

<do lots of things>

save "$root/data/derived_data/cleaned data.dta"
project, creates("$root/data/raw_data/cleaned data.dta")
```

Note that `project, original` came before `use`. And `project, creates` came after `save`. So the clearing of the loaded data was inconsequential. But sometimes you don't want the loaded data to be cleared, in which case you need to add the `preserve` option to the build command. Some common cases for that are:

* Merging a dataset into the loaded data
* Continuing to work with a dataset after saving it
* Generating a bunch of figures in a loop

Omitting a `preserve` option is the most common cause of crashes when you first build code that you've written interactively. But you'll notice and fix the problem easily—just remember to [build before committing](#checklist-prior-to-committing). The alternative, adding `preserve` to every build command, would slow down the build. 

#### *Correspondence between build commands and folders*

Because of the way our [folder organization](#folder-organization) is designed, there is a direct association between the correct build command and the folder you're accessing:

* Loading data
	* Files in **data/raw** are loaded using `project, original`.
	* Files in **data/derived** and **scratch** are loaded using `project, uses`
	* Files in **results** are not loaded by the code.
* Saving data
	* Files in **data/derived**, **scratch** and **results** are created using `project, creates`

In practice, this has gotten a little more complicated in the Health Inequality Project code because the build was [split up into multiple build pipelines](#appendix).

But if you accidentally use `original` or `uses` incorrectly when you should have used the other, `project` will simply tell you so and give an error when you try to build. It's no big deal.

#### *Recording dependencies on ado-files*

If your do-file runs a command that is defined in an ado-file in **code/ado**, then it depends on that ado-file. For example, if your code runs `compute_racefracs` and **code/ado/compute_racefracs.ado** changes, that code needs to be re-run. So you need to record that dependency using `project, original(code/ado/compute_racefracs.ado)`.

You don't need to worry about recording dependencies on code in **code/ado_ssc** or **code/ado_maptile_geo** within your do-files. Since that code wasn't written in the project, it's unlikely to change.

In practice, remembering to add build commands for dependencies on ado-file programs is much harder than remembering other build commands. Try to be conscious of this and remember them. But in our experience, it has been inevitable that they are forgotten sometimes. So if you are updating a program in **code/ado**, it is often worth double-checking that all the do-files that use the program declare their dependency on the ado-file. If the program name is distinctive, you can do this easily by searching within all the do-files for the program name using [Atom](https://atom.io/), [Sublime Text](https://www.sublimetext.com/) or [Notepad++](https://notepad-plus-plus.org/).

#### *Features other than builds*

Most of the time you'll be using `project` to run the code using `project, build`. But `project` has some other useful features that you should keep in mind:

* `project, list(concordance)` will list every file used or created by the project, and under each file state which do-files used or created it. It will also save that list to a text file under **archive/list**.
	* This is useful to trace out how a file was created and which code and results a changed file might affect.
* `project, replicate` will build the project, move all the files created by the project to a folder called **replicate**, then build the project again and print a report listing all the files that differed between the two builds.
	* Focus on the datasets and results. There are many reasons why logs can differ across builds, and usually that's nothing to worry about. Especially since every number that's reported in the paper is [stored in a CSV](#outputting-reported-numbers), not merely recovered from a log.
	* Sometimes datasets are not identical when replicated because of some randomness in the last digits of a variable stored as a double. Often this is because of a `collapse` command on a double. This is nothing to worry about, but you can decide if you want to eliminate the randomness using the `float()` command or `recast float <varlist>, force` to eliminate the random false precision in the double.
* `project, share(<sharename>, alltime nocreated)` will create a folder under **archive** containing all the files required to build the project from scratch. This is useful when creating replication files to post online.
	* If you run `project, setup` and point to the master do-file in the subfolder of **archive**, you should be able to build the project in that folder by running `project, build`. But you might discover that there were some missing dependencies that you need to declare using build commands. This is how we discovered the dependencies that are now declared near the top of **code/mortality.do**.

It's worth reading through `help project` to discover all the things that `project` can do.

## Technical Debt

If you've read through this coding style guide, you're probably thinking that there are a lot of guidelines to follow! Some will become second nature through force of habit, but some of these things require work. And there will be times when you're racing to produce some new results, and you don't have time to follow all the rules. That is okay, and even optimal—as long as you're aware of the tradeoffs you're making and are conscientious about it.

Computer scientists have a framework for thinking about this issue: they talk about "technical debt". Technical debt works a lot like financial debt, but you're borrowing time instead of money. Sometimes it's worthwhile to borrow against the future in order to get something you need now. But if you don't pay down your debt, it will accummulate and grow more costly to repay.

You can think about technical debt [like borrowing on a high-interest credit card](https://research.google.com/pubs/pub43146.html). You can get a result fast by ignoring all the guidelines: making repetitive code, ignoring the build, getting numbers straight from the log, not outputting data CSVs for figures, etc. But as you rush, the code becomes more disorganized, harder to maintain and more error-prone. It becomes harder for others to work with the code. And over time as more code interacts with the low-quality rushed code, it becomes harder and more time-consuming to fix up the issues and get all the code running smoothly again. You're paying interest on your technical debt, and it continues growing the longer you ignore it.

When you're taking on technical debt, try to consider whether it's worthwhile. Try to keep track of the code you worked on while you were rushing, and remember to go back and clean it up when you have the time. And if you come across code that's in a messy state during your regular work, take some time to refactor it. Refactoring is when you restructure code to make it clearer and better organized, without changing the result.

The code is never perfect, and there are often good reasons for imperfections. Be aware of them as you work hard and produce good research, and you'll leave the code better than you found it.

## Appendix

#### Why is the code split up into distinct pipelines instead of integrated into a single build?

Originally we had a single pipeline called `mortality.do` that ran all the code from start to finish. Having a single pipeline is very simple and convenient: build it and everything is updated! Having the code split into multiple pipelines is more complicated to maintain, but became more convenient in this project for a few reasons:

1. The data generation code in `mortality_datagen.do` is much slower than the analysis code in `mortality.do`, and there was a natural division of labor between the coders working on data generation and those working on analysis. The people working on the analysis code benefited at times from working with an older vintage of the data while developing their code, without having to wait for the latest data generation code to build.
2. The code in the `mortality_init.do` pipeline uses datasets that we are not authorized to post publicly. By segmenting this part from the rest of the code, people replicating our work can build the `mortality_datagen.do` and `mortality.do` pipeline to completion using publicly accessible data. We've avoided posting broken builds, which are much harder for others to work with than working builds.
3. The code in `mortality_tests.do` also uses datasets we are not authorized to post publicly, like `mortality_init.do`. But it has to be run after the `mortality_datagen.do` pipeline because it relies on some datasets created there. So it is split from the `mortality_init.do` pipeline.
4. The `mortality_init.do` and `mortality_tests.do` pipelines both run some code in the [Julia](http://julialang.org/) programming language, while all the rest of our code is run in Stata. By segmenting these parts from the rest of the code, both collaborators and people replicating our work can run the main code pipelines without installing and configuring Julia. This simplifies the dependencies and set up.

#### What the 8 lines of header code do

As [discussed above](#do-file-header), every do-file begins with the same 8 lines of code:

```
* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
    if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
    do "${mortality_root}/code/set_environment.do"
}
```

This code gives us the flexibility to run the do-file interactively or using `project, build`. But how? Let's go through it piece-by-piece:

* First we clear all return values (`return clear`) and ask `project` to tell us about the build it's running (`capture project, doinfo`).
* If a project build is running, we set the global `$root` as the folder containing the "master do-file" of the pipeline being built (ex: `mortality.do`). These are located in the root folder of the project.
* If no project build is running, we have a little more work to do:
	* First we run **profile.do** in Stata's PERSONAL folder, which is where [you defined](#specify-the-root-folder) a global named `$mortality_root`.
		* **profile.do** will be run automatically when Stata is opened, but the global could have been changed or cleared since then, so we'll reset it. For instance, `project` clears all globals while running a build.
	* Then we run **code/set_environment.do**, which performs important configuration steps.
		* It sets the global `$root` to the value of `$mortality_root`.
		* It adds **code/ado** and **code/ado_ssc** to Stata's adopath, so Stata will automatically find the programs stored there.
			* When the do-file is run during a project build, this will be performed by the master do-file.
		* It disables the `project` command by temporarily dropping it from memory and replacing it with a dummy program. The dummy program just displays a message saying "project is disabled" with a button to re-enable `project`.
			* Otherwise the project build commands (like `project, uses`) would crash the do-file while it's running interactively, because no project build is in progress.

## Further reading

Gentzkow, M., & Shapiro, J. M. (2014, January). [Code and Data for the Social Sciences: A Practitioner’s Guide](https://web.stanford.edu/~gentzkow/research/CodeAndData.pdf).

Wilson, G., Aruliah, D. A., Brown, C. T., Hong, N. P. C., Davis, M., Guy, R. T., … Wilson, P. (2014). [Best Practices for Scientific Computing](https://doi.org/10.1371/journal.pbio.1001745). *PLOS Biol*, 12(1), e1001745.
