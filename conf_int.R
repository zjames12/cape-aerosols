library(tseries)

bs <- function(diff) {
  boot_out <- tsbootstrap(diff, nb = 10000,
                          statistic = function(x) mean(x),
                          type = "stationary")
  
  boot_means <- boot_out$statistic
  ci <- quantile(boot_means, probs = c(0.025, 0.975)); 
  print(ci)
  print((ci[2]-ci[1])/2)
  print(mean(diff))
}

