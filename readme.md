
This repository contains the code of the 2016 JAMA paper: [The Association between Income and Life Expectancy in the United States, 2001 - 2014](http://jama.jamanetwork.com/article.aspx?articleId=2513561&guestAccessKey=4023ce75-d0fb-44de-bb6c-8a10a30a6173), by Raj Chetty, Michael Stepner, Sarah Abraham, Shelby Lin, Benjamin Scuderi, Nicholas Turner, Augustin Bergeron, and David Cutler. *The Journal of the American Medical Association* (2016), Vol 315, No. 14.

Frina Lin and Jeremy Majerovitz provided outstanding research assistance and contributed to developing this code.

For more information about the results of this project and to download the data and results, see [www.healthinequality.org](https://healthinequality.org). For more information on how to use this code to replicate the results, read on.

# License for Code

All of the files in this repository (with the exception of **code/readme.md** and those contained under **code/ado_ssc** and **code/ado_maptile_geo**) are released to the public domain under a [CC0 license](https://creativecommons.org/publicdomain/zero/1.0/) to permit the widest possible reuse. If you use our code or data, we ask that you cite our [2016 JAMA paper](http://jama.jamanetwork.com/article.aspx?articleId=2513561&guestAccessKey=4023ce75-d0fb-44de-bb6c-8a10a30a6173).

The coding style guide contained in **code/readme.md** is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/). The files contained in the **code/ado_ssc** folder were obtained from Stata's [SSC software repository](http://www.stata.com/support/ssc-installation/), and are subject to their own respective licenses. The files contained in the **code/ado_maptile_geo** folder were obtained from the [maptile geography template website](https://michaelstepner.com/maptile/geographies/), and are subject to their own respective licenses.

# Code Organization

Our code consists of three pipelines, which connect together to process our raw data into the tables, figures and numbers published in our paper. This process can be visualized from start to finish as:

**raw_data** *---mortality_init, mortality_datagen--->* **derived_data** *---mortality--->* **scratch**,**results**

Each pipeline is run using the [-project- command](https://ideas.repec.org/c/boc/bocode/s457685.html) in Stata, which is a build automation tool. In the **root** folder of our repository, there are three do-files:

1. `mortality_init.do` is the initial data generation pipeline. It processes raw mortality rates that we are not authorized to post publicly into more aggregated data that we can post publicly.
2. `mortality_datagen.do` is the data generation pipeline: it processes raw data into derived data.
3. `mortality.do` is the analysis pipeline: it processes raw data and derived data (mostly derived data) into results.

There is also a `mortality_tests.do` pipeline that runs some unit tests, which verify that our code is working as expected. It does not need to be run to replicate our results.

# Setup for Replication

The code is written in [Stata](http://www.stata.com/), and has been tested in Stata versions 13 and 14.

### Step 1: Download the code

If you are not a git user, you can download a copy of the code by clicking the green **Clone or download** button above and selecting **Download ZIP**. Unzip the file wherever you'd like on your computer. The folder you create will be referred to below as the **root** folder of the mortality project.

If you are a git user, you can clone this repository using your favorite git client.

### Step 2: Download the data

First download the [data-only ZIP file](https://github.com/michaelstepner/healthinequality-code/releases/download/jama2016/health_ineq_replication_dataonly.zip) (1 GB). This contains all the data that you need to run the `mortality_datagen.do` (data generation) and `mortality.do` (analysis) pipeline. You'll need to run each of them to produce the results.

If you wish, you may additionally download the [derived results ZIP file](https://github.com/michaelstepner/healthinequality-code/releases/download/jama2016/health_ineq_replication_derivedresults.zip) (2 GB). This contains all of the derived data and results generated when the code is run to completion. Combined with the data-only ZIP file, you will be able to run any individual code file independently without running the entire pipeline (since all the intermediate files are included). You can also use this file to compare our original results with your replication output.

Each ZIP file you download should be unzipped in the **root** folder of the mortality project. After unzipping, that folder will contain a **code** subfolder and a **data** subfolder (and possibly others).

### Step 3: Configure Stata

1. In Stata, define a global called $mortality_root that contains the path to the root folder for the mortality project on your computer.
	1. Open Stata, and run ``doedit "`c(sysdir_personal)'/profile.do"``. This will open a do-file editor to the **profile.do** file in your PERSONAL folder.
		* Every time Stata is opened, it searches for a do-file named **profile.do** and runs it if the do-file is found. This is a good place to place a command that defines the global $mortality_root, since it will then always be automatically created. Stata looks for **profile.do** in many folders, so there are many options for where to place it.  A good choice is in your Stata PERSONAL directory, which can be found by running `personal` in Stata.
	2. Write a line that says `global mortality_root "<path_to_mortality_root>"`. Save the do-file.
	3. Close Stata and reopen Stata. When it reopens, you should see a line in the Results window that says something like "running [...]/profile.do".
	4. In Stata, if you run `ls "$mortality_root/"`, you should see **code** and **data** among the printed results. If you do, then everything is set up correctly.
2. In Stata, install -project- from the SSC if you haven't already: `ssc install project`
3. Add the data generation and analysis pipelines to -project-
    * Run `project, setup` in Stata, then navigate to **mortality.do** in the **root** folder. Decide whether you want plain-text or SMCL log files, then hit OK.
    * Run `project, setup` again, and choose **mortality_datagen.do** this time.

### Step 4: Run the code

* Run the data generation pipeline by running `project mortality_datagen, build`
	* The data generation pipeline will take a very long time to run from start to finish if you run 1000 bootstrap iterations, which is the number we used for the paper. You can change the number of bootstrap iterations by editing **code/set_bootstrap.do** and changing `global reps 1000`.
* Run the analysis pipeline by running `project mortality, build`
* You can also run individual do-files interactively.

The first time you run a pipeline, it will take some time to generate everything. On subsequent runs, it will only update files whose code or dependencies have changed.

The code for the `mortality_init.do` and `mortality_tests.do` pipelines are included in the replication files for completeness, but you will not be able to run those pipelines. The data files that they process are cannot be posted publicly, so they are not included in the data download ZIP files.

# Addendum: Configuring Julia

In the `mortality_init.do` pipeline, we use a [Julia](http://julialang.org/) program to quickly calculate Gompertz parameters from mortality rates.

**There is no need to install or configure Julia in order on your computer to replicate our results.** The data for the `mortality_init.do` pipeline cannot be posted publicly, so that data is not included in our data ZIP files. And the `mortality_datagen.do` and `mortality.do` pipelines, which you can run by following the instructions above, do not use any Julia code.

Nevertheless, in the name of complete documentation of our data processing, we are including instructions on how to configure Julia to run the `mortality_init.do` pipeline code.

The Julia code for Gompertz estimation under **code/ado/estimate_gompertz.jl** has been tested and run in Julia version 0.6.0 with packages:

- ArgParse 0.5.0
- DataFrames 0.10.0
- Distributions 0.14.0
- GLM 0.7.0

The Julia website has [instructions](https://julialang.org/downloads/) for installing the command line version. If you are using a Mac and have installed [Homebrew](https://brew.sh/), you can install Julia fairly easily by opening a terminal and running `brew cask install julia`.

You will also need to install the required Julia packages. To do so, open julia on the terminal by running `julia`. In the Julia terminal, run:

```
Pkg.add("GLM")
Pkg.add("DataFrames")
Pkg.add("ArgParse")
```

By default, the Gompertz estimation will be performed (very slowly) in Stata. To switch to using Julia for Gompertz estimation, first find out the path to the Julia executable on your computer by opening a terminal and running `which julia`. Then create a file at **code/set_julia.do** with the following contents, replacing `<PATH_TO_JULIA>` with the actual path on your system:

```
global juliapath <PATH_TO_JULIA>
```

