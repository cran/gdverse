#' @title univariate discretization
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' Function to classify univariate vector to interval, a wrapper of `classInt::classify_intervals()`.
#'
#' @param x A continuous numerical variable.
#' @param k (optional) Number of classes required, `k` must greater than `1`.
#' @param method Chosen classify style: one of "fixed", "sd", "equal", "pretty", "quantile", "kmeans",
#' "hclust", "bclust", "fisher", "jenks", "dpih", "headtails", "maximum", or "box". Default is `quantile`.
#' @param factor (optional) Default is `FALSE`, if `TRUE` returns cols as a factor with intervals as
#' labels rather than integers.
#' @param seed (optional) Random seed number, default is `123456789`. Setting random seed is useful when
#' the sample size is greater than `3000`(the default value for `largeN`) and the data is discretized
#' by sampling `10%`(the default value for `samp_prop`).
#' @param ... (optional) Other arguments passed to `classInt::classify_intervals()`,
#' see `?classInt::classify_intervals()`.
#'
#' @return A discrete vector after being discretized.
#' @export
#'
#' @examples
#' xvar = c(22361, 9573, 4836, 5309, 10384, 4359, 11016, 4414, 3327, 3408,
#'          17816, 6909, 6936, 7990, 3758, 3569, 21965, 3605, 2181, 1892,
#'          2459, 2934, 6399, 8578, 8537, 4840, 12132, 3734, 4372, 9073,
#'          7508, 5203)
#' st_unidisc(xvar, k = 5, method = 'sd')
#'
st_unidisc = \(x,k,method = "quantile",factor = FALSE,
               seed = 123456789, ...){
  if (k <= 1) {stop(" `k` must greater than 1 !")}
  set.seed(seed)
  discedvec = suppressWarnings(classInt::classify_intervals(var = x, n = k,
                                                            style = method,...,
                                                            factor = factor))
  return(discedvec)
}

#' @title best univariate discretization based on geodetector q-statistic
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' Function for determining the best univariate discretization based on geodetector q-statistic.
#'
#' @param formula A formula of best univariate discretization.
#' @param data A data.frame or tibble of observation data.
#' @param discnum (optional) A vector of number of classes for discretization. Default is `3:22`.
#' @param discmethod (optional) A vector of methods for discretization,default is using
#' `c("sd","equal","pretty","quantile","fisher","headtails","maximum","box")`in `gdverse`.
#' @param cores (optional) A positive integer(default is 1). If cores > 1, a 'parallel' package
#' cluster with that many cores is created and used. You can also supply a cluster
#' object.
#' @param return_disc (optional) Whether or not return discretized result used the optimal parameter.
#' Default is `TRUE`.
#' @param seed (optional) Random seed number, default is `123456789`. Setting random seed is useful when
#' the sample size is greater than `3000`(the default value for `largeN`) and the data is discretized
#' by sampling `10%`(the default value for `samp_prop` in `st_unidisc()`).
#' @param ... (optional) Other arguments passed to `st_unidisc()`.
#'
#' @return A list with the optimal parameter in the provided parameter combination with `k`,
#' `method` and `disc`(when `return_disc` is `TRUE`).
#' \describe{
#' \item{\code{x}}{the name of the variable that needs to be discretized}
#' \item{\code{k}}{optimal discretization number}
#' \item{\code{method}}{optimal discretization method}
#' \item{\code{disc}}{optimal discretization results}
#' }
#' @export
#'
#' @examples
#' data('sim')
#' gd_bestunidisc(y ~ xa + xb + xc, data = sim,
#'                discvar = paste0('x',letters[1:3]),
#'                discnum = 3:6)
#'
gd_bestunidisc = \(formula, data, discnum = 3:22,
                   discmethod = c("sd","equal","pretty","quantile","fisher","headtails","maximum","box"),
                   cores = 1,return_disc = TRUE,seed = 123456789,...){
  doclust = FALSE
  if (inherits(cores, "cluster")) {
    doclust = TRUE
  } else if (cores > 1) {
    doclust = TRUE
    cores = parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(cores), add=TRUE)
  }

  formula = stats::as.formula(formula)
  formula.vars = all.vars(formula)
  response = data[, formula.vars[1], drop = TRUE]
  if (formula.vars[2] == "."){
    explanatory = data[,-which(colnames(data) == formula.vars[1])]
  } else {
    explanatory = subset(data, TRUE, match(formula.vars[-1], colnames(data)))
  }

  discname = names(explanatory)
  paradf = tidyr::crossing("x" = discname,
                           "k" = discnum,
                           "method" = discmethod)
  parak = split(paradf, seq_len(nrow(paradf)))

  calcul_disc = \(paramgd){
    xdisc = st_unidisc(explanatory[,paramgd[[1]],drop = TRUE],
                       k = paramgd[[2]],method = paramgd[[3]],
                       seed = seed, ...)
    fd = factor_detector(response,xdisc)
    q = fd[[1]]
    names(q) = "qstatistic"
    return(q)
  }

  if (doclust) {
    parallel::clusterExport(cores,c('st_unidisc','factor_detector'))
    out_g = parallel::parLapply(cores,parak,calcul_disc)
    out_g = tibble::as_tibble(do.call(rbind, out_g))
  } else {
    out_g = purrr::map_dfr(parak,calcul_disc)
  }

  out_g = dplyr::bind_cols(paradf,out_g) %>%
    dplyr::group_by(x) %>%
    dplyr::slice_max(order_by = qstatistic,
                     with_ties = FALSE) %>%
    dplyr::ungroup() %>%
    dplyr::select(-qstatistic) %>%
    as.list()

  if(return_disc){
    suppressMessages({resdisc = purrr::pmap_dfc(out_g,
                              \(x,k,method) st_unidisc(x = explanatory[,x,drop = TRUE],
                                                       k = k,method = method,...)) %>%
      purrr::set_names(out_g[[1]])})
    out_g = append(out_g,list("disv" = resdisc))
  }
  return(out_g)
}
