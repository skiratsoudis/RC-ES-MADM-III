###############################################################################
# RC-ES MADM III Decision Studio
# Version: 1.0.0
#
# Research software for the Robust Consensus Entropy-Synergy Multi-Attribute
# Decision-Making III (RC-ES MADM III) framework.
#
# Purpose:
#   - Import structured Excel workbooks for multi-scenario MADM analysis.
#   - Compute normalized performance matrices, entropy-informed criterion weights,
#     consensus/redundancy-adjusted weights, alternative scores, rank-stability
#     diagnostics, alternative-distinction diagnostics, and Decision Reliability
#     Index (DRI) profiles.
#   - Export reproducible case-study outputs in Excel format.
#
# Repository note:
#   This application provides the computational implementation used for the
#   reproducible case-study material. The full mathematical exposition is reserved
#   for the associated manuscript.
#
# Author: Sideris Kiratsoudis
# License: MIT
###############################################################################

required_packages <- c(
  "shiny",
  "shinythemes",
  "readxl",
  "writexl",
  "ggplot2",
  "DT",
  "dplyr"
)

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    "Missing required package(s): ", paste(missing_packages, collapse = ", "),
    ". Install them with install.packages(c(",
    paste(sprintf('\"%s\"', missing_packages), collapse = ", "),
    ")).",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  invisible(lapply(required_packages, library, character.only = TRUE))
})


`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x
EPS <- 1e-12
APP_VERSION <- "1.0.0"
APP_NAME <- "RC-ES MADM III Decision Studio"

# -----------------------------------------------------------------------------
# Numeric utilities
# -----------------------------------------------------------------------------

as_num <- function(x, default = NA_real_) {
  out <- suppressWarnings(as.numeric(x))
  out[!is.finite(out)] <- default
  out
}

as_chr <- function(x) trimws(as.character(x))

safe_scalar <- function(x, default = 0) {
  if (is.null(x) || length(x) == 0) return(default)
  out <- suppressWarnings(as.numeric(x[1]))
  if (!is.finite(out)) default else out
}

safe_chr_scalar <- function(x, default = "") {
  if (is.null(x) || length(x) == 0) return(default)
  out <- suppressWarnings(as.character(x[1]))
  if (length(out) == 0 || is.na(out) || !nzchar(trimws(out))) return(default)
  trimws(out)
}

safe_bool <- function(x, default = FALSE) {
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return(default)
  val <- tolower(trimws(as.character(x[1])))
  val %in% c("true", "t", "yes", "y", "1")
}

clamp01 <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x[!is.finite(x)] <- 0
  pmin(1, pmax(0, x))
}

renorm_simplex <- function(x, eps = EPS) {
  nms <- names(x)
  x <- as.numeric(x)
  x[!is.finite(x)] <- 0
  x <- pmax(x, 0)
  s <- sum(x)
  if (!is.finite(s) || s <= eps) {
    out <- rep(1 / length(x), length(x))
    names(out) <- nms
    return(out)
  }
  out <- x / s
  names(out) <- nms
  out
}

entropy_base2 <- function(p, eps = EPS, normalize = TRUE) {
  p <- as.numeric(p)
  p[!is.finite(p)] <- 0
  p <- pmax(p, 0)
  if (normalize) p <- renorm_simplex(p, eps)
  nz <- p > eps
  if (!any(nz)) return(0)
  -sum(p[nz] * log2(p[nz]))
}

rank_positions <- function(scores) {
  rank(-scores, ties.method = "min")
}

rescale_unit <- function(x) {
  x <- as.numeric(x)
  x[!is.finite(x)] <- 0
  mn <- min(x, na.rm = TRUE)
  mx <- max(x, na.rm = TRUE)
  if (!is.finite(mx - mn) || abs(mx - mn) <= EPS) return(rep(1, length(x)))
  clamp01((x - mn) / (mx - mn))
}

# -----------------------------------------------------------------------------
# Workbook reader
# -----------------------------------------------------------------------------

read_settings <- function(path) {
  sheets <- excel_sheets(path)
  if (!("Settings" %in% sheets)) return(list())
  raw <- read_excel(path, sheet = "Settings") %>% as.data.frame()
  if (!all(c("Parameter", "Value") %in% names(raw))) return(list())
  vals <- as.list(raw$Value)
  names(vals) <- raw$Parameter
  vals
}

get_setting_num <- function(settings, key, default) {
  safe_scalar(settings[[key]] %||% default, default)
}

get_setting_chr <- function(settings, key, default) {
  safe_chr_scalar(settings[[key]] %||% default, default)
}

get_setting_bool <- function(settings, key, default) {
  safe_bool(settings[[key]] %||% default, default)
}

read_rc_workbook <- function(path) {
  sheets <- excel_sheets(path)
  required <- c("Settings", "Criteria", "Alternatives", "DecisionMatrix")
  missing <- setdiff(required, sheets)
  if (length(missing) > 0) stop("Missing required sheet(s): ", paste(missing, collapse = ", "), ". Required sheets are: Settings, Criteria, Alternatives, DecisionMatrix.")

  settings <- read_settings(path)

  criteria <- read_excel(path, sheet = "Criteria") %>% as.data.frame()
  alternatives <- read_excel(path, sheet = "Alternatives") %>% as.data.frame()
  decision <- read_excel(path, sheet = "DecisionMatrix") %>% as.data.frame()

  if (!("ScenarioID" %in% names(criteria))) criteria$ScenarioID <- "S1"
  if (!("ScenarioID" %in% names(alternatives))) alternatives$ScenarioID <- "S1"
  if (!("ScenarioID" %in% names(decision))) decision$ScenarioID <- "S1"

  required_criteria <- c("CriterionID", "Type")
  required_alternatives <- c("AlternativeID")
  required_decision <- c("AlternativeID", "CriterionID", "Value")
  if (length(setdiff(required_criteria, names(criteria))) > 0) stop("Criteria sheet must include CriterionID and Type.")
  if (length(setdiff(required_alternatives, names(alternatives))) > 0) stop("Alternatives sheet must include AlternativeID.")
  if (length(setdiff(required_decision, names(decision))) > 0) stop("DecisionMatrix sheet must include AlternativeID, CriterionID, and Value.")

  if (!("CriterionName" %in% names(criteria))) criteria$CriterionName <- criteria$CriterionID
  if (!("SubjectiveWeight" %in% names(criteria))) criteria$SubjectiveWeight <- NA_real_
  if (!("AlternativeName" %in% names(alternatives))) alternatives$AlternativeName <- alternatives$AlternativeID

  criteria$ScenarioID <- as_chr(criteria$ScenarioID)
  criteria$CriterionID <- as_chr(criteria$CriterionID)
  criteria$CriterionName <- as_chr(criteria$CriterionName)
  criteria$Type <- tolower(as_chr(criteria$Type))
  criteria$SubjectiveWeight <- as_num(criteria$SubjectiveWeight, NA_real_)

  alternatives$ScenarioID <- as_chr(alternatives$ScenarioID)
  alternatives$AlternativeID <- as_chr(alternatives$AlternativeID)
  alternatives$AlternativeName <- as_chr(alternatives$AlternativeName)

  decision$ScenarioID <- as_chr(decision$ScenarioID)
  decision$AlternativeID <- as_chr(decision$AlternativeID)
  decision$CriterionID <- as_chr(decision$CriterionID)
  decision$Value <- as_num(decision$Value, NA_real_)

  scenario_probs <- NULL
  if ("ScenarioProbabilities" %in% sheets) {
    scenario_probs <- read_excel(path, sheet = "ScenarioProbabilities") %>% as.data.frame()
    if (nrow(scenario_probs) > 0 && all(c("ScenarioID", "Probability") %in% names(scenario_probs))) {
      scenario_probs$ScenarioID <- as_chr(scenario_probs$ScenarioID)
      scenario_probs$Probability <- pmax(0, as_num(scenario_probs$Probability, 0))
    } else {
      scenario_probs <- NULL
    }
  }

  scenario_ids <- unique(decision$ScenarioID)
  scenario_ids <- scenario_ids[!is.na(scenario_ids) & nzchar(scenario_ids)]

  list(
    path = path,
    workbook = tools::file_path_sans_ext(basename(path)),
    settings = settings,
    criteria = criteria,
    alternatives = alternatives,
    decision = decision,
    scenario_probs = scenario_probs,
    scenario_ids = scenario_ids
  )
}

scenario_rows <- function(df, scenario_id) {
  if (!("ScenarioID" %in% names(df))) return(df)
  out <- df[df$ScenarioID %in% c(scenario_id, "ALL", "All", "all", ""), , drop = FALSE]
  if (nrow(out) == 0) out <- df[df$ScenarioID == scenario_id, , drop = FALSE]
  out
}

scenario_probability <- function(obj, scenario_id) {
  sp <- obj$scenario_probs
  if (is.null(sp) || nrow(sp) == 0) return(1)
  val <- sp$Probability[sp$ScenarioID == scenario_id]
  if (length(val) == 0 || !is.finite(val[1])) return(1)
  max(0, val[1])
}

# -----------------------------------------------------------------------------
# RC-ES-MADM III core computations
# -----------------------------------------------------------------------------

normalize_matrix <- function(X, types, method = "minmax") {
  method <- tolower(trimws(method %||% "minmax"))
  X <- as.matrix(X)
  m <- nrow(X)
  n <- ncol(X)
  R <- matrix(0, nrow = m, ncol = n, dimnames = dimnames(X))

  for (j in seq_len(n)) {
    x <- as.numeric(X[, j])
    x[!is.finite(x)] <- NA_real_
    if (any(is.na(x))) stop("Missing or non-finite value in criterion ", colnames(X)[j], ".")

    type_j <- tolower(trimws(types[j]))
    is_cost <- type_j %in% c("cost", "c", "negative", "min")

    if (method == "vector") {
      valid <- if (is_cost) all(x > 0) else TRUE
      if (valid) {
        v <- if (is_cost) 1 / x else x
        denom <- sqrt(sum(v^2))
        if (is.finite(denom) && denom > EPS) {
          R[, j] <- rescale_unit(v / denom)
        } else {
          R[, j] <- rep(1, m)
        }
      } else {
        R[, j] <- normalize_matrix(X[, j, drop = FALSE], types[j], "minmax")[, 1]
      }
    } else if (method == "ratio") {
      if (!is_cost && max(x) > EPS && min(x) >= 0) {
        R[, j] <- clamp01(x / max(x))
      } else if (is_cost && all(x > EPS) && min(x) >= 0) {
        R[, j] <- clamp01(min(x) / x)
      } else {
        R[, j] <- normalize_matrix(X[, j, drop = FALSE], types[j], "minmax")[, 1]
      }
    } else {
      mn <- min(x)
      mx <- max(x)
      if (!is.finite(mx - mn) || abs(mx - mn) <= EPS) {
        R[, j] <- rep(1, m)
      } else if (is_cost) {
        R[, j] <- (mx - x) / (mx - mn)
      } else {
        R[, j] <- (x - mn) / (mx - mn)
      }
      R[, j] <- clamp01(R[, j])
    }
  }

  R
}

proportion_matrix <- function(R) {
  R <- as.matrix(R)
  m <- nrow(R)
  n <- ncol(R)
  P <- matrix(0, nrow = m, ncol = n, dimnames = dimnames(R))
  for (j in seq_len(n)) {
    s <- sum(R[, j], na.rm = TRUE)
    if (!is.finite(s) || s <= EPS) {
      P[, j] <- rep(1 / m, m)
    } else {
      P[, j] <- pmax(R[, j], 0) / s
    }
  }
  P
}

combine_preliminary_weights <- function(wE, wS, alpha, beta) {
  alpha <- max(0, safe_scalar(alpha, 1))
  beta <- max(0, safe_scalar(beta, 1))
  if (alpha + beta <= EPS) alpha <- 1

  raw <- rep(1, length(wE))
  if (alpha > EPS) raw <- raw * (pmax(wE, 0) ^ alpha)
  if (beta > EPS) raw <- raw * (pmax(wS, 0) ^ beta)

  if (sum(raw) <= EPS) {
    raw <- alpha * pmax(wE, 0) + beta * pmax(wS, 0)
  }
  renorm_simplex(raw)
}

compute_rc_scenario <- function(obj, scenario_id, overrides = list()) {
  settings <- obj$settings

  alpha <- safe_scalar(overrides$alpha %||% get_setting_num(settings, "Alpha", 1), 1)
  beta <- safe_scalar(overrides$beta %||% get_setting_num(settings, "Beta", 1), 1)
  eta <- min(1, max(0, safe_scalar(overrides$eta %||% get_setting_num(settings, "Eta", 1), 1)))
  B <- max(1, as.integer(round(safe_scalar(overrides$B %||% get_setting_num(settings, "B", 1000), 1000))))
  deltaR <- min(1, max(0, safe_scalar(overrides$deltaR %||% get_setting_num(settings, "DeltaR", 0.03), 0.03)))
  deltaW <- min(0.999, max(0, safe_scalar(overrides$deltaW %||% get_setting_num(settings, "DeltaW", 0.10), 0.10)))
  include_norm <- safe_bool(overrides$includeNorm %||% get_setting_chr(settings, "IncludeNormalizationSensitivity", "FALSE"), FALSE)
  seed <- as.integer(round(safe_scalar(overrides$seed %||% get_setting_num(settings, "RandomSeed", 1234), 1234)))

  lambdas <- c(
    safe_scalar(overrides$lambda1 %||% get_setting_num(settings, "Lambda1", 0.40), 0.40),
    safe_scalar(overrides$lambda2 %||% get_setting_num(settings, "Lambda2", 0.25), 0.25),
    safe_scalar(overrides$lambda3 %||% get_setting_num(settings, "Lambda3", 0.20), 0.20),
    safe_scalar(overrides$lambda4 %||% get_setting_num(settings, "Lambda4", 0.15), 0.15)
  )
  lambdas <- renorm_simplex(lambdas)

  crit <- scenario_rows(obj$criteria, scenario_id)
  alt <- scenario_rows(obj$alternatives, scenario_id)
  dec <- scenario_rows(obj$decision, scenario_id)

  crit <- crit[!duplicated(crit$CriterionID), , drop = FALSE]
  alt <- alt[!duplicated(alt$AlternativeID), , drop = FALSE]

  if (nrow(alt) < 2) stop("Scenario ", scenario_id, " must contain at least two alternatives.")
  if (nrow(crit) < 1) stop("Scenario ", scenario_id, " must contain at least one criterion.")

  crit_ids <- crit$CriterionID
  alt_ids <- alt$AlternativeID
  m <- length(alt_ids)
  n <- length(crit_ids)

  X <- matrix(NA_real_, nrow = m, ncol = n, dimnames = list(alt_ids, crit_ids))
  for (rr in seq_len(nrow(dec))) {
    aid <- dec$AlternativeID[rr]
    cid <- dec$CriterionID[rr]
    if (aid %in% alt_ids && cid %in% crit_ids) {
      X[aid, cid] <- dec$Value[rr]
    }
  }
  if (any(is.na(X))) stop("Scenario ", scenario_id, " has missing AlternativeID-CriterionID values in DecisionMatrix.")

  types <- crit$Type
  R <- normalize_matrix(X, types, method = "minmax")
  P <- proportion_matrix(R)

  E <- numeric(n)
  D <- numeric(n)
  for (j in seq_len(n)) {
    E[j] <- entropy_base2(P[, j], normalize = FALSE) / log2(m)
    D[j] <- 1 - E[j]
  }

  wE <- if (sum(D) <= EPS) rep(1 / n, n) else renorm_simplex(D)
  wS_raw <- crit$SubjectiveWeight
  wS_raw[!is.finite(wS_raw)] <- 0
  wS <- renorm_simplex(wS_raw)
  wbar <- combine_preliminary_weights(wE, wS, alpha, beta)

  JSD <- matrix(0, nrow = n, ncol = n, dimnames = list(crit_ids, crit_ids))
  CS <- matrix(1, nrow = n, ncol = n, dimnames = list(crit_ids, crit_ids))
  for (j in seq_len(n)) {
    for (k in seq_len(n)) {
      mid <- 0.5 * (P[, j] + P[, k])
      JSD[j, k] <- entropy_base2(mid, normalize = FALSE) -
        0.5 * entropy_base2(P[, j], normalize = FALSE) -
        0.5 * entropy_base2(P[, k], normalize = FALSE)
      JSD[j, k] <- min(1, max(0, JSD[j, k]))
      CS[j, k] <- 1 - JSD[j, k]
    }
  }

  if (n > 1) {
    rho <- sapply(seq_len(n), function(j) mean(CS[j, -j]))
  } else {
    rho <- 0
  }
  g <- 1 - eta * rho
  g <- pmax(0, g)
  raw_final <- wbar * g
  w <- if (sum(raw_final) <= EPS) wbar else renorm_simplex(raw_final)

  Q <- sweep(R, 2, w, "*")
  S <- as.numeric(Q %*% rep(1, n))
  names(S) <- alt_ids
  rankS <- rank_positions(S)

  # Robustness replications
  set.seed(seed + sum(utf8ToInt(scenario_id)))
  rank_counts <- matrix(0, nrow = m, ncol = m, dimnames = list(alt_ids, paste0("Rank_", seq_len(m))))
  methods <- c("minmax", "vector", "ratio")

  for (b in seq_len(B)) {
    baseR <- R
    if (isTRUE(include_norm)) {
      baseR <- normalize_matrix(X, types, method = sample(methods, 1))
    }
    Rhat <- clamp01(as.vector(baseR) + runif(m * n, -deltaR, deltaR))
    Rhat <- matrix(Rhat, nrow = m, ncol = n, dimnames = dimnames(R))
    u <- w * (1 + runif(n, -deltaW, deltaW))
    wb <- renorm_simplex(u)
    Srep <- as.numeric(Rhat %*% wb)
    rb <- rank_positions(Srep)
    for (i in seq_len(m)) {
      rank_counts[i, rb[i]] <- rank_counts[i, rb[i]] + 1
    }
  }

  rank_probs <- rank_counts / B
  P_first <- rank_probs[, 1]
  RS_i <- sapply(seq_len(m), function(i) rank_probs[i, rankS[i]])
  RS <- mean(RS_i)

  Delta <- sapply(seq_len(m), function(i) min(abs(S[i] - S[-i])))
  score_distance <- abs(outer(S, S, "-"))
  ADI <- 2 / (m * (m - 1)) * sum(score_distance[upper.tri(score_distance)])

  DRI <- lambdas[1] * S + lambdas[2] * P_first + lambdas[3] * S * RS_i + lambdas[4] * S * Delta
  DRI <- clamp01(DRI)
  rankDRI <- rank_positions(DRI)

  theta <- scenario_probability(obj, scenario_id)

  profile <- data.frame(
    Workbook = obj$workbook,
    ScenarioID = scenario_id,
    ScenarioProbability = theta,
    AlternativeID = alt_ids,
    AlternativeName = alt$AlternativeName,
    S = S,
    Rank_S = rankS,
    P_First = as.numeric(P_first),
    RS_i = as.numeric(RS_i),
    Delta = as.numeric(Delta),
    DRI = as.numeric(DRI),
    Rank_DRI = rankDRI,
    stringsAsFactors = FALSE
  )

  scenario_summary <- data.frame(
    Workbook = obj$workbook,
    ScenarioID = scenario_id,
    ScenarioProbability = theta,
    Alternatives = m,
    Criteria = n,
    B = B,
    DeltaR = deltaR,
    DeltaW = deltaW,
    IncludeNormalizationSensitivity = include_norm,
    RS = RS,
    ADI = ADI,
    TopByS = alt_ids[which.min(rankS)],
    TopByDRI = alt_ids[which.min(rankDRI)],
    TopByS_Name = alt$AlternativeName[which.min(rankS)],
    TopByDRI_Name = alt$AlternativeName[which.min(rankDRI)],
    stringsAsFactors = FALSE
  )

  weights_df <- data.frame(
    Workbook = obj$workbook,
    ScenarioID = scenario_id,
    CriterionID = crit_ids,
    CriterionName = crit$CriterionName,
    Type = crit$Type,
    E = E,
    D = D,
    w_E = as.numeric(wE),
    w_S = as.numeric(wS),
    w_bar = as.numeric(wbar),
    rho = as.numeric(rho),
    g = as.numeric(g),
    w = as.numeric(w),
    stringsAsFactors = FALSE
  )

  norm_df <- do.call(rbind, lapply(seq_len(m), function(i) {
    data.frame(
      Workbook = obj$workbook,
      ScenarioID = scenario_id,
      AlternativeID = alt_ids[i],
      AlternativeName = alt$AlternativeName[i],
      CriterionID = crit_ids,
      CriterionName = crit$CriterionName,
      X = as.numeric(X[i, ]),
      R = as.numeric(R[i, ]),
      p_ij = as.numeric(P[i, ]),
      q_ij = as.numeric(Q[i, ]),
      stringsAsFactors = FALSE
    )
  }))

  rank_prob_df <- do.call(rbind, lapply(seq_len(m), function(i) {
    data.frame(
      Workbook = obj$workbook,
      ScenarioID = scenario_id,
      AlternativeID = alt_ids[i],
      AlternativeName = alt$AlternativeName[i],
      Rank = seq_len(m),
      Probability = as.numeric(rank_probs[i, ]),
      stringsAsFactors = FALSE
    )
  }))

  consensus_df <- do.call(rbind, lapply(seq_len(n), function(j) {
    data.frame(
      Workbook = obj$workbook,
      ScenarioID = scenario_id,
      Criterion_j = crit_ids[j],
      Criterion_j_Name = crit$CriterionName[j],
      Criterion_k = crit_ids,
      Criterion_k_Name = crit$CriterionName,
      JSD = as.numeric(JSD[j, ]),
      CS = as.numeric(CS[j, ]),
      stringsAsFactors = FALSE
    )
  }))

  settings_used <- data.frame(
    Workbook = obj$workbook,
    ScenarioID = scenario_id,
    Parameter = c("Alpha", "Beta", "Eta", "B", "DeltaR", "DeltaW", "IncludeNormalizationSensitivity", "RandomSeed", "Lambda1", "Lambda2", "Lambda3", "Lambda4"),
    Value = c(alpha, beta, eta, B, deltaR, deltaW, include_norm, seed, lambdas[1], lambdas[2], lambdas[3], lambdas[4]),
    stringsAsFactors = FALSE
  )

  list(
    workbook = obj$workbook,
    scenario = scenario_id,
    summary = scenario_summary,
    profile = profile,
    weights = weights_df,
    normalized = norm_df,
    rank_probabilities = rank_prob_df,
    consensus = consensus_df,
    settings_used = settings_used
  )
}

portfolio_scores <- function(profiles) {
  if (is.null(profiles) || nrow(profiles) == 0) return(data.frame())
  profiles <- profiles %>%
    mutate(ScenarioProbability = ifelse(is.finite(ScenarioProbability), ScenarioProbability, 1))
  profiles %>%
    group_by(AlternativeID, AlternativeName) %>%
    summarise(
      ScenarioWeighted_S = sum(ScenarioProbability * S) / sum(ScenarioProbability),
      ScenarioWeighted_DRI = sum(ScenarioProbability * DRI) / sum(ScenarioProbability),
      Mean_P_First = mean(P_First),
      Mean_RS_i = mean(RS_i),
      Scenarios = n(),
      .groups = "drop"
    ) %>%
    mutate(Rank_SW_DRI = rank(-ScenarioWeighted_DRI, ties.method = "min")) %>%
    arrange(Rank_SW_DRI)
}

# -----------------------------------------------------------------------------
# UI helpers
# -----------------------------------------------------------------------------

metric_card <- function(icon_name, title, value, subtitle, color = "#1f4e79") {
  div(class = "metric-card", style = paste0("border-top: 4px solid ", color, ";"),
      div(class = "metric-icon", icon(icon_name)),
      div(class = "metric-title", title),
      div(class = "metric-value", value),
      div(class = "metric-subtitle", subtitle))
}

app_css <- "
body { background: #f6f8fb; font-family: 'Inter', 'Segoe UI', Arial, sans-serif; }
.hero { background: linear-gradient(135deg, #0f3a5f 0%, #1f4e79 50%, #126c7a 100%); color: #ffffff; border-radius: 20px; padding: 22px 26px; box-shadow: 0 10px 28px rgba(16,42,67,.18); }
.app-title { font-weight: 800; color: #ffffff; margin-top: 0; }
.app-subtitle { color: #dbeafe; font-size: 14px; margin-top: -4px; }
.status-pill { display:inline-block; padding: 6px 10px; border-radius: 999px; background: rgba(255,255,255,.14); color:#ffffff; font-weight:700; font-size: 12px; margin: 4px 4px 0 0; border: 1px solid rgba(255,255,255,.18); }
.well { background: #ffffff; border: 1px solid #d9e2ec; border-radius: 14px; box-shadow: 0 4px 16px rgba(16,42,67,.06); }
.metric-card { background: white; border-radius: 18px; padding: 17px; margin-bottom: 14px; box-shadow: 0 6px 20px rgba(16,42,67,.09); min-height: 132px; border: 1px solid #e6eef7; }
.metric-icon { float:right; color: #829ab1; font-size: 25px; }
.metric-title { color: #52606d; font-size: 12px; text-transform: uppercase; font-weight: 800; letter-spacing: .8px; }
.metric-value { color: #102a43; font-size: 27px; font-weight: 850; margin-top: 8px; }
.metric-subtitle { color: #627d98; font-size: 12px; margin-top: 5px; }
.viz-card { background: #ffffff; border: 1px solid #d9e2ec; border-radius: 18px; padding: 16px; margin-bottom: 18px; box-shadow: 0 6px 20px rgba(16,42,67,.07); }
.help-box { background:#f0f4f8; border-left:5px solid #1f4e79; padding:13px 14px; border-radius:10px; color:#334e68; }
.small-muted { color:#dbeafe; font-size:12px; }
.control-label { font-weight: 700; color: #243b53; }
body.dark-mode { background: #0b1120; color: #e5e7eb; }
body.dark-mode .hero { background: linear-gradient(135deg, #020617 0%, #0f172a 55%, #075985 100%); box-shadow: 0 10px 28px rgba(0,0,0,.45); }
body.dark-mode .well, body.dark-mode .metric-card, body.dark-mode .viz-card { background: #111827; border-color: #334155; box-shadow: 0 6px 22px rgba(0,0,0,.34); }
body.dark-mode .metric-title, body.dark-mode .metric-subtitle, body.dark-mode .metric-icon { color: #94a3b8; }
body.dark-mode .metric-value { color: #f8fafc; }
body.dark-mode .help-box { background: #0f172a; border-left-color: #38bdf8; color: #dbeafe; }
body.dark-mode .nav-tabs > li > a { background:#0f172a; color:#cbd5e1; border-color:#334155; }
body.dark-mode .nav-tabs > li.active > a { background:#1e293b; color:#ffffff; border-color:#475569; }
body.dark-mode .form-control, body.dark-mode input, body.dark-mode textarea { background:#0f172a !important; color:#e5e7eb !important; border-color:#475569 !important; }
body.dark-mode .control-label { color:#cbd5e1; }
body.dark-mode .dataTables_wrapper, body.dark-mode table.dataTable, body.dark-mode .dataTables_info, body.dark-mode .dataTables_length, body.dark-mode .dataTables_filter, body.dark-mode .paginate_button { color:#e5e7eb !important; }
body.dark-mode table.dataTable tbody tr { background-color:#111827 !important; }
"

plot_text_color <- function(dark = FALSE) {
  if (isTRUE(dark)) "#e5e7eb" else "#102a43"
}

heatmap_label_color <- function(value) {
  ifelse(value >= 0.55, "white", "#102a43")
}

rc_plot_theme <- function(dark = FALSE, rotate_x = FALSE, legend_bottom = FALSE) {
  th <- theme_minimal(base_size = 13) +
    theme(plot.title = element_text(face = "bold", size = 14), axis.title = element_text(face = "bold"))
  if (rotate_x) th <- th + theme(axis.text.x = element_text(angle = 20, hjust = 1))
  if (legend_bottom) th <- th + theme(legend.position = "bottom")
  if (isTRUE(dark)) {
    th <- th + theme(
      plot.background = element_rect(fill = "#111827", color = NA),
      panel.background = element_rect(fill = "#111827", color = NA),
      panel.grid.major = element_line(color = "#334155"),
      panel.grid.minor = element_line(color = "#1f2937"),
      text = element_text(color = "#e5e7eb"),
      axis.text = element_text(color = "#cbd5e1"),
      axis.title = element_text(color = "#e5e7eb"),
      plot.title = element_text(face = "bold", color = "#f8fafc"),
      legend.background = element_rect(fill = "#111827", color = NA),
      legend.key = element_rect(fill = "#111827", color = NA),
      legend.text = element_text(color = "#e5e7eb"),
      legend.title = element_text(color = "#e5e7eb")
    )
  }
  th
}

# -----------------------------------------------------------------------------
# Shiny UI
# -----------------------------------------------------------------------------

ui <- fluidPage(
  theme = shinytheme("flatly"),
  tags$head(
    tags$style(HTML(app_css)),
    tags$script(HTML("Shiny.addCustomMessageHandler('toggleDarkMode', function(enabled) { $('body').toggleClass('dark-mode', enabled); });"))
  ),
  br(),
  div(class = "hero",
      fluidRow(
        column(8,
               h2(class = "app-title", tagList(icon("project-diagram"), " RC-ES MADM III Decision Studio")),
               div(class = "app-subtitle", "Reliability-aware platform for multi-scenario alternative ranking and decision diagnostics"),
               div(
                 span(class = "status-pill", tagList(icon("balance-scale"), " entropy weighting")),
                 span(class = "status-pill", tagList(icon("network-wired"), " consensus / redundancy")),
                 span(class = "status-pill", tagList(icon("random"), " robustness replications")),
                 span(class = "status-pill", tagList(icon("chart-line"), " DRI profiles"))
               )
        ),
        column(4, align = "right", br(),
               checkboxInput("darkMode", "Dark mode", value = FALSE),
               tags$span(class = "small-muted", tagList(icon("flask"), " Research computational platform"))
        )
      )
  ),
  br(),

  tabsetPanel(id = "mainTabs",
    tabPanel(title = tagList(icon("dashboard"), "Overview"), br(),
      fluidRow(
        column(3, uiOutput("cardStatus")),
        column(3, uiOutput("cardScenarios")),
        column(3, uiOutput("cardRS")),
        column(3, uiOutput("cardADI"))
      ),
      fluidRow(
        column(6, div(class="viz-card", plotOutput("plotTopAlternatives", height="340px"))),
        column(6, div(class="viz-card", plotOutput("plotScenarioDiagnostics", height="340px")))
      ),
      div(class="viz-card", DTOutput("tableScenarioSummary"))
    ),

    tabPanel(title = tagList(icon("upload"), "Data Import"), br(),
      sidebarLayout(
        sidebarPanel(width = 3,
          fileInput("files", "Upload RC-ES MADM III Excel workbooks", multiple = TRUE, accept = c(".xlsx")),
          actionButton("run", "Run computation", icon = icon("play"), class = "btn-primary"),
          hr(),
          numericInput("alpha", "Alpha: objective exponent", value = 1, min = 0, max = 5, step = 0.1),
          numericInput("beta", "Beta: subjective exponent", value = 1, min = 0, max = 5, step = 0.1),
          numericInput("eta", "Eta: redundancy adjustment", value = 1, min = 0, max = 1, step = 0.05),
          hr(),
          numericInput("B", "Robustness replications B", value = 1000, min = 100, max = 20000, step = 100),
          numericInput("deltaR", "deltaR: normalized-value perturbation", value = 0.03, min = 0, max = 1, step = 0.01),
          numericInput("deltaW", "deltaW: weight perturbation", value = 0.10, min = 0, max = 0.99, step = 0.01),
          checkboxInput("includeNorm", "Include normalization sensitivity", value = FALSE),
          hr(),
          numericInput("lambda1", "lambda1: S", value = 0.40, min = 0, max = 1, step = 0.05),
          numericInput("lambda2", "lambda2: P(first)", value = 0.25, min = 0, max = 1, step = 0.05),
          numericInput("lambda3", "lambda3: S*RS", value = 0.20, min = 0, max = 1, step = 0.05),
          numericInput("lambda4", "lambda4: S*Delta", value = 0.15, min = 0, max = 1, step = 0.05)
        ),
        mainPanel(width = 9,
          div(class="help-box",
              strong(tagList(icon("info-circle"), " Input format: ")),
              "Required sheets: Settings, Criteria, Alternatives, DecisionMatrix. Optional sheet: ScenarioProbabilities. Several ScenarioID values may be included in the same workbook."),
          br(),
          tabsetPanel(
            tabPanel("Loaded workbooks", br(), DTOutput("tableLoadedWorkbooks")),
            tabPanel("Criteria", br(), DTOutput("tableInputCriteria")),
            tabPanel("Alternatives", br(), DTOutput("tableInputAlternatives")),
            tabPanel("Decision matrix", br(), DTOutput("tableInputMatrix"))
          )
        )
      )
    ),

    tabPanel(title = tagList(icon("table"), "Scenario Results"), br(),
      fluidRow(
        column(3, selectInput("scenarioSelect", "Scenario", choices = character(0))),
        column(9, div(class="help-box", "Inspect the reference ranking, reliability-adjusted ranking, weights, normalized matrix, and rank probabilities for the selected scenario."))
      ),
      fluidRow(
        column(6, div(class="viz-card", plotOutput("plotScoresDRI", height="360px"))),
        column(6, div(class="viz-card", plotOutput("plotRankProbHeatmap", height="360px")))
      ),
      tabsetPanel(
        tabPanel("Alternative profiles", br(), DTOutput("tableProfiles")),
        tabPanel("Criterion weights", br(), DTOutput("tableWeights")),
        tabPanel("Normalized matrix", br(), DTOutput("tableNormalized")),
        tabPanel("Rank probabilities", br(), DTOutput("tableRankProb"))
      )
    ),

    tabPanel(title = tagList(icon("sitemap"), "Consensus & Redundancy"), br(),
      fluidRow(
        column(6, div(class="viz-card", plotOutput("plotWeights", height="370px"))),
        column(6, div(class="viz-card", plotOutput("plotConsensus", height="370px")))
      ),
      div(class="viz-card", DTOutput("tableConsensus"))
    ),

    tabPanel(title = tagList(icon("layer-group"), "Scenario Portfolio"), br(),
      fluidRow(
        column(6, div(class="viz-card", plotOutput("plotPortfolio", height="380px"))),
        column(6, div(class="viz-card", DTOutput("tablePortfolio")))
      )
    ),

    tabPanel(title = tagList(icon("download"), "Export"), br(),
      fluidRow(
        column(4, div(class="viz-card",
          h4("Export results"),
          p("Download all RC-ES MADM III scenario outputs, including profiles, weights, normalized values, rank probabilities, consensus matrices, and settings."),
          downloadButton("downloadResults", "Download RC-ES-MADM III results (.xlsx)", class = "btn-success")
        )),
        column(8, div(class="help-box",
          strong(tagList(icon("check-square"), " Recommended workflow: ")),
          "1) upload the case-study workbook; 2) run computation; 3) inspect rankings and robustness plots; 4) export outputs; 5) verify the exported workbook against the expected case-study behavior."
        ))
      )
    )
  )
)

# -----------------------------------------------------------------------------
# Shiny server
# -----------------------------------------------------------------------------

server <- function(input, output, session) {
  rv <- reactiveValues(workbooks = list(), results = list())

  observeEvent(input$darkMode, {
    session$sendCustomMessage("toggleDarkMode", isTRUE(input$darkMode))
  }, ignoreNULL = FALSE)

  overrides <- reactive(list(
    alpha = input$alpha,
    beta = input$beta,
    eta = input$eta,
    B = input$B,
    deltaR = input$deltaR,
    deltaW = input$deltaW,
    includeNorm = input$includeNorm,
    lambda1 = input$lambda1,
    lambda2 = input$lambda2,
    lambda3 = input$lambda3,
    lambda4 = input$lambda4
  ))

  observeEvent(input$run, {
    req(input$files)
    withProgress(message = "Running RC-ES MADM III scenarios...", value = 0, {
      wb_list <- list()
      res_list <- list()
      nfiles <- nrow(input$files)
      total_jobs <- 0

      for (idx in seq_len(nfiles)) {
        obj <- read_rc_workbook(input$files$datapath[idx])
        obj$workbook <- tools::file_path_sans_ext(input$files$name[idx])
        wb_list[[obj$workbook]] <- obj
        total_jobs <- total_jobs + length(obj$scenario_ids)
      }

      job <- 0
      for (obj_name in names(wb_list)) {
        obj <- wb_list[[obj_name]]
        for (sid in obj$scenario_ids) {
          job <- job + 1
          incProgress(1 / max(1, total_jobs), detail = paste(obj_name, sid))
          key <- make.unique(c(names(res_list), paste0(obj_name, " :: ", sid)))
          key <- key[length(key)]
          res <- compute_rc_scenario(obj, sid, overrides = overrides())
          res$display_name <- key
          res_list[[key]] <- res
        }
      }

      rv$workbooks <- wb_list
      rv$results <- res_list
    })

    scen_names <- names(rv$results)
    updateSelectInput(session, "scenarioSelect", choices = scen_names, selected = scen_names[1])
  })

  all_summary <- reactive({
    req(length(rv$results) > 0)
    bind_rows(lapply(rv$results, function(x) x$summary %>% mutate(DisplayScenario = x$display_name)))
  })

  all_profiles <- reactive({
    req(length(rv$results) > 0)
    bind_rows(lapply(rv$results, function(x) x$profile %>% mutate(DisplayScenario = x$display_name)))
  })

  all_weights <- reactive({
    req(length(rv$results) > 0)
    bind_rows(lapply(rv$results, function(x) x$weights %>% mutate(DisplayScenario = x$display_name)))
  })

  all_normalized <- reactive({
    req(length(rv$results) > 0)
    bind_rows(lapply(rv$results, function(x) x$normalized %>% mutate(DisplayScenario = x$display_name)))
  })

  all_rank_probs <- reactive({
    req(length(rv$results) > 0)
    bind_rows(lapply(rv$results, function(x) x$rank_probabilities %>% mutate(DisplayScenario = x$display_name)))
  })

  all_consensus <- reactive({
    req(length(rv$results) > 0)
    bind_rows(lapply(rv$results, function(x) x$consensus %>% mutate(DisplayScenario = x$display_name)))
  })

  selected_result <- reactive({
    req(input$scenarioSelect, rv$results[[input$scenarioSelect]])
    rv$results[[input$scenarioSelect]]
  })

  output$cardStatus <- renderUI({
    n <- length(rv$results)
    metric_card("check-circle", "Status", ifelse(n > 0, "Computed", "Awaiting input"), paste(n, "scenario(s)"), "#1f7a4d")
  })
  output$cardScenarios <- renderUI({
    val <- if (length(rv$results) == 0) 0 else length(unique(all_summary()$DisplayScenario))
    metric_card("layer-group", "Scenarios", val, "Total evaluated scenarios", "#1f4e79")
  })
  output$cardRS <- renderUI({
    val <- if (length(rv$results) == 0) "--" else sprintf("%.3f", mean(all_summary()$RS, na.rm = TRUE))
    metric_card("shield-alt", "Mean RS", val, "Overall ranking stability", "#6f42c1")
  })
  output$cardADI <- renderUI({
    if (length(rv$results) == 0) {
      val <- "--"
    } else {
      adi_values <- all_summary()$ADI
      adi_values <- adi_values[is.finite(adi_values)]
      val <- if (length(adi_values) == 0) "--" else sprintf("%.3f", mean(adi_values))
    }
    metric_card("arrows-alt-h", "Mean ADI", val, "Alternative distinction", "#b7791f")
  })

  output$tableLoadedWorkbooks <- renderDT({
    if (length(rv$workbooks) == 0) return(datatable(data.frame(Message = "No workbooks loaded yet.")))
    df <- bind_rows(lapply(rv$workbooks, function(x) data.frame(
      Workbook = x$workbook,
      Scenarios = length(x$scenario_ids),
      CriteriaRows = nrow(x$criteria),
      AlternativeRows = nrow(x$alternatives),
      MatrixRows = nrow(x$decision),
      stringsAsFactors = FALSE
    )))
    datatable(df, options = list(pageLength = 10))
  })

  output$tableInputCriteria <- renderDT({
    if (length(rv$workbooks) == 0) return(datatable(data.frame(Message = "Load workbooks first.")))
    datatable(bind_rows(lapply(rv$workbooks, function(x) data.frame(Workbook = x$workbook, x$criteria))),
              options = list(scrollX = TRUE, pageLength = 15))
  })

  output$tableInputAlternatives <- renderDT({
    if (length(rv$workbooks) == 0) return(datatable(data.frame(Message = "Load workbooks first.")))
    datatable(bind_rows(lapply(rv$workbooks, function(x) data.frame(Workbook = x$workbook, x$alternatives))),
              options = list(scrollX = TRUE, pageLength = 15))
  })

  output$tableInputMatrix <- renderDT({
    if (length(rv$workbooks) == 0) return(datatable(data.frame(Message = "Load workbooks first.")))
    datatable(bind_rows(lapply(rv$workbooks, function(x) data.frame(Workbook = x$workbook, x$decision))),
              options = list(scrollX = TRUE, pageLength = 20))
  })

  output$tableScenarioSummary <- renderDT({
    req(length(rv$results) > 0)
    datatable(all_summary(), options = list(scrollX = TRUE, pageLength = 10)) %>%
      formatRound(columns = c("ScenarioProbability", "RS", "ADI", "DeltaR", "DeltaW"), digits = 4)
  })

  output$plotTopAlternatives <- renderPlot({
    req(length(rv$results) > 0)
    df <- all_profiles() %>% filter(Rank_DRI == 1)
    ymax <- max(1.05, max(df$DRI, na.rm = TRUE) * 1.20)
    ggplot(df, aes(x = DisplayScenario, y = DRI, fill = AlternativeName)) +
      geom_col(width = 0.65) +
      geom_text(aes(label = sprintf("%s\nDRI=%.3f", AlternativeID, DRI)), vjust = -0.20, fontface = "bold", size = 4, lineheight = 0.95, color = plot_text_color(isTRUE(input$darkMode))) +
      coord_cartesian(ylim = c(0, ymax), clip = "off") +
      labs(title = "Top reliability-adjusted alternative by scenario", x = NULL, y = "DRI") +
      rc_plot_theme(isTRUE(input$darkMode), rotate_x = TRUE, legend_bottom = TRUE) +
      theme(plot.margin = margin(12, 24, 18, 8))
  })

  output$plotScenarioDiagnostics <- renderPlot({
    req(length(rv$results) > 0)
    sm <- all_summary()
    df <- rbind(
      data.frame(DisplayScenario = sm$DisplayScenario, Index = "RS", Value = sm$RS),
      data.frame(DisplayScenario = sm$DisplayScenario, Index = "ADI", Value = sm$ADI)
    )
    ggplot(df, aes(x = DisplayScenario, y = Value, fill = Index)) +
      geom_col(position = "dodge", width = 0.65) +
      geom_text(aes(label = sprintf("%.3f", Value)), position = position_dodge(width = 0.65), vjust = -0.3, fontface = "bold", size = 4, color = plot_text_color(isTRUE(input$darkMode))) +
      coord_cartesian(ylim = c(0, 1.05), clip = "off") +
      labs(title = "Scenario-level stability and distinction", x = NULL, y = "Index value") +
      rc_plot_theme(isTRUE(input$darkMode), rotate_x = TRUE, legend_bottom = TRUE)
  })

  output$tableProfiles <- renderDT({
    req(selected_result())
    datatable(selected_result()$profile, options = list(scrollX = TRUE, pageLength = 10)) %>%
      formatRound(columns = c("ScenarioProbability", "S", "P_First", "RS_i", "Delta", "DRI"), digits = 4)
  })

  output$tableWeights <- renderDT({
    req(selected_result())
    datatable(selected_result()$weights, options = list(scrollX = TRUE, pageLength = 10)) %>%
      formatRound(columns = c("E", "D", "w_E", "w_S", "w_bar", "rho", "g", "w"), digits = 4)
  })

  output$tableNormalized <- renderDT({
    req(selected_result())
    datatable(selected_result()$normalized, options = list(scrollX = TRUE, pageLength = 15)) %>%
      formatRound(columns = c("X", "R", "p_ij", "q_ij"), digits = 4)
  })

  output$tableRankProb <- renderDT({
    req(selected_result())
    datatable(selected_result()$rank_probabilities, options = list(scrollX = TRUE, pageLength = 20)) %>%
      formatRound(columns = "Probability", digits = 4)
  })

  output$plotScoresDRI <- renderPlot({
    req(selected_result())
    pr <- selected_result()$profile
    df <- rbind(
      data.frame(AlternativeName = pr$AlternativeName, Metric = "Reference score S", Value = pr$S),
      data.frame(AlternativeName = pr$AlternativeName, Metric = "Decision Reliability DRI", Value = pr$DRI)
    )
    ggplot(df, aes(x = reorder(AlternativeName, Value), y = Value, fill = Metric)) +
      geom_col(position = "dodge", width = 0.7) +
      geom_text(aes(label = sprintf("%.3f", Value)), position = position_dodge(width = 0.7), hjust = -0.05, fontface = "bold", size = 4, color = plot_text_color(isTRUE(input$darkMode))) +
      coord_flip(ylim = c(0, 1.08)) +
      labs(title = paste("Reference and reliability-adjusted scores:", selected_result()$scenario), x = NULL, y = "Value") +
      rc_plot_theme(isTRUE(input$darkMode), legend_bottom = TRUE)
  })

  output$plotRankProbHeatmap <- renderPlot({
    req(selected_result())
    df <- selected_result()$rank_probabilities
    df$LabelColor <- heatmap_label_color(df$Probability)
    ggplot(df, aes(x = factor(Rank), y = AlternativeName, fill = Probability)) +
      geom_tile(color = "white") +
      geom_text(aes(label = sprintf("%.2f", Probability), color = LabelColor), fontface = "bold", size = 4, show.legend = FALSE) +
      scale_color_identity() +
      scale_fill_gradient(limits = c(0, 1), low = "#f7fbff", high = "#1f4e79") +
      labs(title = "Robust rank-probability matrix", x = "Rank", y = NULL, fill = "Probability") +
      rc_plot_theme(isTRUE(input$darkMode))
  })

  output$plotWeights <- renderPlot({
    req(selected_result())
    w <- selected_result()$weights
    df <- rbind(
      data.frame(CriterionName = w$CriterionName, WeightType = "w_E", Value = w$w_E),
      data.frame(CriterionName = w$CriterionName, WeightType = "w_S", Value = w$w_S),
      data.frame(CriterionName = w$CriterionName, WeightType = "w_bar", Value = w$w_bar),
      data.frame(CriterionName = w$CriterionName, WeightType = "w", Value = w$w)
    )
    ggplot(df, aes(x = CriterionName, y = Value, fill = WeightType)) +
      geom_col(position = "dodge", width = 0.75) +
      coord_cartesian(ylim = c(0, max(1, max(df$Value, na.rm = TRUE) * 1.1))) +
      labs(title = "Objective, subjective, preliminary, and final weights", x = NULL, y = "Weight") +
      rc_plot_theme(isTRUE(input$darkMode), rotate_x = TRUE, legend_bottom = TRUE)
  })

  output$plotConsensus <- renderPlot({
    req(selected_result())
    df <- selected_result()$consensus
    df$LabelColor <- heatmap_label_color(df$CS)
    ggplot(df, aes(x = Criterion_k, y = Criterion_j, fill = CS)) +
      geom_tile(color = "white") +
      geom_text(aes(label = sprintf("%.2f", CS), color = LabelColor), fontface = "bold", size = 4, show.legend = FALSE) +
      scale_color_identity() +
      scale_fill_gradient(limits = c(0, 1), low = "#f7fbff", high = "#126c7a") +
      labs(title = "Criterion similarity matrix CS", x = NULL, y = NULL, fill = "CS") +
      rc_plot_theme(isTRUE(input$darkMode))
  })

  output$tableConsensus <- renderDT({
    req(selected_result())
    datatable(selected_result()$consensus, options = list(scrollX = TRUE, pageLength = 20)) %>%
      formatRound(columns = c("JSD", "CS"), digits = 4)
  })

  output$tablePortfolio <- renderDT({
    req(length(rv$results) > 0)
    datatable(portfolio_scores(all_profiles()), options = list(scrollX = TRUE, pageLength = 10)) %>%
      formatRound(columns = c("ScenarioWeighted_S", "ScenarioWeighted_DRI", "Mean_P_First", "Mean_RS_i"), digits = 4)
  })

  output$plotPortfolio <- renderPlot({
    req(length(rv$results) > 0)
    df <- portfolio_scores(all_profiles())
    if (nrow(df) == 0) return(NULL)
    ggplot(df, aes(x = reorder(AlternativeName, ScenarioWeighted_DRI), y = ScenarioWeighted_DRI)) +
      geom_col(width = 0.65) +
      geom_text(aes(label = sprintf("%.3f", ScenarioWeighted_DRI)), hjust = -0.05, fontface = "bold", size = 4.5, color = plot_text_color(isTRUE(input$darkMode))) +
      coord_flip(ylim = c(0, 1.08)) +
      labs(title = "Scenario-weighted DRI portfolio", x = NULL, y = "Scenario-weighted DRI") +
      rc_plot_theme(isTRUE(input$darkMode))
  })

  output$downloadResults <- downloadHandler(
    filename = function() paste0("RC_ES_MADM_III_results_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
    content = function(file) {
      req(length(rv$results) > 0)
      export_list <- list(
        ScenarioSummary = all_summary(),
        AlternativeProfiles = all_profiles(),
        CriterionWeights = all_weights(),
        NormalizedMatrix = all_normalized(),
        RankProbabilities = all_rank_probs(),
        ConsensusMatrix = all_consensus(),
        ScenarioWeightedScores = portfolio_scores(all_profiles()),
        SettingsUsed = bind_rows(lapply(rv$results, function(x) x$settings_used %>% mutate(DisplayScenario = x$display_name)))
      )
      writexl::write_xlsx(export_list, path = file)
    }
  )
}

shinyApp(ui = ui, server = server)
