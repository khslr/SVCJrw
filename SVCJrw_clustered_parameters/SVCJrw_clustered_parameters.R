this_file <- if (exists("current_script")) current_script else sub(
  "^--file=", "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1]
)
source(file.path(dirname(dirname(normalizePath(this_file))), "R", "utils.R"))

require_packages(c("ggplot2", "RColorBrewer"))

paths <- project_paths(this_file)

suppressPackageStartupMessages(library(ggplot2))

cluster_data <- read.csv(file.path(paths$script_dir, "clustering_data.csv"))
names(cluster_data)[1] <- "date"
cluster_data$date <- as.Date(cluster_data$date)

scale_columns <- c("mu", "beta", "sigma_y", "sigma_v")
cluster_scaled <- as.data.frame(scale(cluster_data[, scale_columns]))
cluster_scaled$date <- cluster_data$date
cluster_scaled$crix <- cluster_data$crix

set.seed(1234)

cluster_theme <- function() {
  theme_bw() +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
}

within_cluster_sums <- function(data, max_clusters = 9, nstart = 25) {
  vapply(seq_len(max_clusters), function(k) {
    if (k == 1) {
      return((nrow(data) - 1) * sum(apply(data, 2, stats::var)))
    }
    sum(stats::kmeans(data, centers = k, nstart = nstart)$withinss)
  }, numeric(1))
}

plot_parameter_clusters <- function(x_var, y_var, prefix, centers = 3) {
  variables <- c(x_var, y_var)
  clustering_input <- cluster_scaled[, variables]
  wss <- within_cluster_sums(clustering_input)

  save_png(file.path(paths$script_dir, paste0(prefix, "_elbow.png")), {
    plot(
      seq_along(wss),
      wss,
      type = "b",
      xlab = "Number of Clusters",
      ylab = "Within groups sum of squares"
    )
  })

  clusters <- stats::kmeans(
    clustering_input,
    centers = centers,
    iter.max = 10,
    nstart = 25
  )

  cluster_column <- paste0("cluster_", prefix)
  plot_data <- cluster_scaled
  plot_data[[cluster_column]] <- factor(clusters$cluster)
  cluster_colors <- RColorBrewer::brewer.pal(centers, "Paired")
  names(cluster_colors) <- levels(plot_data[[cluster_column]])

  cluster_plot <- ggplot(plot_data, aes(x = .data[[x_var]], y = .data[[y_var]], color = .data[[cluster_column]])) +
    geom_point(size = 2.2) +
    scale_colour_manual(name = "Cluster #", values = cluster_colors) +
    cluster_theme()

  crix_plot <- ggplot(plot_data, aes(x = date, y = crix, color = .data[[cluster_column]])) +
    geom_point() +
    scale_colour_manual(name = "Cluster #", values = cluster_colors) +
    cluster_theme()

  ggsave(file.path(paths$script_dir, paste0(prefix, "_cluster.png")), cluster_plot, width = 7, height = 5, dpi = 150)
  ggsave(file.path(paths$script_dir, paste0(prefix, "_crix.png")), crix_plot, width = 7, height = 5, dpi = 150)

  if (requireNamespace("gridExtra", quietly = TRUE)) {
    combined_plot <- gridExtra::arrangeGrob(cluster_plot, crix_plot, ncol = 1)
    ggsave(file.path(paths$script_dir, paste0(prefix, ".png")), combined_plot, width = 7, height = 8, dpi = 150)
  }
}

plot_parameter_clusters("beta", "mu", "mu_beta", centers = 3)
plot_parameter_clusters("sigma_v", "sigma_y", "sigma_y_sigma_v", centers = 3)

gif_file <- file.path(paths$script_dir, "gif_data.Rda")
if (all(vapply(c("gganimate", "gifski", "hrbrthemes"), requireNamespace, logical(1), quietly = TRUE)) && file.exists(gif_file)) {
  suppressPackageStartupMessages(library(gganimate))
  suppressPackageStartupMessages(library(hrbrthemes))

  s <- load_object(gif_file, "s")
  s <- na.omit(s)

  gif_plot <- ggplot(s, aes(x = s.alpha.150, y = s.sigma_v.150)) +
    geom_line(colour = "grey") +
    geom_point() +
    theme_ipsum() +
    theme(
      panel.background = element_rect(fill = "transparent", colour = NA),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_line(colour = "black")
    ) +
    transition_reveal(as.Date(date)) +
    ggtitle("Date: {frame_along}")

  animate(
    gif_plot,
    renderer = gifski_renderer(file.path(paths$script_dir, "alpha_sigma_v.gif")),
    bg = "transparent",
    nframes = 100
  )
} else {
  message("Skipping GIF generation; install gganimate, gifski, and hrbrthemes to reproduce alpha_sigma_v.gif.")
}
