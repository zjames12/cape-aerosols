library(terra)

files1 <- list.files("~/Documents/summer/test-gefs-2400-c00", full.names = TRUE, pattern = "\\.tif$")
files2 <- list.files("~/Documents/merra/merra-1730-test", full.names = TRUE, pattern = "\\.nc$")
files3 <- list.files("~/Documents/summer/test-gefs-1800-2400-c00", full.names = TRUE, pattern = "\\.tif$")
files4 <- list.files("~/Documents/summer/test-gefs-1800-c00", full.names = TRUE, pattern = "\\.tif$")

get_date <- function(f) sub(".*(\\d{8}).*", "\\1", basename(f))

dates1 <- substring(files1, 47, 54)
dates2 <- get_date(files2)
dates3 <- substring(files3,  52, 59)
dates4 <- substring(files4,  47, 54)
common_dates = intersect(intersect(intersect(dates1, dates2),dates3),dates4) # common_dates = common_dates[365:length(common_dates)]
files1 <- files1[dates1 %in% common_dates]
files2 <- files2[dates2 %in% common_dates]
files3 <- files3[dates3 %in% common_dates]
files4 <- files4[dates4 %in% common_dates]
files1 <- files1[order(common_dates)]
files2 <- files2[order(common_dates)]
files3 <- files3[order(common_dates)]
files4 <- files4[order(common_dates)]

combine_day <- function(f1, f2, f3, f4) {
  date <- get_date(f1)
  print(date)
  r1 <- rast(f1)          
  r2 <- rast(f2)  
  r3 <- rast(f3)
  r4 <- rast(f4)
  r2 <- project(r2, r1)
  r <- c(r3, r2, r4, r1)
  writeRaster(r, paste0("~/Documents/lightning/scoring-combined-gefs/", date, ".tif"), overwrite = TRUE)
}

for (i in 1:length(common_dates)){
  combine_day(files1[i], files2[i], files3[i], files4[i])
}














