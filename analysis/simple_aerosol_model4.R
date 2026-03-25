library(GpGp)
set.seed(1)

df <- readRDS("201507.rds")
# df <- df[sample(1:nrow(df),1000000),]
# saveRDS(df, "20022020_1M.rds")
# print(head(df))
# df$year = as.numeric(substring(df$date, 1,4)) - 2000
# df$month = as.numeric(substring(df$date, 5,6))
df$day = as.numeric(substring(df$date, 7,8))
# df$date = as.Date(df$date, "%Y%m%d")
# df$dayssince = as.numeric(df$date - min(df$date))

df$CAPE = df$CAPE + abs(rnorm(nrow(df), sd=0.01))
m4 <- fit_model(log(df$CAPE+1), df[,c(1:2,10)], X = cbind(intercept=rep(1,nrow(df)),df[,3:7]),
               covfun_name = "exponential_scaledim")
saveRDS(m4, "model_201507_scaledim_covparms.rds")
print(summary(m4))


