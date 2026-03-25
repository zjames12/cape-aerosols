library(raster)
library(terra)

setwd("C:/Users/Zach/Documents/lightning/data")

r <- rast("2024-07-01-gridded.nc")

for (i in 2:31){
  file_name = paste("2024-07-",sprintf("%02d", i),"-gridded.nc", sep="")
  r2 = rast(file_name)
  vals = values(r2)
  if (min(vals) < 0) {
    print(file_name)
  }
  r = r + r2
}


spplot(log10(r))
spplot(r)


r_ll <- project(r, "EPSG:4326", method="mode")
writeCDF(r_ll, "lightning-2018-07.nc", overwrite = TRUE)
r_ll <- rast("lightning-2018-07.nc")

spplot(log10(r_ll))
spplot(r_ll)

r_crop <- crop(r, extent(-4e+06,1e+06,-5e+06,-2e+06))

e <- extent(-76,-73,43,45)
r_crop <- crop(r_ll, e, snap="out")
spplot(r_crop)
spplot(log10(r_crop))

# r <- rast("lightning-2018-07-01.nc")
r_flip <- flip(r, direction="vertical")
e <- extent(-128, -65, 24, 50)
r_crop <- crop(r_flip, e)
plot(r_crop)
us_states <- vect(ne_states(country="United States of America", returnclass="sf"))
world <- vect(ne_countries(scale="medium", returnclass="sf"))
lines(world, col="black", lwd=0.3)
lines(us_states, col="black", lwd=0.3)



fn <- "C:\\Users\\Zach\\data\\noaa-goes16\\ABI-L2-ACHTM\\2021\\365\\23\\OR_ABI-L2-ACHTM2-M6_G16_s20213652359551_e20220010000010_c20220010001428.nc"
fn <- "C:\\Users\\Zach\\data\\noaa-goes16\\ABI-L2-BRFF\\2022\\001\\00\\OR_ABI-L2-BRFF-M6_G16_s20220010000205_e20220010009513_c20220010011290.nc"
a <- rast(fn)

files <- list.files("~/Documents/lightning/scoring-cape/", full.names = TRUE, pattern = "\\.tif$")

