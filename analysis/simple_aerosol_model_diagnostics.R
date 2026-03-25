library(lubridate)
library(ggplot2)
library(dplyr)
library(fields)
library(maps)

m4 <- readRDS("model4_covparms.rds")
m4 <- readRDS("model_6b_scaledim_covparms.rds")

df <- readRDS("20022020_1M.rds")
df$year = as.numeric(substring(df$date, 1,4)) - 2000
df$month = as.numeric(substring(df$date, 5,6))
df$day = as.numeric(substring(df$date, 7,8))
df$date = as.Date(df$date, "%Y%m%d")
df$dayssince = as.numeric(df$date - min(df$date))
df$date <- as.Date(df$date, "%Y%m%d")
# yhat = as.matrix(df[,3:7]) %*% m4$betahat
yhat = predictions(m4, df[1:10000,c(1:2,10:13)],cbind(intercept=rep(1,10000),df[1:10000,3:7]))
y = log(df$CAPE+1)[1:10000]
df$residual = y-yhat

plot(yhat, y-yhat, xlim = c(-.5,2.5), ylim = c(-2,8))

df_2015 = df[year(df$date) == 2015,]
plot(df_2014$date, df_2014$residual)#, xlim = c(-.5,2.5), ylim = c(-2,8))
plot(df$date, df$residual)#, xlim = c(-.5,2.5), ylim = c(-2,8))
ggplot(df, aes(x = date, y = residual, alpha=0.5)) +
  geom_point() +
  ylab("Residual") +
  xlab("Date") + 
  theme_bw()
ggplot(df_2015, aes(x = date, y = residual, alpha=0.5)) +
  geom_point() +
  ylab("Residual") +
  xlab("Date") + 
  theme_bw()

df_weekly <- df %>%
  mutate(day = cut(date, breaks = "month")) %>%
  group_by(day) %>%
  summarise(val = mean(residual, na.rm = TRUE))
acf(df_weekly$val, main = "Monthly Residuals")

qqPlot(df$residual)

max_val = as.Date("2022-01-01")
min_val = as.Date("2002-01-01")
duration = "year"
bins <- cut(df$date, breaks = seq(min_val, max_val, by = duration), include.lowest = TRUE)
avg_y <- tapply(df$residual, bins, mean)
breaks <- seq(min_val, max_val, by = duration)
plot(breaks[-1], avg_y)

# Three coordinates: x,y, days since
# Covariance Function: exponential_scaledim
# 
# Covariance Parameters:
#   4.7463 11.2273 8.5083 2.338 0
# 
# Loglikelihood: -1644524.4676
# 
# Linear Mean Parameters:
#   variable estimate std_error   t_stat
# 1 BCEXTTAU -10.3249    0.5419 -19.0523
# 2 DUEXTTAU  -2.1748    0.1545 -14.0802
# 3 OCEXTTAU   0.9027    0.0439  20.5558
# 4 SSEXTTAU   5.9643    0.0476 125.4071
# 5 SUEXTTAU   5.8130    0.0409 141.9645
# m4$betahat = c(-10.3249, -2.1748, 0.9027, 5.9643, 5.8130)
df_20150701 <- readRDS("20022020.rds")
df_20150701 <- df_20150701[df_20150701$date == "20081101",]
df_20150701$year = as.numeric(substring(df_20150701$date, 1,4)) - 2000
df_20150701$month = as.numeric(substring(df_20150701$date, 5,6))
df_20150701$day = as.numeric(substring(df_20150701$date, 7,8))
df_20150701$date = as.Date(df_20150701$date, "%Y%m%d")
df_20150701$dayssince = as.numeric(df_20150701$date - min(df$date))
df_20150701$date <- as.Date(df_20150701$date, "%Y%m%d")
quilt.plot(df_20150701[,1:2], log(df_20150701$CAPE+1), nx = 140, ny = 60, asp =1)
map("world", add = TRUE, col = "white", lwd = 2)

yhatns = as.matrix(cbind(intercept=rep(1,nrow(df_20150701)),df_20150701[,3:7]))%*% m4$betahat
yhat = predictions(m4, df_20150701[,c(1:2,10:13)],cbind(intercept=rep(1,nrow(df_20150701)),df_20150701[,3:7]))

y = log(df_20150701$CAPE+1)
df_20150701$residual = y-yhat
quilt.plot(df_20150701[,1:2], yhatns, nx = 140, ny = 60, asp =1)
map("world", add = TRUE, col = "white", lwd = 2)


quilt.plot(df_20150701[,1:2], yhat, nx = 140, ny = 60, asp =1)
map("world", add = TRUE, col = "white", lwd = 2)


# Test model performance
df <- readRDS("20022020.rds")
df <- df[df$date=="20160715",]
df$day <- rep(15, nrow(df))
preds <- predictions(m4, df[,c(1:2,10)], cbind(rep(1,nrow(df)),df[,3:7]), m = 30)
quilt.plot(df[,1:2], log(df$CAPE+1), nx = 128, ny = 64)
quilt.plot(df[,1:2], preds, nx = 128, ny = 64)

