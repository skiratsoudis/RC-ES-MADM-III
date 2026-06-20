# RC-ES MADM III

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20772360.svg)](https://doi.org/10.5281/zenodo.20772360)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![R](https://img.shields.io/badge/R-software-blue)

**RC-ES MADM III** is a reliability-aware, entropy-based multi-attribute decision-support framework developed to support robust ranking, consensus-aware evaluation, rank-stability analysis, alternative-distinction diagnostics, and scenario-weighted decision reliability assessment.

This repository provides the computational implementation, case-study input/output workbooks, and figure-generation scripts associated with the RC-ES MADM III computational case study. It is intended to support transparency, reproducibility, and future research use while avoiding disclosure of the full mathematical formulation, which is currently part of a manuscript under publication preparation/review.

---

## Repository contents

```text
RC-ES-MADM-III/
├── app/
│   ├── RC_ES_MADM_III_Decision_Studio_V.1.0.0.R
│   └── README.md
├── data/
│   ├── input/
│   │   └── RC_ES_MADM_III_Case_Study_Input.xlsx
│   ├── output/
│   │   └── RC_ES_MADM_III_Case_Study_Output.xlsx
│   └── README.md
├── scripts/
│   ├── RC_ES_MADM_III_V.1.0.0_Figures_3_to_6_EMBEDDED_DATA.R
│   └── README.md
├── .gitignore
├── LICENSE
└── README.md
```

---

## Model and case-study overview

RC-ES MADM III is designed as a reliability-aware, entropy-based multi-attribute decision-support framework for evaluating and ranking alternatives under heterogeneous criteria, scenario uncertainty, and robustness requirements. The framework extends conventional multi-attribute ranking by treating the final ordering of alternatives not as an isolated output, but as part of a broader decision profile that also considers ranking stability, consensus structure, alternative separation, and scenario-weighted decision reliability.

The model follows a structured computational logic. The decision problem is represented through alternatives, evaluation criteria, criterion directions, scenario definitions, subjective preference information, and scenario-dependent performance data. The raw decision matrices are transformed into preference-aligned normalized representations, allowing cost-type and benefit-type criteria to be evaluated on a comparable basis. The framework then integrates information extracted from the decision data with subjective preference information provided by the decision maker or expert group.

A central feature of RC-ES MADM III is its consensus-aware and robustness-oriented diagnostic layer. Beyond computing baseline performance scores and rankings, the framework evaluates the stability of the ranking structure under perturbation, the probability of each alternative maintaining the first position, and the degree to which alternatives are clearly separated from one another. This distinction is important because a ranking may be numerically valid but practically fragile when the leading alternative is only marginally superior, highly sensitive to input changes, or weakly separated from close competitors.

The computational case study included in this repository concerns a resilient supplier and logistics-partner selection problem. The case study evaluates eight candidate alternatives across ten criteria and six operational scenarios. The alternatives represent different sourcing and logistics configurations, including regional, offshore, nearshore, incumbent, digital-platform-enabled, green local, high-capacity global, and emergency-backup profiles. The criteria cover cost, lead time, delivery reliability, quality conformity, scalability, disruption recovery, financial resilience, digital traceability, carbon footprint, and strategic dependence risk.

The scenario structure is designed to test the behaviour of the model under different operational conditions. It includes a baseline steady-state scenario and five stress scenarios related to supply disruption, demand surge, cost inflation, sustainability/regulatory pressure, and expert-disagreement conditions. This structure allows the framework to examine whether the preferred alternative remains reliable across changing assumptions, whether specific alternatives become more attractive under particular stress regimes, and whether the final portfolio-level ranking is supported by adequate stability and separation evidence.

---

## Directory description

### `app/`

The `app/` directory contains the RC-ES MADM III Decision Studio implemented in R/Shiny. The application reads the structured case-study workbook, executes the computational workflow, and produces scenario-level, alternative-level, and portfolio-level decision-support outputs.

Main file:

```text
app/RC_ES_MADM_III_Decision_Studio_V.1.0.0.R
```

### `data/input/`

The `data/input/` directory contains the structured Excel workbook used as input for the computational case study. It includes the case-study alternatives, criteria, scenario definitions, criterion directions, scenario-specific weights, raw performance values, and model settings.

Main file:

```text
data/input/RC_ES_MADM_III_Case_Study_Input.xlsx
```

### `data/output/`

The `data/output/` directory contains the exported computational results produced by the RC-ES MADM III Decision Studio. These results include scenario diagnostics, alternative rankings, rank-stability outputs, decision-reliability measures, scenario-weighted outputs, and benchmark-related results.

Main file:

```text
data/output/RC_ES_MADM_III_Case_Study_Output.xlsx
```

### `scripts/`

The `scripts/` directory contains the standalone R script used to reproduce the result-based figures associated with the computational case study. The script includes embedded data and does not require reading external Excel files.

Main file:

```text
scripts/RC_ES_MADM_III_V.1.0.0_Figures_3_to_6_EMBEDDED_DATA.R
```

---

## Computational scope

The repository supports reproducible inspection of the following computational components:

* preference-aligned normalization of decision matrices;
* entropy-informed criterion weighting;
* integration of subjective preference information;
* criterion-similarity and redundancy adjustment;
* performance aggregation and baseline ranking;
* Monte Carlo rank-stability analysis;
* alternative-distinction diagnostics;
* scenario-weighted decision reliability assessment;
* benchmark-oriented comparative interpretation.

The complete mathematical formulation is intentionally not included in this repository because the associated manuscript is currently under publication preparation/review.

---

## How to run the Shiny application

Open the following file in RStudio:

```text
app/RC_ES_MADM_III_Decision_Studio_V.1.0.0.R
```

Then run the application directly from RStudio.

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

The case-study input workbook is located in:

```text
data/input/RC_ES_MADM_III_Case_Study_Input.xlsx
```

---

## How to reproduce the figures

The result-based manuscript figures can be reproduced using the standalone R script located in:

```text
scripts/RC_ES_MADM_III_V.1.0.0_Figures_3_to_6_EMBEDDED_DATA.R
```

To run the script in R/RStudio:

```r
source("scripts/RC_ES_MADM_III_V.1.0.0_Figures_3_to_6_EMBEDDED_DATA.R")
```

The script produces the following figures:

* **Fig. 3**: Scenario-level diagnostic profile;
* **Fig. 4**: Scenario-specific DRI ranking transitions;
* **Fig. 5**: Scenario-weighted DRI portfolio ranking;
* **Fig. 6**: Spearman rank correlations with benchmark MADM methods.

The script is fully standalone and contains the required plotting data internally.

---

## Reproducibility note

This repository is intended to reproduce the computational case-study outputs and associated result-based figures. It does not include the full manuscript, unpublished derivations, or complete mathematical exposition of RC-ES MADM III.

Users interested in applying or extending the framework should use the provided Shiny application, input workbook, output workbook, and figure-generation script as the primary reproducibility material.

---

## DOI

This repository has been archived on Zenodo.

**DOI:** [10.5281/zenodo.20772360](https://doi.org/10.5281/zenodo.20772360)

---

## Citation

If you use this repository, software, case-study material, or figure-generation scripts, please cite:

```text
Kiratsoudis S (2026) RC-ES MADM III: Research software and reproducibility material for a reliability-aware entropy-based multi-attribute decision-support framework. Zenodo. https://doi.org/10.5281/zenodo.20772360
```

BibTeX entry:

```bibtex
@software{kiratsoudis_2026_rc_es_madm_iii,
  author       = {Kiratsoudis, Sideris},
  title        = {{RC-ES MADM III: Research software and reproducibility material for a reliability-aware entropy-based multi-attribute decision-support framework}},
  year         = {2026},
  publisher    = {Zenodo},
  doi          = {10.5281/zenodo.20772360},
  url          = {https://doi.org/10.5281/zenodo.20772360}
}
```

---

## License

This repository is distributed under the MIT License.

See the `LICENSE` file for details.

---

## Author

**Sideris Kiratsoudis**

Research interests: multi-attribute decision making, entropy-based modelling, robustness analysis, decision reliability, and operations research applications.
