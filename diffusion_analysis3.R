files1 <- list.files("~/Documents/lightning/samples/20150701", full.names = TRUE, pattern = "\\.tiff$")
files2 <- list.files("~/Documents/lightning/samples/20150701_intervention", full.names = TRUE, pattern = "\\.tiff$")

max_cape1 = c()
q99_cape1 = c()

for (file in files1){
  pred <- rast(file)
  q99_cape1 = c(q99_cape1,as.numeric(quantile(values(pred),.99)))
  max_cape1 = c(max_cape1,max(values(pred)))
}

max_cape2 = c()
q99_cape2 = c()
for (file in files2){
  pred <- rast(file)
  q99_cape2 = c(q99_cape2,as.numeric(quantile(values(pred),.99)))
  max_cape2 = c(max_cape2,max(values(pred)))
}
se = sd(c(max_cape1, max_cape2))*sqrt(2/1024)
t = (mean(max_cape1) - mean(max_cape2))/se
df = 1024+1024-2
pt(t, df)

p1 = as.numeric(max_cape1 > 6000)
p2 = as.numeric(max_cape2 > 6000)

se = sd(c(p1, p2))*sqrt(2/1024)
t = (mean(p1) - mean(p2))/se
df = 1024+1024-2
pt(t, df)
