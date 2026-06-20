###############################################################################
# RC-ES MADM III - Manuscript V1 figures (Fig. 3 to Fig. 6 only)
# Fully standalone R script with embedded data
#
# VERSION: LARGE-TEXT / JOURNAL-READABLE
#
# IMPORTANT:
#   - This script intentionally DOES NOT reproduce Fig. 1 or Fig. 2.
#   - Fig. 1 and Fig. 2 are workflow/architecture diagrams and should be prepared
#     separately as publication-quality schematic diagrams/icons.
#   - This script reproduces only Fig. 3, Fig. 4, Fig. 5, and Fig. 6.
#
# Purpose:
#   Reproduce the manuscript plots from V1 without reading Excel, CSV, or any
#   external dataset. All plotting data are embedded below.
#
# Figure numbering follows Manuscript V1:
#   Fig. 3  Scenario-level RS and ADI diagnostic profile
#   Fig. 4  Scenario-specific DRI ranking transitions
#   Fig. 5  Scenario-weighted DRI portfolio ranking
#   Fig. 6  Spearman rank correlations with benchmark MADM methods
#
# Improvements in this version:
#   - Larger base font and axis labels.
#   - Larger numeric labels.
#   - Thicker lines and clearer points.
#   - Legend restored in Fig. 4 to improve readability.
#   - Wider figure defaults to prevent crowding.
#   - Grayscale/pattern-friendly design for journal printing.
#
# Required package:
#   ggplot2
###############################################################################

# -----------------------------------------------------------------------------
# 0. User-adjustable settings
# -----------------------------------------------------------------------------

OUTPUT_DIR <- "RC_ES_MADM_III_V1_manuscript_figures_large_text"
SAVE_FIGURES <- TRUE
SHOW_PLOTS <- TRUE

# Supported export formats: "png", "pdf", "eps", "tiff", "jpg"
# For journal submission, "pdf" or "eps" is best for vector output.
# For Word insertion, "png" at 600 dpi is usually convenient.
EXPORT_FORMAT <- "png"
DPI <- 600

# Larger figure dimensions in inches.
# If figures are still tight in Word, increase FIG_WIDTH and/or FIG_HEIGHT.
FIG_WIDTH <- 8.8
FIG_HEIGHT <- 6.2

# Dedicated sizes for specific figures.
FIG3_WIDTH <- 8.6
FIG3_HEIGHT <- 6.6

FIG4_WIDTH <- 9.6
FIG4_HEIGHT <- 6.4

FIG5_WIDTH <- 9.0
FIG5_HEIGHT <- 6.2

FIG6_WIDTH <- 8.8
FIG6_HEIGHT <- 6.1

# Large-text setting.
# A value of 15–16 generally remains readable after manuscript scaling.
BASE_SIZE <- 15

# Text labels inside the plots.
VALUE_LABEL_SIZE <- 5.0
POINT_LABEL_SIZE <- 5.2

# Keep FALSE for journal-ready files with captions outside the artwork.
# Set TRUE only for internal checking.
INCLUDE_PLOT_TITLES <- FALSE

# Use a generic font by default.
# You may change to "Arial" or "Helvetica" if available on your system.
FONT_FAMILY <- ""

# -----------------------------------------------------------------------------
# 1. Package check
# -----------------------------------------------------------------------------

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is required. Install it with: install.packages('ggplot2')")
}

library(ggplot2)
library(grid)

if (!dir.exists(OUTPUT_DIR) && isTRUE(SAVE_FIGURES)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# -----------------------------------------------------------------------------
# 2. Utility functions
# -----------------------------------------------------------------------------

save_manuscript_figure <- function(plot, fig_no, short_name,
                                   width = FIG_WIDTH, height = FIG_HEIGHT) {
  if (!isTRUE(SAVE_FIGURES)) return(invisible(NULL))

  ext <- tolower(EXPORT_FORMAT)
  file_name <- sprintf("Fig%d_%s.%s", fig_no, short_name, ext)
  out_path <- file.path(OUTPUT_DIR, file_name)

  args <- list(
    filename = out_path,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    bg = "white"
  )

  if (ext %in% c("png", "jpg", "jpeg")) {
    args$dpi <- DPI
    do.call(ggplot2::ggsave, args)
  } else if (ext == "tiff") {
    args$dpi <- DPI
    args$compression <- "lzw"
    do.call(ggplot2::ggsave, args)
  } else if (ext %in% c("pdf", "eps")) {
    do.call(ggplot2::ggsave, args)
  } else {
    stop("Unsupported EXPORT_FORMAT. Use one of: 'png', 'jpg', 'pdf', 'eps', 'tiff'.")
  }

  message("Saved: ", normalizePath(out_path, winslash = "/", mustWork = FALSE))
  invisible(out_path)
}

print_if_requested <- function(plot) {
  if (isTRUE(SHOW_PLOTS)) print(plot)
  invisible(plot)
}

add_optional_title <- function(plot, title_text) {
  if (isTRUE(INCLUDE_PLOT_TITLES)) {
    plot + ggtitle(title_text)
  } else {
    plot
  }
}

wrap_text <- function(x, width = 28) {
  vapply(
    x,
    function(s) paste(strwrap(s, width = width), collapse = "\n"),
    FUN.VALUE = character(1),
    USE.NAMES = FALSE
  )
}

manuscript_theme <- function(base_size = BASE_SIZE) {
  theme_bw(base_size = base_size, base_family = FONT_FAMILY) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0, size = base_size + 1),
      axis.title = element_text(face = "bold", size = base_size),
      axis.text = element_text(color = "black", size = base_size - 1),
      panel.grid.major = element_line(color = "grey85", linewidth = 0.35),
      panel.grid.minor = element_blank(),
      legend.title = element_text(face = "bold", size = base_size - 1),
      legend.text = element_text(size = base_size - 1),
      legend.position = "bottom",
      legend.box = "horizontal",
      strip.background = element_rect(fill = "grey90", color = "grey30", linewidth = 0.35),
      strip.text = element_text(face = "bold", size = base_size - 1),
      plot.margin = margin(12, 18, 12, 12)
    )
}

# -----------------------------------------------------------------------------
# 3. Embedded data from Manuscript V1
# -----------------------------------------------------------------------------

scenario_summary <- data.frame(
  Scenario = factor(c("S0", "S1", "S2", "S3", "S4", "S5"),
                    levels = c("S0", "S1", "S2", "S3", "S4", "S5")),
  ScenarioName = c(
    "Baseline steady-state",
    "Supply-disruption stress",
    "Demand-surge stress",
    "Cost-inflation stress",
    "Sustainability/regulatory stress",
    "Expert-disagreement stress"
  ),
  RS = c(0.8263, 0.9965, 0.5314, 0.7296, 0.8925, 0.9360),
  ADI = c(0.1203, 0.1787, 0.1088, 0.1119, 0.1703, 0.1246),
  TopByScore = c("A4", "A4", "A5", "A1", "A4", "A4"),
  TopByDRI = c("A4", "A4", "A5", "A1", "A4", "A4"),
  TopAlternativeName = c(
    "Premium incumbent supplier",
    "Premium incumbent supplier",
    "Digital platform-enabled 3PL supplier",
    "Regional dual-source integrator",
    "Premium incumbent supplier",
    "Premium incumbent supplier"
  ),
  DRIGapToSecond = c(0.2788, 0.2934, 0.2309, 0.0771, 0.2598, 0.2557)
)

scenario_rankings <- data.frame(
  Alternative = rep(c("A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8"), each = 6),
  Scenario = factor(rep(c("S0", "S1", "S2", "S3", "S4", "S5"), times = 8),
                    levels = c("S0", "S1", "S2", "S3", "S4", "S5")),
  Rank = c(
    2, 2, 5, 1, 2, 2,
    7, 8, 7, 7, 8, 8,
    4, 4, 3, 5, 3, 4,
    1, 1, 4, 2, 1, 1,
    3, 3, 1, 4, 4, 3,
    6, 5, 8, 6, 5, 6,
    5, 6, 2, 3, 6, 5,
    8, 7, 6, 8, 7, 7
  )
)

alternative_names <- data.frame(
  Alternative = c("A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8"),
  AlternativeName = c(
    "Regional dual-source integrator",
    "Low-cost offshore supplier",
    "Nearshore flexible supplier",
    "Premium incumbent supplier",
    "Digital platform-enabled 3PL supplier",
    "Green local manufacturer",
    "High-capacity global supplier",
    "Emergency backup consortium"
  )
)

portfolio_ranking <- data.frame(
  PortfolioRank = 1:8,
  Alternative = c("A4", "A1", "A5", "A3", "A7", "A6", "A8", "A2"),
  AlternativeName = c(
    "Premium incumbent supplier",
    "Regional dual-source integrator",
    "Digital platform-enabled 3PL supplier",
    "Nearshore flexible supplier",
    "High-capacity global supplier",
    "Green local manufacturer",
    "Emergency backup consortium",
    "Low-cost offshore supplier"
  ),
  ScenarioWeightedS = c(0.6400, 0.6182, 0.6027, 0.5644, 0.5251, 0.4881, 0.3845, 0.3413),
  ScenarioWeightedDRI = c(0.5436, 0.3723, 0.3713, 0.3190, 0.2966, 0.2813, 0.2230, 0.1990),
  MeanPFirst = c(0.7343, 0.1107, 0.1353, 0.0023, 0.0173, 0.0000, 0.0000, 0.0000),
  MeanRSi = c(0.7807, 0.7705, 0.7893, 0.8053, 0.7913, 0.8553, 0.8728, 0.8843)
)

benchmark_correlations <- data.frame(
  Scenario = factor(rep(c("S0", "S1", "S2", "S3", "S4", "S5"), each = 3),
                    levels = c("S0", "S1", "S2", "S3", "S4", "S5")),
  Method = factor(rep(c("TOPSIS", "VIKOR", "WASPAS"), times = 6),
                  levels = c("TOPSIS", "VIKOR", "WASPAS")),
  SpearmanRho = c(
    0.357, 0.667, 0.929,
    0.976, 0.690, 0.976,
    0.762, 0.881, 0.762,
    0.262, 0.548, 0.810,
    0.881, 0.762, 0.929,
    0.452, 0.619, 0.929
  )
)

# -----------------------------------------------------------------------------
# 4. Fig. 3 - Scenario-level diagnostic profile: RS and ADI
# -----------------------------------------------------------------------------

make_fig3 <- function() {
  diagnostics_long <- rbind(
    data.frame(Scenario = scenario_summary$Scenario,
               Metric = "Rank stability (RS)",
               Value = scenario_summary$RS),
    data.frame(Scenario = scenario_summary$Scenario,
               Metric = "Alternative distinction (ADI)",
               Value = scenario_summary$ADI)
  )
  diagnostics_long$Metric <- factor(
    diagnostics_long$Metric,
    levels = c("Rank stability (RS)", "Alternative distinction (ADI)")
  )

  p <- ggplot(diagnostics_long, aes(x = Scenario, y = Value)) +
    geom_col(fill = "grey72", color = "black", linewidth = 0.45, width = 0.66) +
    geom_text(aes(label = sprintf("%.3f", Value)),
              vjust = -0.35, size = VALUE_LABEL_SIZE, fontface = "bold") +
    facet_wrap(~ Metric, ncol = 1, scales = "free_y") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.20))) +
    labs(x = "Scenario", y = "Index value") +
    manuscript_theme() +
    theme(
      legend.position = "none",
      panel.spacing = unit(1.2, "lines")
    )

  add_optional_title(p, "Fig. 3. Scenario-level diagnostic profile")
}

fig3 <- make_fig3()
print_if_requested(fig3)
save_manuscript_figure(fig3, 3, "Scenario_Level_Diagnostic_Profile_RS_ADI",
                       width = FIG3_WIDTH, height = FIG3_HEIGHT)

# -----------------------------------------------------------------------------
# 5. Fig. 4 - Scenario-specific DRI ranking transitions
# -----------------------------------------------------------------------------

make_fig4 <- function() {
  # Final-position labels with only alternative IDs for readability.
  label_data <- scenario_rankings[scenario_rankings$Scenario == "S5", ]

  p <- ggplot(scenario_rankings,
              aes(x = Scenario, y = Rank,
                  group = Alternative,
                  linetype = Alternative,
                  shape = Alternative,
                  color = Alternative)) +
    geom_line(linewidth = 0.95) +
    geom_point(size = 3.8, stroke = 1.0) +
    geom_text(
      data = label_data,
      aes(label = Alternative),
      inherit.aes = FALSE,
      x = as.numeric(label_data$Scenario) + 0.12,
      y = label_data$Rank,
      size = POINT_LABEL_SIZE,
      fontface = "bold",
      hjust = 0
    ) +
    scale_y_reverse(breaks = 1:8, limits = c(8.45, 0.65)) +
    scale_x_discrete(expand = expansion(mult = c(0.04, 0.13))) +
    scale_colour_grey(start = 0.05, end = 0.65) +
    scale_linetype_manual(values = c(
      "solid", "dashed", "dotted", "dotdash",
      "longdash", "twodash", "solid", "dashed"
    )) +
    scale_shape_manual(values = c(16, 17, 15, 18, 3, 4, 8, 7)) +
    coord_cartesian(clip = "off") +
    labs(x = "Scenario", y = "DRI rank (1 = best)",
         color = "Alternative", linetype = "Alternative", shape = "Alternative") +
    manuscript_theme(base_size = BASE_SIZE) +
    guides(
      color = guide_legend(nrow = 1),
      linetype = guide_legend(nrow = 1),
      shape = guide_legend(nrow = 1)
    ) +
    theme(
      legend.position = "bottom",
      legend.box = "vertical",
      legend.key.width = unit(1.1, "cm"),
      plot.margin = margin(12, 42, 12, 12)
    )

  add_optional_title(p, "Fig. 4. Scenario-specific DRI ranking transitions")
}

fig4 <- make_fig4()
print_if_requested(fig4)
save_manuscript_figure(fig4, 4, "Scenario_Specific_DRI_Ranking_Transitions",
                       width = FIG4_WIDTH, height = FIG4_HEIGHT)

# -----------------------------------------------------------------------------
# 6. Fig. 5 - Scenario-weighted DRI portfolio ranking
# -----------------------------------------------------------------------------

make_fig5 <- function() {
  df <- portfolio_ranking
  df$AlternativeLabel <- paste0(df$Alternative, " - ", df$AlternativeName)
  df$AlternativeLabelWrapped <- wrap_text(df$AlternativeLabel, width = 34)
  df$AlternativeLabelWrapped <- factor(
    df$AlternativeLabelWrapped,
    levels = rev(df$AlternativeLabelWrapped)
  )

  p <- ggplot(df, aes(x = AlternativeLabelWrapped, y = ScenarioWeightedDRI)) +
    geom_col(fill = "grey65", color = "black", linewidth = 0.45, width = 0.70) +
    geom_text(aes(label = sprintf("%.4f", ScenarioWeightedDRI)),
              hjust = -0.08, size = VALUE_LABEL_SIZE, fontface = "bold") +
    coord_flip(clip = "off") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.22))) +
    labs(x = NULL, y = "Scenario-weighted DRI") +
    manuscript_theme(base_size = BASE_SIZE) +
    theme(
      legend.position = "none",
      axis.text.y = element_text(size = BASE_SIZE - 2, lineheight = 0.92),
      plot.margin = margin(12, 34, 12, 12)
    )

  add_optional_title(p, "Fig. 5. Scenario-weighted DRI portfolio ranking")
}

fig5 <- make_fig5()
print_if_requested(fig5)
save_manuscript_figure(fig5, 5, "Scenario_Weighted_DRI_Portfolio_Ranking",
                       width = FIG5_WIDTH, height = FIG5_HEIGHT)

# -----------------------------------------------------------------------------
# 7. Fig. 6 - Spearman rank correlations with benchmark methods
# -----------------------------------------------------------------------------

make_fig6 <- function() {
  dodge <- position_dodge(width = 0.76)

  p <- ggplot(benchmark_correlations,
              aes(x = Scenario, y = SpearmanRho, fill = Method)) +
    geom_col(position = dodge, width = 0.64,
             color = "black", linewidth = 0.35) +
    geom_text(aes(label = sprintf("%.3f", SpearmanRho)),
              position = dodge,
              vjust = -0.25,
              size = 4.4,
              fontface = "bold") +
    geom_hline(yintercept = 0, linewidth = 0.35) +
    scale_fill_grey(start = 0.25, end = 0.82) +
    scale_y_continuous(
      limits = c(0, 1.12),
      breaks = seq(0, 1, 0.2),
      expand = expansion(mult = c(0, 0.03))
    ) +
    labs(x = "Scenario", y = "Spearman rank correlation",
         fill = "Benchmark method") +
    manuscript_theme(base_size = BASE_SIZE) +
    theme(
      legend.position = "bottom",
      legend.key.width = unit(1.2, "cm")
    )

  add_optional_title(p, "Fig. 6. Spearman correlations with benchmark MADM methods")
}

fig6 <- make_fig6()
print_if_requested(fig6)
save_manuscript_figure(fig6, 6, "Benchmark_Spearman_Rank_Correlations",
                       width = FIG6_WIDTH, height = FIG6_HEIGHT)

# -----------------------------------------------------------------------------
# 8. Optional: export embedded data tables used for plots as R objects
# -----------------------------------------------------------------------------

embedded_data <- list(
  scenario_summary = scenario_summary,
  scenario_rankings = scenario_rankings,
  portfolio_ranking = portfolio_ranking,
  benchmark_correlations = benchmark_correlations,
  alternative_names = alternative_names
)

message("\nAll requested manuscript figures (Fig. 3 to Fig. 6) have been generated with embedded data.")
message("Fig. 1 and Fig. 2 are intentionally excluded from this R script.")
message("Output directory: ", normalizePath(OUTPUT_DIR, winslash = "/", mustWork = FALSE))
message("Figure order produced by this script: Fig3, Fig4, Fig5, Fig6.")
message("Large-text version: BASE_SIZE = ", BASE_SIZE,
        ", VALUE_LABEL_SIZE = ", VALUE_LABEL_SIZE,
        ", POINT_LABEL_SIZE = ", POINT_LABEL_SIZE, ".")

###############################################################################
# End of script
###############################################################################
