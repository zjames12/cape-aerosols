library(terra)
setwd("~/Documents/hrrr")

files1 <- list.files("~/Documents/merra/merra-1730-train-projected", full.names = TRUE, pattern = "\\.tif$")
files2 <- list.files("~/Documents/hrrr/gfs-1800-0-cape-forecast", full.names = TRUE, pattern = "\\.tif$")
files3 <- list.files("~/Documents/hrrr/gfs-1800-6-cape-forecast", full.names = TRUE, pattern = "\\.tif$")
files4 <- list.files("~/Documents/hrrr/gfs-2400-0-cape-forecast", full.names = TRUE, pattern = "\\.tif$")
files5 <- list.files("~/Documents/hrrr/gfs-1800-3-cape-forecast", full.names = TRUE, pattern = "\\.tif$")

get_date <- function(f) sub(".*(\\d{8}).*", "\\1", basename(f))

dates1 <- get_date(files1)
dates2 <- get_date(files2)
dates3 <- get_date(files3)
dates4 <- get_date(files4)
dates5 <- get_date(files5)

common_dates <- intersect(intersect(intersect(dates1, dates2), dates3), dates4)
common_dates <- intersect(common_dates, dates5)
# common_dates <- common_dates[4000:4002]

files1 <- files1[dates1 %in% common_dates]
files2 <- files2[dates2 %in% common_dates]
files3 <- files3[dates3 %in% common_dates]
files4 <- files4[dates4 %in% common_dates]
files5 <- files5[dates5 %in% common_dates]

# sort to ensure matching order
files1 <- files1[order(get_date(files1))]
files2 <- files2[order(get_date(files2))]
files3 <- files3[order(get_date(files3))]
files4 <- files4[order(get_date(files4))]
files5 <- files5[order(get_date(files5))]

combine_day <- function(f1, f2, f3, f4, f5) {
  date <- get_date(f1)
  print(date)
  r1 <- rast(f1)          
  r2 <- rast(f2)  
  r3 <- rast(f3)
  r4 <- rast(f4)
  r5 <- rast(f5)
  r <- c(r2, r5, r3, r1, r4)
  writeRaster(r, paste("~/Documents/hrrr/gfs-merra-1800-2400-0-3-6-forecast/", date, ".tif", sep=""), overwrite = TRUE)
}

for (i in 1:length(files1)){
  combine_day(files1[i], files2[i], files3[i], files4[i], files5[i])
}
