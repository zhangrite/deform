#' Error functions
#' @param x numeric
#' @export
erf <- function(x){
  2 * pnorm(x * sqrt(2)) - 1
}

#' @rdname erf
#' @export
erfc <- function(x){
  2 * pnorm(x * sqrt(2), lower.tail = FALSE)
}

#' @rdname erf
#' @export
ierf <- function (x){
  qnorm((1 + x) / 2) / sqrt(2)
}

#' @rdname erf
#' @export
ierfc <- function (x){
  qnorm(x/2, lower.tail = FALSE) / sqrt(2)
}

#' @rdname erf
#' @export
ierfc2 <- function(x){
  exp(-1 * x^2) / sqrt(pi) - x * erfc(x)
}