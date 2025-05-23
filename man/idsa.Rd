% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/idsa.R
\name{idsa}
\alias{idsa}
\title{interactive detector for spatial associations(IDSA) model}
\usage{
idsa(
  formula,
  data,
  wt = NULL,
  discnum = 3:8,
  discmethod = "quantile",
  overlay = "and",
  strategy = 2L,
  increase_rate = 0.05,
  cores = 1,
  seed = 123456789,
  alpha = 0.95,
  ...
)
}
\arguments{
\item{formula}{A formula of IDSA model.}

\item{data}{A \code{data.frame}, \code{tibble} or \code{sf} object of observation data.}

\item{wt}{(optional) The spatial weight matrix. When \code{data} is not an \code{sf} object, must provide \code{wt}.}

\item{discnum}{(optional) Number of multilevel discretization. Default will use \code{3:8}.}

\item{discmethod}{(optional) The discretization methods. Default all use \code{quantile}.
Noted that  \code{rpart} will use \code{rpart_disc()}; Others use \code{sdsfun::discretize_vector()}.}

\item{overlay}{(optional) Spatial overlay method. One of \code{and}, \code{or}, \code{intersection}.
Default is \code{and}.}

\item{strategy}{(optional) Discretization strategy. When \code{strategy} is \code{1L}, choose the highest SPADE model q-statistics to
determinate optimal spatial data discretization parameters. When \code{strategy} is \code{2L}, The optimal discrete parameters of
spatial data are selected by combining LOESS model.}

\item{increase_rate}{(optional) The critical increase rate of the number of discretization.
Default is \verb{5\%}.}

\item{cores}{(optional) Positive integer (default is 1). When cores are greater than 1, use
multi-core parallel computing.}

\item{seed}{(optional) Random number seed, default is \code{123456789}.}

\item{alpha}{(optional) Specifies the size of confidence level. Default is \code{0.95}.}

\item{...}{(optional) Other arguments passed to \code{cpsd_disc()}.}
}
\value{
A list.
\describe{
\item{\code{interaction}}{the interaction result of IDSA model}
\item{\code{risk}}{whether values of the response variable between a pair of overlay zones are significantly different}
\item{\code{number_individual_explanatory_variables}}{the number of individual explanatory variables used for examining the interaction effects}
\item{\code{number_overlay_zones}}{the number of overlay zones}
\item{\code{percentage_finely_divided_zones}}{the percentage of finely divided zones that are determined by the interaction of variables}
}
}
\description{
interactive detector for spatial associations(IDSA) model
}
\note{
\strong{Please note that all variables in the IDSA model need to be continuous data}.

The IDSA model requires at least \eqn{2^n-1} calculations when has \eqn{n} explanatory variables.
When there are more than 10 explanatory variables, carefully consider the computational burden of this model.
When there are a large number of explanatory variables, the data dimensionality reduction method can be used
to ensure the trade-off between analysis results and calculation speed.
}
\examples{
data('sim')
sim1 = sf::st_as_sf(sim,coords = c('lo','la'))
g = idsa(y ~ ., data = sim1)
g

}
\references{
Yongze Song & Peng Wu (2021) An interactive detector for spatial associations,
International Journal of Geographical Information Science, 35:8, 1676-1701,
DOI:10.1080/13658816.2021.1882680
}
\author{
Wenbo Lv \email{lyu.geosocial@gmail.com}
}
