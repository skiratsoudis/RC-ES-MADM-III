# RC-ES MADM III

**RC-ES MADM III** is a reliability-aware, entropy-based multi-attribute decision-support framework developed to support robust ranking, consensus-aware evaluation, rank-stability analysis, and scenario-weighted decision reliability assessment.

This repository provides the computational implementation, case-study input/output workbooks, and figure-generation scripts associated with the RC-ES MADM III computational case study. It is intended to support transparency, reproducibility, and future research use while avoiding disclosure of the full mathematical formulation, which is currently part of a manuscript under publication preparation/review.

---

## Repository contents

```text
RC-ES-MADM-III/
├── app/
│   └── app.R
├── data/
│   ├── input/
│   │   └── RC_ES_MADM_III_Case_Study_Input.xlsx
│   └── output/
│       └── RC_ES_MADM_III_Case_Study_Output.xlsx
├── scripts/
│   └── reproduce_figures_3_to_6.R
├── LICENSE
├── README.md
└── .gitignore
```

### `app/`

The `app/` directory contains the RC-ES MADM III Decision Studio implemented in R/Shiny. The application reads the structured case-study workbook, executes the computational workflow, and produces scenario-level, alternative-level, and portfolio-level decision-support outputs.

### `data/input/`

The `data/input/` directory contains the structured Excel workbook used as input for the computational case study. It includes the case-study alternatives, criteria, scenario definitions, criterion directions, scenario-specific weights, and model settings.

### `data/output/`

The `data/output/` directory contains the exported computational results produced by the RC-ES MADM III Decision Studio. These results include scenario diagnostics, alternative rankings, rank-stability outputs, decision-reliability measures, and benchmark-related outputs.

### `scripts/`

The `scripts/` directory contains the standalone R script used to reproduce the manuscript figures associated with the computational results. The script includes embedded data and does not require reading external Excel files.

---

## Model overview

RC-ES MADM III is designed as a reliability-aware extension of entropy-based multi-attribute decision making. The framework evaluates alternatives not only through aggregate performance ranking, but also through the diagnostic structure that supports the final decision.

The model combines several computational stages:

* preference-aligned normalization of decision matrices;
* entropy-informed objective criterion weighting;
* integration of subjective preference information;
* criterion-similarity and redundancy adjustment;
* performance aggregation and baseline ranking;
* Monte Carlo rank-stability analysis;
* alternative-distinction diagnostics;
* scenario-weighted decision reliability assessment.

The main purpose of the framework is to support decisions where the final ranking must be interpreted together with its stability, robustness, alternative separation, and scenario-dependent reliability.

The full mathematical formulation is intentionally not included in this repository because the associated manuscript is currently under publication preparation/review.

---

## Case-study context

The repository includes a resilient supplier and logistics-partner selection case study. The case study evaluates eight alternatives across ten criteria and six operational scenarios. The scenario design includes baseline operating conditions and stress conditions related to supply disruption, demand surge, cost inflation, sustainability/regulatory pressure, and expert-disagreement stress.

The case study is designed to demonstrate how RC-ES MADM III can identify:

* the leading portfolio-level alternative;
* scenario-dependent preference shifts;
* stable and unstable ranking structures;
* alternatives that are strongly or weakly separated;
* the difference between stable superiority and stable inferiority;
* convergence or divergence with conventional MADM benchmark methods.

---

## How to run the Shiny application

Open R or RStudio and run:

```r
shiny::runApp("app")
```

Alternatively, open the file:

```text
app/app.R
```

and run the application directly from RStudio.

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

The input workbook is located in:

```text
data/input/RC_ES_MADM_III_Case_Study_Input.xlsx
```

---

## How to reproduce the figures

The manuscript figures based on the computational results can be reproduced using the standalone R script located in:

```text
scripts/reproduce_figures_3_to_6.R
```

To run the script in R/RStudio:

```r
source("scripts/reproduce_figures_3_to_6.R")
```

The script produces the following figures:

* Fig. 3: Scenario-level diagnostic profile;
* Fig. 4: Scenario-specific DRI ranking transitions;
* Fig. 5: Scenario-weighted DRI portfolio ranking;
* Fig. 6: Spearman rank correlations with benchmark MADM methods.

The figure-generation script is standalone and contains the required plotting data internally.

---

## Reproducibility note

The repository is intended to reproduce the computational case-study outputs and associated figures. It does not include the full manuscript, unpublished derivations, or complete mathematical exposition of RC-ES MADM III.

Users interested in applying or extending the framework should use the provided Shiny application, input workbook, output workbook, and figure-generation script as the primary reproducibility material.

---

## Citation

A formal citation will be added after the repository is archived and assigned a DOI through Zenodo.

Until then, please cite this repository as:

```text
Kiratsoudis S (2026) RC-ES MADM III: Research software and reproducibility material for a reliability-aware entropy-based multi-attribute decision-support framework. GitHub repository.
```

---

## License

This repository is distributed under the MIT License.

See the `LICENSE` file for details.

---

## Author

**Sideris Kiratsoudis**

Research interests: multi-attribute decision making, entropy-based modelling, robustness analysis, decision reliability, and operations research applications.
