library(terra)
# setwd("~/Documents/lightning")

# files1 <- list.files("C:/Users/Zach/Documents/lightning/merra-1600/", full.names = TRUE, pattern = "\\.nc$")
files1 <- list.files("~/Documents/hrrr/hrrr-projected", full.names = TRUE, pattern = "\\.tif$")
files2 <- list.files("~/Documents/lightning/images-2300-cape-aerosols", full.names = TRUE, pattern = "\\.tif$")
get_date <- function(f) substring(basename(f), 1,8)
dates1 <- get_date(files1)
dates2 <- get_date(files2)
common_dates <- intersect(dates1, dates2)

files1 <- files1[dates1 %in% common_dates]
files2 <- files2[dates2 %in% common_dates]

# sort to ensure matching order
ord1 <- order(get_date(files1))
ord2 <- order(get_date(files2))

files1 <- files1[ord1]
files2 <- files2[ord2]


combine_day <- function(f1, f2) {
  date <- get_date(f1)
  print(date)
  r1 <- rast(f1)          # 5 layers
  r2 <- rast(f2)          # 1 layer
  r <- c(r1, r2)
  writeRaster(r, paste("images-2300-cape-aerosols-hrrr/", date, ".tif", sep=""), overwrite = TRUE)
}

# build list of daily stacks
t <- proc.time()
l <- mapply(combine_day, files1, files2, SIMPLIFY = FALSE)
print(proc.time() - t)
