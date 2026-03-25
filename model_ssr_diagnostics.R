ssr0101 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220101_2.csv")
ssr0201 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220201_2.csv")
ssr0301 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220301_2.csv")
ssr0401 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220401_2.csv")
ssr0501 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220501_2.csv")
ssr0601 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220601_2.csv")
ssr0701 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220701_2.csv")
ssr0801 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220801_2.csv")
ssr0901 <- read.csv("~/Documents/lightning/spread_skill_ratio_20220901_2.csv")
ssr1001 <- read.csv("~/Documents/lightning/spread_skill_ratio_20221001_2.csv")
ssr1101 <- read.csv("~/Documents/lightning/spread_skill_ratio_20221101_2.csv")
ssr1201 <- read.csv("~/Documents/lightning/spread_skill_ratio_20221201_2.csv")

plot(ssr0101$guidenence, ssr0101$spread_skill_ratio, ylim = c(0,1.5), type="l", 
     col="red", xlab="Guidance", ylab="Spread Skill Ratio",)
# points(ssr0101$guidenence, ssr0101$spread_skill_ratio, col = "red", type="l")
points(ssr0201$guidenence, ssr0201$spread_skill_ratio, col = "red", type="l")
points(ssr0301$guidenence, ssr0301$spread_skill_ratio, col = "green", type="l")
points(ssr0401$guidenence, ssr0401$spread_skill_ratio, col = "green", type="l")
points(ssr0501$guidenence, ssr0501$spread_skill_ratio, col = "green", type="l")
points(ssr0601$guidenence, ssr0601$spread_skill_ratio, col = "blue", type="l")
points(ssr0701$guidenence, ssr0701$spread_skill_ratio, col = "blue", type="l")
points(ssr0801$guidenence, ssr0801$spread_skill_ratio, col = "blue", type="l")
points(ssr0901$guidenence, ssr0901$spread_skill_ratio, col = "black", type="l")
points(ssr1001$guidenence, ssr1001$spread_skill_ratio, col = "black", type="l")
points(ssr1101$guidenence, ssr1101$spread_skill_ratio, col = "black", type="l")
points(ssr1201$guidenence, ssr1201$spread_skill_ratio, col = "red", type="l")
abline(h=1, lty=2)
# abline(v=.4, lty=2)
legend(
  "topright",
  legend = c("Winter", "Spring", "Summer", "Fall"),
  col = c("red", "green", "blue", "black"),
  pch = 16
)


plot(ssr0101$guidenence, ssr0101$rmse, type="l", col = "red",
     xlab="Guidance", ylab="RMSE")
# points(ssr0101$guidenence, ssr0101$rmse, col = "red", type="l")
points(ssr0201$guidenence, ssr0201$rmse, col = "red", type="l")
points(ssr0301$guidenence, ssr0301$rmse, col = "red", type="l")
points(ssr0401$guidenence, ssr0401$rmse, col = "green", type="l")
points(ssr0501$guidenence, ssr0501$rmse, col = "green", type="l")
points(ssr0601$guidenence, ssr0601$rmse, col = "green", type="l")
points(ssr0701$guidenence, ssr0701$rmse, col = "blue", type="l")
points(ssr0801$guidenence, ssr0801$rmse, col = "blue", type="l")
points(ssr0901$guidenence, ssr0901$rmse, col = "blue", type="l")
points(ssr1001$guidenence, ssr1001$rmse, col = "black", type="l")
points(ssr1101$guidenence, ssr1101$rmse, col = "black", type="l")
points(ssr1201$guidenence, ssr1201$rmse, col = "black", type="l")
legend(
  "topright",
  legend = c("Winter", "Spring", "Summer", "Fall"),
  col = c("red", "green", "blue", "black"),
  pch = 16
)

spring <- rast("spring.tif")
summer <- rast("summer.tif")
fall <- rast("fall.tif")
winter <- rast("winter.tif")

winter <- clamp(winter, lower=1, upper=800, values=TRUE)
spring <- clamp(spring, lower=1, upper=800, values=TRUE)
summer <- clamp(summer, lower=1, upper=800, values=TRUE)
fall <- clamp(fall, lower=1, upper=800, values=TRUE)
par(mfrow=c(1,1))
plot(log10(winter), range=c(0,2.9), legend= FALSE, axes=F)
plot(log10(spring), range=c(0,2.9), legend= FALSE, axes=F)
plot(log10(summer), range=c(0,2.9), legend= FALSE, axes=F)
plot(log10(fall), range=c(0,2.9), legend= T, axes=F)
map("world", add = TRUE, col = rgb(1,1,1,0.5), lwd = 1)
map("state", add = TRUE, col = rgb(1,1,1,0.1), lwd = 0.5)


#gefs
spring_gefs <- rast("spring_gefs.tif")
summer_gefs <- rast("summer_gefs.tif")
fall_gefs <- rast("fall_gefs.tif")
winter_gefs <- rast("winter_gefs.tif")

winter_gefs <- clamp(winter, lower=1, upper=800, values=TRUE)
spring_gefs <- clamp(spring, lower=1, upper=800, values=TRUE)
summer_gefs <- clamp(summer, lower=1, upper=800, values=TRUE)
fall_gefs <- clamp(fall, lower=1, upper=800, values=TRUE)
par(mfrow=c(1,1))
plot(log10(winter), range=c(0,2.9), legend= FALSE, axes=F)
plot(log10(spring), range=c(0,2.9), legend= FALSE, axes=F)
plot(log10(summer), range=c(0,2.9), legend= FALSE, axes=F)
plot(log10(fall), range=c(0,2.9), legend= F, axes=F)
map("world", add = TRUE, col = rgb(1,1,1,0.5), lwd = 1)
map("state", add = TRUE, col = rgb(1,1,1,0.1), lwd = 0.5)


winter_crpsss <- rast("winter_crpsss2.tif")
wcc <- crop(winter_crpsss, ext(-126.25, -66.75, 24.50, 55))
plot(winter_crpsss)
plot(wcc)
mean(values(winter_crpsss), na.rm=TRUE)
mean(values(wcc))

winter_gefs <- rast("winter_crpsss.tif")
wcc <- crop(winter_gefs, ext(-126.25, -66.75, 24.50, 55))
mean(values(wcc))
