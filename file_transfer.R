library(terra)
setwd("~/Documents/hrrr")

files1 <- list.files("~/Documents/merra/merra-1730-test", full.names = TRUE, pattern = "\\.nc$")
files2 <- list.files("/Users/zj/Documents/lightning/test-images/", full.names = TRUE, pattern = "\\.tif$")

get_date <- function(f) sub(".*(\\d{8}).*", "\\1", basename(f))

dates1 <- get_date(files1)
dates2 <- get_date(files2)

common_dates <- intersect(dates1, dates2)

files1 <- files1[dates1 %in% common_dates]
files2 <- files2[dates2 %in% common_dates]

files1 <- files1[order(get_date(files1))]
files2 <- files2[order(get_date(files2))]

combine_day <- function(f1, f2) {
  date <- get_date(f1)
  print(date)
  merra <- rast(f1)
  cape <- rast(f2)
  merra <- project(merra, cape)
  r <- c(cape[[1]], merra, cape[[2]], cape[[3]])
  r <- crop_rast(r)
  writeRaster(r, paste("~/Documents/lightning/scoring-combined/", date, ".tif", sep=""), overwrite = TRUE)
}

for (i in 1:(length(files1)-31)) {
  combine_day(files1[i+31], files2[i+31])
}
