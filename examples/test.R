library(lava)
devtools::load_all("../R-package")

m <- lvm(list(c(y1,y2,y3)~eta,eta~x)); latent(m) <- ~eta
## simulate some data with non-linear covariate effect
functional(m,eta~x) <- function(x) 0.3*x^2
d <- sim(m,500)

e <- estimate(m,d)
g <- gofobs::cumres(e,eta~x,R=1000)

## Checking the functional form of eta on x
g <- gof::cumres(e,eta~x,R=1000)

x <- function(p) predict(e,x=~y2+y3,p=p)[,"eta"]
## Checking the functional form of y1 on eta
cumres(e,y1~eta,R=1000)
g <- cumres(e,"y1",x=x,R=1000)
plot(g)




ord <- order(g$x)
t0 <- g$x[ord]
r0 <- g$r[ord]
dr0 <- g$dr[ord,]
ii0 <- g$ic[ord,,drop=FALSE]
eta <- -apply(dr0,2,cumsum)
KS <- function(x) max(abs(x))
n <- length(r0)

R <- 100
Ws <- matrix(0,n,max(100,R))
stat <- numeric(R)
for (i in seq(R)) {
    G0 <- rnorm(n, sd=1)
    W1 <- cumsum(G0*r0)
    iiG <- colSums(apply(ii0,2,function(x) x*G0))
    W2 <- apply(eta, 1, function(x) crossprod(x, iiG))
    (Wi <- (W1+W2)/sqrt(n))
    if (i<=ncol(Ws))
        Ws[,i] <- Wi
    stat[i] <- KS(Wi)
    if (i%%50==0) message(i)
}

W0 <- cumsum(r0)/sqrt(n)
matplot(t0, Ws, type="s", col=lava::Col(1,0.3), ylim=range(c(W0,Ws)))
lines(t0, W0, type="s", lwd=3, col=lava::Col("darkred",.5))



x <- function(p) predict(e,x=~y2+y3,p=p)[,"eta"]
## Checking the functional form of y1 on eta
cumres(e,y1~eta,R=1000)
g <- cumres(e,"y1",x=x,R=1000)
plot(g)


library(Rcpp)
library("futile.logger")
flog.layout(layout.colored)
set.seed(1)
n <- 1000
flog.info("Simulating (n=%s)", n)
x <- rnorm(n)
z <- seq(0,1,length.out=n)
y <- 0.1*x*x + x + z + rnorm(n)
d <- data.frame(y,x,z)
write.table(d, file="d.csv", row.names=FALSE, col.names=FALSE, sep=",")
l <- lm(y~x+z, data=d)
ii <- lava::iid(l)
r <- residuals(l)
t <- x ## Variable to order residuals after
d2 <- data.frame(r,t,ii)
write.table(d2, file="r.csv", row.names=FALSE, col.names=FALSE, sep=",")
X <- model.matrix(l)


gg <- cumres(l,R=1e4)
par(mfrow=c(2,2)); plot(gg)

 Rcpp::compileAttributes("../R-package/")
devtools::load_all("../R-package")

g <- new(gof::CumRes, r, -X, ii);
g$reorder(predict(l))
ks0 <- KolmogorovSmirnov(g$obs())
mean(g$samplestat(1e4, 0:499, FALSE)[,1]>ks0)

g$reorder(x)
ks0 <- KolmogorovSmirnov(g$obs())
mean(g$samplestat(1e4, 0:499, FALSE)[,1]>ks0)

g$reorder(z)
ks0 <- KolmogorovSmirnov(g$obs())
mean(g$samplestat(1e4, 0:499, FALSE)[,1]>ks0)

g$rnorm()[1:10]

g$reorder(t)
t0 <- g$t
W0 <- g$obs()
t1a <- t0[mets::fast.approx(t0, seq(t0[1], t0[n], length.out=50))]
t1b <- quantile(t0, seq(0,1,length.out=50))
t1 <- sort(union(t1a,t1b))
pos <- 1
idx <- numeric(n) # grouping
for (i in seq_along(idx)) {
    if (t0[i]>t1[pos]) {
        pos <- pos+1        
    }
    idx[i] <- pos
}
idx1 <- mets::dby(data.frame(id=idx, pos=seq_along(idx)), pos~id, pos=max, REDUCE=T)$pos

Rplot <- 200
Ws <- matrix(0,length(idx1),Rplot)
for (i in seq(Rplot))
    Ws[,i] <- g$sample1(idx1-1)
plot(t0, W0, type="n", ylim=range(W0,Ws))
matplot(t0[idx1], Ws, type="s", col=Col(1,0.2), lty=1, lwd=2)
lines(t0, W0, type="s", col=lava::Col("darkred", 0.7), lwd=5, ylim=range(W0,Ws))
 
## library(gofobs)
## g0 <- gofobs::cumres(l, R=1e4)

gof:::gof_samplestat(g)
