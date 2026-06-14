this_file <- if (exists("current_script")) current_script else sub(
  "^--file=", "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1]
)
source(file.path(dirname(dirname(normalizePath(this_file))), "R", "utils.R"))

paths <- project_paths(this_file)
default_inputs <- c(
  file.path(paths$script_dir, c("test.csv", "20210605_test.csv")),
  file.path(paths$repo_root, "20210605_test.csv")
)
input_file <- Sys.getenv(
  "SVCJRW_MARKET_CAPS_CSV",
  first_existing_path(default_inputs)
)
if (!file.exists(input_file)) {
  stop(
    "Market-cap source data is not included in the repository. ",
    "Set SVCJRW_MARKET_CAPS_CSV to the CoinGecko CSV path or place test.csv/20210605_test.csv in this folder."
  )
}

market_data <- read.csv(
  input_file,
  colClasses = c(
    Datetime = "Date",
    Id = "NULL",
    prices = "numeric",
    market_caps = "numeric",
    total_volumes = "numeric"
  )
)
market_data <- subset(market_data, prices > 0 & total_volumes > 0 & market_caps > 0)
market_data$log_mc <- log(market_data$market_caps)

active_coins <- aggregate(
  market_caps ~ Datetime,
  data = market_data,
  FUN = length
)
names(active_coins) <- c("Date", "number_of_coins")

save_png(file.path(paths$script_dir, "active_coins.png"), {
  plot(
    number_of_coins ~ Date,
    data = active_coins,
    type = "l",
    ylab = "Number of active CCs",
    xlab = "",
    lwd = 2,
    col = "#9E9AC8"
  )
})

selected_dates <- seq(
  from = min(market_data$Datetime, na.rm = TRUE),
  to = max(market_data$Datetime, na.rm = TRUE),
  by = "6 months"
)
selected_dates <- selected_dates[selected_dates %in% market_data$Datetime]
if (length(selected_dates) == 0) {
  stop("No selected market-cap dates are present in ", input_file)
}
colors <- colorRampPalette(c("grey", "navy"))(length(selected_dates))

save_png(file.path(paths$script_dir, "sorted_market_caps_over_time.png"), {
  par(pin = c(4.5, 3), mar = par()$mar + c(0, 0, 0, 3), xpd = FALSE)
  first_date <- selected_dates[1]
  plot(
    sort(market_data$log_mc[market_data$Datetime == first_date], decreasing = TRUE),
    type = "l",
    col = colors[1],
    xlab = "# coins",
    ylab = "log(market cap)",
    xlim = c(0, 1250),
    lwd = 2
  )

  for (i in seq_along(selected_dates)[-1]) {
    lines(
      sort(market_data$log_mc[market_data$Datetime == selected_dates[i]], decreasing = TRUE),
      col = colors[i],
      lwd = 2
    )
  }

  legend(
    "right",
    legend = selected_dates,
    col = colors,
    inset = c(-0.3, 0),
    xpd = TRUE,
    cex = 0.8,
    lty = 1,
    title = "dates"
  )
})
