library(GpGp)
set.seed(1)
# df25 <- readRDS("2025-07-noon.rds")
# df24 <- readRDS("2024-07-noon.rds")
# df23 <- readRDS("2023-07-noon.rds")
# df238 <- readRDS("2023-08-noon.rds")
# df248 <- readRDS("2024-08-noon.rds")
# 
# df <- rbind(df23, df24, df25, df238, df248)

df <- readRDS("20022020_1M.rds")

print(head(df))
df$year = as.numeric(substring(df$date, 1,4)) - 2000
df$month = as.numeric(substring(df$date, 5,6))
df$day = as.numeric(substring(df$date, 7,8))
df$date = as.Date(df$date, "%Y%m%d")
df$dayssince = as.numeric(df$date - min(df$date))

df$CAPE = df$CAPE + abs(rnorm(nrow(df), sd=0.01))
m4 <- fit_model(log(df$CAPE+1), df[,c(1:2,13)], X = df[,3:7],
                covfun_name = "exponential_scaledim")#,
#max_iter = 40, m_seq = c(10))
saveRDS(m4[1:10], "model5_scaledim_covparms.rds")
print(summary(m4))


