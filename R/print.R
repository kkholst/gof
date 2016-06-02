##' @S3method print cumres
print.cumres <- function(x,...) {
    cat("\n");
    for (i in 1:length(x$variable)) {
        if (!is.null(x$KS)) cat("Kolmogorov-Smirnov-test: p-value=", x$KS[i], "\n", sep="")
        if (!is.null(x$CvM)) cat("Cramer von Mises-test: p-value=", x$CvM[i], "\n", sep="")
        cat("Based on ", x$R, " realizations. Cumulated residuals ordered by ", x$variable[i], "-variable.\n", sep="")
        cat("---\n");
    }
    invisible(x)
}

##' @S3method summary cumres
summary.cumres <- function(object,...) print(object,...)
