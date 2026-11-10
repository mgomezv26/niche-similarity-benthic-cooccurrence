# ============================================================================
# 04_01_environmental_pca.R
# Environmental PCA of the 0.1-degree MEOW marine grid

# ============================================================================
# INPUT:  data/processed/grids/grid_meow_env_clean_0.1deg.gpkg
# OUTPUT: data/processed/grids/grid_env_realm_with_PCA6_axes.gpkg
#         results/pca/ (variance, loadings, PCA scores, figures, RDS model)
#
# Methodological invariants:
# - PCA uses ALL valid grid cells, not individual species occurrences.
# - Nine continuous variables must already be z-standardized upstream.
# - Sediment size is z-standardized here, as in the original script.
# - prcomp(center = TRUE, scale. = FALSE), six axes retained for manuscript.
# - Broken Stick is reported diagnostically; it does not silently change PC1:PC6.
# ============================================================================

library(here)
library(sf)
library(ggplot2)

# ============================================================
# R AND PACKAGE VERSIONS
# ============================================================
# Versions from the current runtime, not the historical analysis environment.

cat("R version:", R.version.string, "\n") # R version: R version 4.5.1 (2025-06-13 ucrt) 

cat("Versions of the libraries used:\n")
cat("here:", as.character(packageVersion("here")), "\n") # here: 1.0.2
cat("sf:", as.character(packageVersion("sf")), "\n") # sf: 1.0.21
cat("ggplot2:", as.character(packageVersion("ggplot2")), "\n") # ggplot2: 4.0.0

# 1. Files ------------------------------------------------------------------
input_file <- here("data", "processed", "grids", "grid_meow_env_clean_0.1deg.gpkg")
output_file <- here("data", "processed", "grids", "grid_meow_env_pca6_0.1deg.gpkg")
results_dir <- here("results", "pca")
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_file)) {
  stop("Missing environmental grid: ", input_file)
}

# 2. Load grid and select the original ten predictors ------------------------
grid_env <- sf::st_read(input_file, quiet = TRUE)
if (!"cell_id" %in% names(grid_env)) stop("Input grid is missing cell_id.")
if (anyDuplicated(grid_env$cell_id)) stop("cell_id must be unique (one row per grid cell).")

continuous_vars <- c("bathymetry", "o2", "ph", "phyc", "po4",
                     "so", "sws", "thetao", "chl")
sediment_var <- "r_sediment_size"
required_vars <- c(continuous_vars, sediment_var)
missing_vars <- setdiff(required_vars, names(grid_env))
if (length(missing_vars) > 0L) {
  stop("Missing required PCA variables: ", paste(missing_vars, collapse = ", "))
}

data_env <- sf::st_drop_geometry(grid_env)
vars_numeric <- data_env[, required_vars, drop = FALSE]
if (!all(vapply(vars_numeric, is.numeric, logical(1)))) {
  stop("All ten PCA predictors must be numeric.")
}

# The original prcomp() would fail on missing values. Fail explicitly instead
# of silently deleting cells and changing the correspondence with the grid.
if (anyNA(vars_numeric) || any(!is.finite(as.matrix(vars_numeric)))) {
  stop("Missing or non-finite values in PCA predictors; inspect grid before running PCA.")
}

# Original analysis: standardize only sediment size at this step.
# The remaining nine predictors were standardized at raster stage (02_03).
if (!is.finite(sd(vars_numeric[[sediment_var]])) || sd(vars_numeric[[sediment_var]]) == 0) {
  stop("Sediment size has zero or invalid standard deviation.")
}
vars_numeric$r_sediment_size_z <- as.numeric(scale(vars_numeric[[sediment_var]]))
vars_numeric[[sediment_var]] <- NULL
vars_numeric <- vars_numeric[, c(continuous_vars, "r_sediment_size_z"), drop = FALSE]
if (any(vapply(vars_numeric, sd, numeric(1)) == 0)) {
  stop("At least one PCA predictor has no variation.")
}

# 3. PCA --------------------------------------------------------------------
pca_env <- stats::prcomp(vars_numeric, center = TRUE, scale. = FALSE)
print(summary(pca_env))
saveRDS(pca_env, file.path(results_dir, "environmental_pca_model.rds"))

# 4. Eigenvalues, explained variance, and Broken Stick -----------------------
eig_vals <- pca_env$sdev^2
n_axes <- length(eig_vals)
prop_exp <- eig_vals / sum(eig_vals)
# Expected proportion for rank k among n random broken-stick segments:
# (1/n) * sum_{j=k}^n (1/j)
bs <- vapply(seq_len(n_axes), function(k) sum(1 / seq.int(k, n_axes)) / n_axes,
             numeric(1))

pca_variance <- data.frame(
  Axis = seq_len(n_axes),
  Eigenvalue = eig_vals,
  Proportion = prop_exp,
  Cumulative = cumsum(prop_exp),
  BrokenStick = bs,
  RetainBrokenStick = prop_exp > bs,
  Proportion_pct = prop_exp * 100,
  Cumulative_pct = cumsum(prop_exp) * 100,
  BrokenStick_pct = bs * 100
)
write.csv(pca_variance, file.path(results_dir, "pca_explained_variance.csv"), row.names = FALSE)
print(pca_variance)

# Original manuscript explicitly uses PC1–PC6 for all downstream calculations.
retained_axes <- seq_len(6L)
if (n_axes < length(retained_axes)) stop("The input has fewer than six PCA axes.")
message("Variance explained by first six axes: ",
        round(100 * sum(prop_exp[retained_axes]), 2), "%")
message("Broken Stick diagnostic axes: ",
        paste(which(pca_variance$RetainBrokenStick), collapse = ", "))

# 5. PCA figures ------------------------------------------------------------
p_variance <- ggplot(pca_variance, aes(x = Axis)) +
  geom_col(aes(y = Proportion_pct), fill = "#D6EAEF", width = 0.7) +
  geom_line(aes(y = Proportion_pct), color = "#2EA4C2", linewidth = 0.8) +
  geom_point(aes(y = Proportion_pct), color = "#2EA4C2", size = 2) +
  geom_line(aes(y = BrokenStick_pct), color = "#80146E",
            linetype = "dashed", linewidth = 0.8) +
  geom_point(aes(y = BrokenStick_pct), color = "#80146E", size = 2) +
  geom_text(aes(y = Proportion_pct, label = sprintf("%.1f%%", Proportion_pct)),
            vjust = -0.6, size = 3) +
  scale_x_continuous(breaks = seq_len(n_axes)) +
  expand_limits(y = max(pca_variance$Proportion_pct) + 5) +
  labs(title = "Environmental PCA: observed variance and Broken Stick",
       x = "Principal component", y = "Explained variance (%)") +
  theme_minimal(base_size = 12)
ggsave(file.path(results_dir, "PCA_variance_BS.svg"), p_variance,
       width = 8, height = 6)

# Rotation coefficients (loadings, as in the original script).
# NOTE: PCA rotation coefficients are not exactly variable-PC correlations.
loadings_raw <- pca_env$rotation[, retained_axes, drop = FALSE]
loadings_table <- data.frame(Variable = rownames(loadings_raw),
                             round(loadings_raw, 3), row.names = NULL,
                             check.names = FALSE)
loadings_table <- loadings_table[order(-abs(loadings_table$PC1)), , drop = FALSE]
write.csv(loadings_table, file.path(results_dir, "PCA_env_loadings_table.csv"),
          row.names = FALSE)

loadings_long <- data.frame(
  Variable = rep(rownames(loadings_raw), times = length(retained_axes)),
  Component = rep(colnames(loadings_raw), each = nrow(loadings_raw)),
  Loading = as.vector(loadings_raw)
)

p_heatmap <- ggplot(loadings_long, aes(x = Component, y = Variable, fill = Loading)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "#4F87BF", mid = "white", high = "#80146E",
                       midpoint = 0, limits = c(-1, 1)) +
  labs(title = "Environmental PCA loadings (first six axes)",
       x = "Principal component", y = "Environmental variable") +
  theme_minimal(base_size = 12)
ggsave(file.path(results_dir, "PCA_loadings_heatmap.svg"), p_heatmap,
       width = 8, height = 6)

p_loadings <- ggplot(loadings_long,
                     aes(x = Variable, y = Loading, fill = Component)) +
  geom_col(position = "dodge", color = "grey30", linewidth = 0.15) +
  geom_hline(yintercept = c(-0.5, 0.5), linetype = "dotted", color = "grey40") +
  coord_flip() +
  labs(title = "Environmental variable loadings on the first six PCA axes",
       x = NULL, y = "PCA rotation coefficient") +
  theme_minimal(base_size = 12)
ggsave(file.path(results_dir, "PCA_loadings_bars.svg"), p_loadings,
       width = 10, height = 7)

# Original script's top-3 loadings by absolute value for each component.
top3 <- do.call(rbind, lapply(split(loadings_long, loadings_long$Component),
                              function(x) head(x[order(-abs(x$Loading)), ], 3)))
rownames(top3) <- NULL
write.csv(top3, file.path(results_dir, "PCA_env_top3_variables_per_component.csv"),
          row.names = FALSE)

# Variable arrows for PC1 vs PC2 and PC3 vs PC4, in rotation space.
make_variable_plot <- function(pc_x, pc_y) {
  rot <- as.data.frame(pca_env$rotation[, c(pc_x, pc_y), drop = FALSE])
  rot$Variable <- rownames(rot)
  ggplot(rot, aes(x = .data[[pc_x]], y = .data[[pc_y]])) +
    geom_hline(yintercept = 0, color = "grey80") +
    geom_vline(xintercept = 0, color = "grey80") +
    geom_segment(aes(x = 0, y = 0, xend = .data[[pc_x]], yend = .data[[pc_y]]),
                 arrow = grid::arrow(length = grid::unit(0.15, "cm")),
                 color = "#4F87BF") +
    geom_text(aes(label = Variable), hjust = -0.1, vjust = -0.2, size = 3) +
    coord_equal() +
    labs(title = paste("PCA variable loadings:", pc_x, "vs", pc_y),
         x = pc_x, y = pc_y) +
    theme_minimal(base_size = 12)
}
ggsave(file.path(results_dir, "PCA_variables_PC1_PC2.svg"),
       make_variable_plot("PC1", "PC2"), width = 8, height = 7)
ggsave(file.path(results_dir, "PCA_variables_PC3_PC4.svg"),
       make_variable_plot("PC3", "PC4"), width = 8, height = 7)

# 6. Append six PCA scores to the ORIGINAL grid, preserving row order --------
pca_scores_sel <- as.data.frame(pca_env$x[, retained_axes, drop = FALSE])
stopifnot(nrow(pca_scores_sel) == nrow(grid_env))
if (any(colnames(pca_scores_sel) %in% names(grid_env))) {
  stop("Input grid already has PCA score columns: remove/rename before joining.")
}
grid_env_with_pca <- cbind(grid_env, pca_scores_sel)

# Also keep a lightweight cell-id-to-score table.
write.csv(data.frame(cell_id = grid_env$cell_id, pca_scores_sel),
          file.path(results_dir, "PCA_grid_cell_scores.csv"), row.names = FALSE)

if (file.exists(output_file)) {
  stop("Output already exists; refusing to overwrite: ", output_file,
       "\nRename or back up the existing historical GeoPackage first.")
}
sf::st_write(grid_env_with_pca, output_file, quiet = TRUE)
message("PCA grid created: ", output_file)
message("PCA summaries and plots: ", results_dir)
