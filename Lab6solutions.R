distract <- c(6,15,14,5)
distract.mat <- matrix(distract, byrow=T, ncol = 2, nrow = 2,
                       dimnames=list(Correct=c("Yes", "No"), 
                                     Distracted=c("Yes", "No")))
distract.mat
spineplot(distract.mat)

chisq.test(distract.mat, correct = F)
