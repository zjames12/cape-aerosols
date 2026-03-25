library(terra)

# list all tif files
files <- list.files(
  path = "~/Documents/lightning/cape-aerosol-gefs-summer-2000-v8/manual_samples/20250803",
  pattern = "\\.tiff$",
  full.names = TRUE
)

template <- rast("~/Documents/lightning/template.tif")
template <- crop_rast(template[[1]])
r <- rast(files)

r_mean = deepcopy(template)
values(r_mean) <- values(mean(r))

r_spread = deepcopy(template)
values(r_spread) <- values( app(r, sd, na.rm = TRUE))


plot(r_mean, range = c(0, 5000))
plot(r_spread, range= c(0, 700))

files_no_fire <- list.files(
  path = "~/Documents/lightning/cape-aerosol-gefs-summer-2000-v8/manual_samples/20250803_20250401",
  pattern = "\\.tiff$",
  full.names = TRUE
)
r_no_fire <- rast(files_no_fire)

r_mean_no_fire = deepcopy(template)
values(r_mean_no_fire) <- values(mean(r_no_fire))

r_spread_no_fire = deepcopy(template)
values(r_spread_no_fire) <- values( app(r_no_fire, sd, na.rm = TRUE))

plot(r_mean_no_fire, range=c(0, 5000))
plot(r_spread_no_fire, range=c(0, 700))

r_mean_diff = r_mean - r_mean_no_fire
v = values(r_mean_diff)
level = 300
v[v >= -level & v <= level] <- NA
v[v > level] <- 1
v[v < -level] <- -1
values(r_mean_diff) <- v
cols <- c("red", "green")
breaks <- c(-1.5, 0, 1.5)
plot(r_mean_diff, col = cols, breaks = breaks, legend = FALSE)


r_spread_diff = r_spread - r_spread_no_fire
v = values(r_spread_diff)
level = 20
v[v >= -level & v <= level] <- NA
v[v > level] <- 1
v[v < -level] <- -1
values(r_spread_diff) <- v
cols <- c("red", "green")
breaks <- c(-1.5, 0, 1.5)
plot(r_spread_diff, col = cols, breaks = breaks, legend = FALSE)
