this_file <- if (exists("current_script")) current_script else sub(
  "^--file=", "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1]
)
source(file.path(dirname(dirname(normalizePath(this_file))), "R", "utils.R"))

require_packages(c("moments", "corrplot", "xtable", "RColorBrewer"))

paths <- project_paths(this_file)
colors <- RColorBrewer::brewer.pal(11, "Paired")

indices <- load_object(file.path(paths$script_dir, "all_indices.rda"), "test5")
daily_sums <- load_object(file.path(paths$script_dir, "daily_sums_n.rda"), "daily.sums.n")

data <- merge(indices, daily_sums[, c("date", "total_mc")], by.x = "Date", by.y = "date", all.x = TRUE)
data$TMI <- NULL
names(data)[names(data) == "total_mc"] <- "TMI"
data <- data[-1, ]

index_names <- names(data)[-1]
normed_names <- paste0(index_names, "_normed")
return_names <- paste0(index_names, "_return")

data[normed_names] <- lapply(index_names, function(index) data[[index]] / data[[index]][1] * 1000)
data[return_names] <- lapply(index_names, function(index) simple_returns(data[[index]]))

returns <- data[return_names]
sample_size <- colSums(!is.na(returns))
avg_returns <- vapply(returns, mean, numeric(1), na.rm = TRUE)
standarddeviation_returns <- vapply(returns, stats::sd, numeric(1), na.rm = TRUE)
skewness <- vapply(returns, moments::skewness, numeric(1), na.rm = TRUE)
kurtosis <- vapply(returns, moments::kurtosis, numeric(1), na.rm = TRUE)
sharpe_ratios <- avg_returns / standarddeviation_returns

psr_input <- (sharpe_ratios * sqrt(sample_size - 1)) /
  sqrt(1 - skewness * sharpe_ratios + ((kurtosis - 1) / 4) * sharpe_ratios^2)

output <- data.frame(
  sharpe_ratio = sharpe_ratios,
  returns = avg_returns,
  vola = standarddeviation_returns,
  skewness = skewness,
  kurtosis = kurtosis,
  PSR = stats::pnorm(psr_input),
  row.names = index_names
)
print(xtable::xtable(output, digits = 3))

save_png(file.path(paths$script_dir, "normed_indices.png"), {
  par(xpd = TRUE, mar = par()$mar + c(0, 0, 0, 7), bg = NA)
  plot(
    data$TMI_normed ~ data$Date,
    type = "l",
    ylim = c(0, 2000),
    xlab = "",
    ylab = "Index Values",
    lwd = 2,
    lty = 1
  )

  line_colors <- c("black", colors[c(3, 2, 6, 8)], "black")
  for (i in seq_along(index_names[-length(index_names)])) {
    index <- index_names[-length(index_names)][i]
    lines(
      data[[paste0(index, "_normed")]] ~ data$Date,
      type = "l",
      col = line_colors[i],
      lwd = 1.8,
      lty = 3
    )
  }

  legend(
    "right",
    inset = c(-0.3, 0),
    xpd = TRUE,
    legend = index_names,
    col = line_colors,
    cex = 0.8,
    lwd = 3,
    lty = c(rep(3.5, length(index_names) - 1), 1.5)
  )
})

index_correlations <- stats::cor(data[, index_names], use = "complete.obs")
save_png(file.path(paths$script_dir, "corrplot_indices_blue.png"), {
  corrplot::corrplot.mixed(
    index_correlations,
    order = "alphabet",
    lower = "number",
    upper = "circle",
    upper.col = colorRampPalette(c("white", "lightpink", "pink"))(200),
    lower.col = colorRampPalette(c("blue", "white", "lightpink", "pink", "red"))(200),
    tl.col = "black"
  )
})

corr_tmi_index <- function(sel_index, rows, source_data = data) {
  stats::cor(source_data[rows, sel_index], source_data[rows, "TMI"], use = "complete.obs")
}

set.seed(1234)
bootstrap_correlations <- replicate(1000, {
  rows <- sample(seq_len(nrow(data)), 100)
  vapply(index_names, corr_tmi_index, numeric(1), rows = rows)
})

bootstrap_correlations <- as.data.frame(t(bootstrap_correlations))
saveRDS(bootstrap_correlations, file.path(paths$script_dir, "bootstrap_correlations.rds"))
