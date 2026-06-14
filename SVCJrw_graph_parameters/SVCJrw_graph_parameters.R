this_file <- if (exists("current_script")) current_script else sub(
  "^--file=", "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1]
)
source(file.path(dirname(dirname(normalizePath(this_file))), "R", "utils.R"))

paths <- project_paths(this_file)
param_file <- Sys.getenv("SVCJRW_PARAM_RDA", file.path(paths$script_dir, "param_t_all.rda"))
output_dir <- Sys.getenv("SVCJRW_GRAPH_OUTPUT_DIR", paths$script_dir)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

param_t_all <- load_object(param_file, "param.t.all")

windows <- c(150, 300, 600)
parameter_groups <- list(
  c("mu", "mu_y", "sigma_y", "lambda"),
  c("alpha", "beta", "rho", "sigma_v"),
  c("rho_j", "mu_v")
)

plot_single_window <- function(parameter, window = 150) {
  values <- param_t_all[[paste(parameter, window, sep = ".")]]
  ma_window <- min(20, length(values))
  ma_values <- moving_average(values, window = ma_window)

  plot(
    x = param_t_all$date,
    y = values,
    type = "l",
    ylab = parameter,
    xlab = "date",
    col = "#26828E90"
  )
  lines(x = param_t_all$date, y = ma_values, type = "l", col = "#26828E")
}

plot_window_comparison <- function(parameter) {
  ma_values <- lapply(windows, function(window) {
    values <- param_t_all[[paste(parameter, window, sep = ".")]]
    moving_average(values, window = min(20, length(values)))
  })

  y_range <- range(unlist(ma_values), na.rm = TRUE)
  if (!all(is.finite(y_range))) {
    y_range <- range(unlist(lapply(windows, function(window) {
      param_t_all[[paste(parameter, window, sep = ".")]]
    })), na.rm = TRUE)
  }
  plot(
    x = param_t_all$date,
    y = ma_values[[1]],
    xaxt = "n",
    type = "l",
    ylab = parameter,
    xlab = "",
    col = "#FD8D3C",
    ylim = y_range
  )
  axis.Date(1, param_t_all$date)
  lines(x = param_t_all$date, y = ma_values[[2]], type = "l", col = "#9E9AC8")
  lines(x = param_t_all$date, y = ma_values[[3]], type = "l", col = "#1B9E77", pch = 18)
}

for (i in seq_along(parameter_groups)) {
  height <- if (length(parameter_groups[[i]]) == 2) 360 else 620
  layout <- c(ceiling(length(parameter_groups[[i]]) / 2), 2)

  save_png(file.path(output_dir, sprintf("20210103_svcj_150_%s.png", i)), {
    par(mfrow = layout, mar = c(3, 4, 1, 1))
    for (parameter in parameter_groups[[i]]) {
      plot_single_window(parameter, window = 150)
    }
  }, width = 900, height = height)

  save_png(file.path(output_dir, sprintf("20210103_svcj_%s.png", i)), {
    par(mfrow = layout, mar = c(3, 4, 1, 1))
    for (parameter in parameter_groups[[i]]) {
      plot_window_comparison(parameter)
    }
  }, width = 900, height = height)
}
