library(terra)

files1 <- list.files("~/Documents/lightning/test-images", full.names = TRUE, pattern = "\\.tif$")
files2 <- list.files("~/Documents/merra/merra-1730-test", full.names = TRUE, pattern = "\\.nc$")

get_date <- function(f) sub(".*(\\d{8}).*", "\\1", basename(f))

dates1 <- substring(files1, 43, 50)
dates2 <- get_date(files2)
common_dates = intersect(dates1, dates2) # common_dates = common_dates[365:length(common_dates)]
files1 <- files1[dates1 %in% common_dates]
files2 <- files2[dates2 %in% common_dates]
files1 <- files1[order(common_dates)]
files2 <- files2[order(common_dates)]


combine_day <- function(f1, f2) {
  date <- get_date(f1)
  print(date)
  r1 <- rast(f1)          
  r2 <- rast(f2)  
  r2 <- project(r2, r1)
  r <- c(r1[[1]], r2, r1[[2]], r1[[3]])
  writeRaster(r, paste0("~/Documents/lightning/scoring-combined/", date, ".tif"), overwrite = TRUE)
}

for (i in 1096:length(common_dates)){
  combine_day(files1[i], files2[i])
}
