library(terra)
# setwd("~/Documents/lightning")

cape <- rast("cape200220222300.nc")
crs(cape) <- "EPSG:4326"
t <- substring(names(cape),17,26)
tt <- as.POSIXct(as.numeric(t), origin = "1970-01-01", tz = "UTC")
new_names = gsub("-", "", substring(tt, 1, 10))
names(cape) <- new_names
# cape_proj <- project(cape, r_fixed)


# files1 <- list.files("C:/Users/Zach/Documents/lightning/merra-1600/", full.names = TRUE, pattern = "\\.nc$")
files1 <- list.files("~/lightning/merra-1600/", full.names = TRUE, pattern = "\\.nc$")
files1 <- sort(files1)
files1 <- files1[1:2]
r1 <- rast(files1[1])

combine_day <- function(date) {
  print(date)
  # r1 <- rast(f1)  # 5 layers
  # r1 <- r1[[c("BCEXTTAU", "DUEXTTAU", "OCEXTTAU", "SSEXTTAU", "SUEXTTAU")]]
  crs(r1) <- "EPSG:4326"
  # date = substring(basename(f1), 28, 35)
  r3 <- cape[[date]]
  crs(r3) <- "EPSG:4326"
  r3 <- project(r3, r1)
  # ret <- c(r1, r3)       # combine into 6 layers
  writeRaster(r3, paste("images-2300-cape/", date, ".tif", sep=""), overwrite = TRUE)
  # df <- as.data.frame(ret, xy = TRUE)
  # names(df)[length(names(df))] <- "CAPE"
  # df$date = date
  return(df)

}
new_names = new_names[5752:7670] #1917 3834 5751 7670
t <- proc.time()
# df <- combine_day(files1[1])
for (i in 1:length(new_names)) {
  combine_day(new_names[i])
  # df <- rbind(df, combine_day(new_names[i]))
  # if (i %% 100 == 0){
  #   saveRDS(df, "20022020_1.rds")
  # }
}
print(proc.time()-t)
# saveRDS(df, "20022020_1.rds")
