current_script_path <- function(current_script = NULL) {
  if (!is.null(current_script) && nzchar(current_script)) {
    return(normalizePath(current_script))
  }

  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) > 0) {
    return(normalizePath(sub("^--file=", "", file_arg[1])))
  }

  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(normalizePath(sys.frames()[[1]]$ofile))
  }

  normalizePath(getwd())
}

project_paths <- function(script_path) {
  script_path <- current_script_path(script_path)
  script_dir <- dirname(script_path)
  list(
    script = script_path,
    script_dir = script_dir,
    repo_root = dirname(script_dir)
  )
}

first_existing_path <- function(paths, fallback = paths[1]) {
  hit <- paths[file.exists(paths)][1]
  if (is.na(hit)) fallback else hit
}

require_packages <- function(packages) {
  missing_packages <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]

  if (length(missing_packages) > 0) {
    stop("Install missing packages: ", paste(missing_packages, collapse = ", "))
  }

  invisible(TRUE)
}

load_object <- function(path, object_name) {
  env <- new.env(parent = emptyenv())
  load(path, envir = env)
  get(object_name, envir = env)
}

save_png <- function(filename, expr, width = 900, height = 650, res = 120) {
  png(filename, width = width, height = height, res = res)
  on.exit(dev.off(), add = TRUE)
  force(expr)
}

moving_average <- function(x, window = 20) {
  stats::filter(x, filter = rep(1 / window, window), method = "convolution", sides = 2)
}

simple_returns <- function(x) {
  c(NA_real_, diff(x) / head(x, -1))
}
