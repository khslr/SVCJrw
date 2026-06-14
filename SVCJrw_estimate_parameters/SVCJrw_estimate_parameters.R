file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (exists("current_script")) {
  current_script
} else if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[1]))
} else {
  normalizePath("SVCJrw_estimate_parameters.R")
}
script_dir <- dirname(script_path)
repo_root <- dirname(script_dir)

source(file.path(repo_root, "R", "utils.R"))
require_packages("MASS")
source(file.path(script_dir, "svcj_model.R"))

read_price_data <- function(path) {
  price_data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!"date" %in% names(price_data)) {
    names(price_data)[1] <- "date"
  }
  if (!"price" %in% names(price_data)) {
    stop("Price data must contain a 'price' column: ", path)
  }

  price_data$date <- as.Date(price_data$date)
  price_data <- price_data[order(price_data$date), c("date", "price")]
  price_data <- price_data[is.finite(price_data$price) & price_data$price > 0, ]
  rownames(price_data) <- NULL
  price_data
}

estimate_rolling_svcj <- function(price_data, window_sizes, step, iterations, burn_in,
                                  max_windows = Inf, seed = 123, verbose = FALSE) {
  stopifnot(iterations > burn_in)
  set.seed(seed)

  parameter_names <- c(
    "mu", "mu_y", "sigma_y", "lambda", "alpha",
    "beta", "rho", "sigma_v", "rho_j", "mu_v"
  )
  estimates <- list()

  for (window_size in window_sizes) {
    starts <- seq(1, nrow(price_data) - window_size, by = step)
    starts <- head(starts, max_windows)
    window_estimates <- data.frame(matrix(
      NA_real_,
      nrow = length(starts),
      ncol = length(parameter_names)
    ))
    names(window_estimates) <- parameter_names
    window_estimates$date <- price_data$date[starts]

    for (idx in seq_along(starts)) {
      start <- starts[idx]
      end <- start + window_size
      if (verbose) {
        message("Estimating window ", idx, "/", length(starts), " for ", window_size, " days")
      }
      result <- svcj_model(
        price_data$price[start:end],
        N = iterations,
        n = burn_in,
        verbose = FALSE
      )
      window_estimates[idx, parameter_names] <- result$parameters$mean
    }

    estimates[[as.character(window_size)]] <- window_estimates
  }

  estimates
}

combine_rolling_estimates <- function(estimates) {
  combined <- NULL
  for (window_size in names(estimates)) {
    estimate <- estimates[[window_size]]
    names(estimate)[names(estimate) != "date"] <- paste0(
      names(estimate)[names(estimate) != "date"],
      ".",
      window_size
    )

    if (is.null(combined)) {
      combined <- estimate
    } else {
      combined <- merge(combined, estimate, by = "date", all = TRUE)
    }
  }

  combined <- combined[order(combined$date), ]
  combined[, c("date", setdiff(names(combined), "date"))]
}

price_file <- Sys.getenv(
  "SVCJRW_PRICE_CSV",
  first_existing_path(c(
    file.path(repo_root, "data", "crix_data.csv"),
    file.path(script_dir, "crix_price.csv")
  ))
)
output_file <- Sys.getenv("SVCJRW_ESTIMATE_OUTPUT", file.path(script_dir, "param_t_all.rda"))
window_sizes <- as.integer(strsplit(Sys.getenv("SVCJRW_WINDOWS", "150,300,600"), ",")[[1]])
step <- as.integer(Sys.getenv("SVCJRW_STEP", "2"))
iterations <- as.integer(Sys.getenv("SVCJRW_ITERATIONS", "5000"))
burn_in <- as.integer(Sys.getenv("SVCJRW_BURN_IN", "1000"))
max_windows <- as.integer(Sys.getenv("SVCJRW_MAX_WINDOWS", as.character(.Machine$integer.max)))
seed <- as.integer(Sys.getenv("SVCJRW_SEED", "123"))

price_data <- read_price_data(price_file)
rolling_estimates <- estimate_rolling_svcj(
  price_data = price_data,
  window_sizes = window_sizes,
  step = step,
  iterations = iterations,
  burn_in = burn_in,
  max_windows = max_windows,
  seed = seed,
  verbose = TRUE
)
param.t.all <- combine_rolling_estimates(rolling_estimates)

save(param.t.all, file = output_file)
write.csv(param.t.all, sub("\\.rda$", ".csv", output_file), row.names = FALSE)
message("Saved rolling SVCJ estimates to ", output_file)
