library(terra)

files <- list.files("~/Documents/lightning/scoring-combined", full.names = TRUE, pattern = "\\.tif$")
r <- rast(files)
r8 <- rast(lapply(files, function(f) rast(f)[[8]]))
r_mean <- mean(r8)
v <- values(r8)
mean(v)
quantile(v, probs = c(0.99, 0.999, 0.9999, 0.99999))


# Here I only look at the summer months
library(lubridate)
files <- list.files("~/Documents/lightning/scoring-combined", full.names = TRUE, pattern = "\\.tif$")
dates <- ymd(tools::file_path_sans_ext(basename(files)))
files <- files[month(dates) %in% 4:9 & year(dates) >= 2023]
r <- rast(files)
r8 <- rast(lapply(files, function(f) rast(f)[[8]]))
v <- values(r8)
quantile(v, probs = c(.95))
r_aod <- rast(lapply(files, function(f) {
  a <- rast(f)
  a[[2]]# + a[[3]] + a[[4]] + a[[5]] + a[[6]]
  }))
quantile(values(r_aod), probs = c(.9))
