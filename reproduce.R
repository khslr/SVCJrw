file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
repo_dir <- if (length(file_arg) > 0) {
  normalizePath(dirname(sub("^--file=", "", file_arg[1])))
} else {
  normalizePath(getwd())
}

source(file.path(repo_dir, "R", "utils.R"))

run_quantlet <- function(path, required_data = NULL) {
  script <- file.path(repo_dir, path)
  if (!is.null(required_data) && !file.exists(required_data)) {
    message("Skipping ", path, ": missing ", required_data)
    return(invisible(FALSE))
  }

  message("Running ", path)
  script_env <- new.env(parent = globalenv())
  script_env$current_script <- script
  source(script, local = script_env)
  invisible(TRUE)
}

quantlets <- c(
  "SVCJrw_Indices_SharpeR/SVCJrw_Indices_SharpeR.R",
  "SVCJrw_graph_parameters/SVCJrw_graph_parameters.R",
  "SVCJrw_clustered_parameters/SVCJrw_clustered_parameters.R"
)

if (tolower(Sys.getenv("SVCJRW_RUN_ESTIMATION", "false")) %in% c("1", "true", "yes")) {
  run_quantlet("SVCJrw_estimate_parameters/SVCJrw_estimate_parameters.R")
}

invisible(lapply(quantlets, run_quantlet))

market_caps_candidates <- c(
  file.path(repo_dir, "SVCJrw_CC_market_caps", c("test.csv", "20210605_test.csv")),
  file.path(repo_dir, "20210605_test.csv")
)
market_caps_csv <- Sys.getenv(
  "SVCJRW_MARKET_CAPS_CSV",
  first_existing_path(market_caps_candidates)
)
run_quantlet(
  "SVCJrw_CC_market_caps/SVCJrw_CC_market_caps.R",
  required_data = market_caps_csv
)

rplots <- file.path(repo_dir, "Rplots.pdf")
if (file.exists(rplots)) {
  invisible(file.remove(rplots))
}
