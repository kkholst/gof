##' @export
coef.cumres <- function(object,...) {
    res <- with(object, data.frame("KS p-value"=KS, "CvM p-value"=CvM))
    rownames(res) <- object$variable
    res
}
