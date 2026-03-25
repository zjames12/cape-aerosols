library(terra)
setwd("~/Documents/hrrr")

# files1 <- list.files("~/Documents/merra/merra-1730-test-projected", full.names = TRUE, pattern = "\\.tif$")
# files2 <- list.files("~/Documents/hrrr/gfs-1800-0-cape-forecast", full.names = TRUE, pattern = "\\.tif$")
# files3 <- list.files("~/Documents/hrrr/gfs-1800-6-cape-forecast", full.names = TRUE, pattern = "\\.tif$")
# files4 <- list.files("~/Documents/hrrr/gfs-2400-0-cape-forecast", full.names = TRUE, pattern = "\\.tif$")
# files1 <- list.files("~/Documents/summer/gefs-merra-1800-2400-summer-forecast", full.names = TRUE, pattern = "\\.tif$")
files1 <- list.files("~/Documents/lightning/scoring-combined", full.names = TRUE, pattern = "\\.tif$")

files2 <- list.files("~/Documents/hrrr/gfs-1800-3-cape-forecast", full.names = TRUE, pattern = "\\.tif$")

get_date <- function(f) sub(".*(\\d{8}).*", "\\1", basename(f))

dates1 <- get_date(files1)
dates2 <- get_date(files2)


common_dates <- intersect(dates1, dates2)

files1 <- files1[dates1 %in% common_dates]
files2 <- files2[dates2 %in% common_dates]


# sort to ensure matching order
files1 <- files1[order(get_date(files1))]
files2 <- files2[order(get_date(files2))]


combine_day <- function(f1, f2) {
  date <- get_date(f1)
  print(date)
  r1 <- rast(f1)          
  r2 <- rast(f2)  
  # r <- c(r1[[7]], r2, r1[[1]], r1[[2:6]], r1[[8]])
  r <- c(r1[[7]], crop_rast(r2), r1[[1]],  r1[[2:6]], r1[[8]])
  # writeRaster(r, paste("~/Documents/hrrr/gefs-merra-1800-2400-0-3-6-forecast/", date, ".tif", sep=""), overwrite = TRUE)
  writeRaster(r, paste("~/Documents/lightning/scoring-combined-0-3-6/", date, ".tif", sep=""), overwrite = TRUE)
}

for (i in 1:length(files1)){
  combine_day(files1[i], files2[i])
}
