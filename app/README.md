# RC-ES MADM III Decision Studio

This directory contains the R/Shiny application used to execute the RC-ES MADM III computational workflow.

The application provides an interactive decision-support environment for loading the structured case-study workbook, running the model, and exporting scenario-level, alternative-level, and portfolio-level results. It is intended to support reproducible experimentation with the RC-ES MADM III framework without exposing the complete unpublished mathematical formulation of the model.

## Main file

```text
RC_ES_MADM_III_Decision_Studio_V.1.0.0.R
```

## Main functions of the application

The Decision Studio supports:

* loading structured Excel input workbooks;
* validating the required workbook structure;
* processing alternatives, criteria, scenarios, and criterion directions;
* applying the RC-ES MADM III computational workflow;
* producing scenario-level diagnostics;
* generating alternative rankings and portfolio-level outputs;
* exporting computational results for further analysis and visualization.

## How to run

From the root directory of the repository, run:

```r
shiny::runApp("app")
```

Alternatively, open `app/app.R` in RStudio and press **Run App**.

## Required R packages

The application requires the following R packages:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "readxl",
  "openxlsx",
  "dplyr",
  "tidyr",
  "ggplot2",
  "DT",
  "plotly"
))
```

## Input workbook

The application is designed to work with the case-study input workbook located in:

```text
data/input/RC_ES_MADM_III_Case_Study_Input.xlsx
```

Users may create additional input workbooks following the same structure.
