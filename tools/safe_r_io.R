# Controlled I/O for the global analysis. Scientific expressions stay in the Rmd.
# Python owns path policy; this adapter requests authorisation for each operation.
safe_require_context <- function() {
  if (!exists("safe_context", inherits = TRUE) ||
      !isTRUE(safe_context$launched)) {
    stop("Use tools/run_r_analysis.py; direct knitting is not authorised.")
  }
  invisible(TRUE)
}

safe_input <- function(id) {
  safe_require_context()
  value <- safe_context$inputs[[id]]
  if (is.null(value) || !file.exists(value)) stop("Required input is absent: ", id)
  value
}

safe_authorize <- function(file, read = FALSE) {
  safe_require_context()
  if (!is.character(file) || length(file) != 1L || is.na(file)) {
    stop("A single explicit file path is required.")
  }
  args <- c("-B", shQuote(safe_context$bridge), "--authorize",
            shQuote(safe_context$context_file), shQuote(file))
  if (read) args <- c(args, "--read-generated")
  answer <- system2(safe_context$python, args, stdout = TRUE)
  status <- attr(answer, "status")
  if ((!is.null(status) && status != 0L) || length(answer) != 1L) {
    stop("Python rejected the requested file operation.")
  }
  answer[[1L]]
}

safe_write_csv <- function(x, file, ...) {
  file <- safe_authorize(file)
  utils::write.csv(x, file = file, ...)
}

safe_save_rds <- function(object, file, ...) {
  file <- safe_authorize(file)
  base::saveRDS(object, file = file, ...)
}

safe_ggsave <- function(filename, ...) {
  filename <- safe_authorize(filename)
  ggplot2::ggsave(filename = filename, ...)
}

safe_read_rds <- function(file, ...) {
  file <- safe_authorize(file, read = TRUE)
  base::readRDS(file, ...)
}

safe_render <- function(context_file, output_format) {
  if (!requireNamespace("rmarkdown", quietly = TRUE) ||
      !requireNamespace("knitr", quietly = TRUE)) {
    stop("Existing rmarkdown and knitr installations are required; nothing is installed automatically.")
  }
  env <- new.env(parent = globalenv())
  sys.source(context_file, envir = env)
  env$safe_context$launched <- TRUE
  # Bind wrappers to this execution's context, without mutating global bindings.
  for (name in c("safe_require_context", "safe_input", "safe_authorize",
                 "safe_write_csv", "safe_save_rds", "safe_ggsave", "safe_read_rds")) {
    fn <- get(name)
    environment(fn) <- env
    assign(name, fn, envir = env)
  }
  root <- env$safe_context$run
  knitr::opts_chunk$set(fig.path = paste0(root, "/figures/knitr/"),
                        cache.path = paste0(root, "/cache/"), cache = FALSE)
  ext <- switch(output_format, html_document = "html", pdf_document = "pdf",
                word_document = "docx", stop("Unsupported report format."))
  rmarkdown::render(input = file.path(root, "report", "analysis.Rmd"),
                    output_format = output_format,
                    output_file = paste0("analysis.", ext),
                    output_dir = file.path(root, "report"),
                    intermediates_dir = file.path(root, "intermediates"),
                    knit_root_dir = file.path(root, "work"),
                    envir = env, clean = FALSE)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 3L || args[[1L]] != "--render") {
    stop("Invoke through the Python launcher.")
  }
  safe_render(args[[2L]], args[[3L]])
}
