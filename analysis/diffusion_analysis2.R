library(viridisLite)

v1<- rep(0, length(values(real[[8]])))

files1 <- list.files("~/Documents/lightning/gfs-samples/20150701", full.names = TRUE, pattern = "\\.tiff$")
files2 <- list.files("~/Documents/lightning/gfs-samples/20150701_zero_intervention", full.names = TRUE, pattern = "\\.tiff$")


r <- rast(files1)
ext(r) <- ext(real)
r_ensemble <- app(r, sd)
plot(r_ensemble, col= magma(200), range=c(0,600))
# plot(r_ensemble, range=c(0,4500))


r <- rast(files2)
ext(r) <- ext(real)
r_gefs <- app(r, sd)
plot(r_gefs, col= magma(200), range=c(0,600))
# plot(r_gefs, range=c(0,4500))

plot(abs(r_gefs-r_ensemble), range=c(0,600))





max_cape = c()
mean_cape = c()
q99_cape = c()
for (file in files){
  pred <- rast(file)
  v1 = v1 + values(pred)
  q99_cape = c(q99_cape,as.numeric(quantile(values(pred),.99)))
  max_cape = c(max_cape,max(values(pred)))
  mean_cape = c(mean_cape,mean(values(pred)))
}
v1 = v1 / length(files)
values(pred) <- v1

v2<- rep(0, length(values(real[[8]])))
files <- list.files("~/Documents/lightning/gfs-samples/20150701_zero_intervention", full.names = TRUE, pattern = "\\.tiff$")
max_cape2 = c()
mean_cape2 = c()
q99_cape2 = c()
for (file in files){
  pred <- rast(file)
  v2 = v2 + values(pred)
  q99_cape2 = c(q99_cape2,as.numeric(quantile(values(pred),.99)))
  max_cape2 = c(max_cape2,max(values(pred)))
  mean_cape2 = c(mean_cape2,mean(values(pred)))
}
v2 = v2 / length(files)
values(pred2) <- v2

plot(pred, range=c(0,5000))
plot(pred2, range=c(0,5000))

hist(mean_cape2, breaks=20, xlim = c(400,800), col=rgb(0,0,1,0.5),
     main="Mean CAPE for True (red) and Modified (blue) Inputs", xlab = "CAPE J/kg")
hist(mean_cape, breaks=20, xlim = c(400,800), col=rgb(1,0,0,0.5), 
     main="Mean CAPE for True Input", xlab = "CAPE J/kg", add=T)


hist(max_cape1, breaks=20, xlim = c(3000,8000), col=rgb(1,0,0,0.5), 
     main="Distribution of Max Atmospheric Energy", xlab = "CAPE J/kg")#, ylim=c(0,100))
hist(max_cape2, breaks=20, xlim = c(3000,8000), col=rgb(0,0,1,0.5), 
     main="Tail Max CAPE for True Input", 
     xlab = "CAPE J/kg", ylim=c(0,100), add = T)
legend("topright",
       legend = c("True", "Modified"),
       col = c(rgb(1,0,0,0.5), rgb(0,0,1,0.5)),
       pch = 16,
       bty = "n") 

pred3 = r_gefs- r_ensemble
ext(pred3) <- ext(real)
plot(pred3)
map("state", add = TRUE, col = rgb(0,0,0,.1), lwd = 0.5)
map("world", add = TRUE, col = rgb(0,0,0,0.5), lwd = 1)
map("state", add = TRUE, col = rgb(1,1,1,.1), lwd = 0.5)
map("world", add = TRUE, col = rgb(1,1,1,0.5), lwd = 1)
change <- values(pred3)
change[change <= 50 & change >= -50] = 0
change[change > 0] = 1
change[change < 0] = -1
pred_change <- deepcopy(pred3)
values(pred_change) <- change
plot(pred_change, col = c(rgb(1,0,0,0.8), "white", rgb(0,1,0,0.8)), legend=T)

neg_change <- values(pred)
neg_change[neg_change >= -100] = 0
neg_pred <- deepcopy(pred)
neg_change[neg_change == 0] <- NA
values(neg_pred) <- neg_change
# plot(r[[2]], col = RColorBrewer::brewer.pal(9, "YlOrRd"))

plot(neg_pred)
