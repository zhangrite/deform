#' Surface deformation from Mogi-type volume sources
#' 
#' Modified from [1]: Computes radial and vertical displacements, ground tilt, and
#' radial and tangential strain on the surface, at radial distances 
#' from the top of the source, due to a hydrostatic pressure inside a 
#' spherical cavity at some depth in a homogeneous elastic halfspace
#' (center of dilatation). See Mogi (1958).
#'
#' @details Strain is reckoned positive for extension. For insight into what a positive
#' tilt is, see \code{\link{Tilt}}.
#' 
#' Units are shown next to the argument descriptions.   
#' 
#' Typical moduli are in the range of 1-10 GPa for shear
#' modulus, and 10-100 GPa for Young's modulus.
#' \emph{Note that one gigapascal (GPa) is
#' equal to 10^9 pascal (Pa).}
#' 
#' @name mogi
#' @aliases Mogi
#' 
#' @param surface.distance numeric; [m] the radial distance (positive away) from the center of the spherical cavity, projected onto the surface
#' @param sphere.depth numeric; [m] depth of the center of the spherical cavity from the surface (positive downward)
#' @param Volume.change numeric; [m^3] volumetric change of the spherical cavity (inflation positive)
#' @param sphere.radius numeric; [m] radius of the spherical cavity that's inflating or deflating
#' @param Pressure.change numeric; [Pa] hydrostatic pressure change in the spherical cavity (inflation positive)
#' @param shear.modulus numeric; [Pa] elastic shear modulus of the surrounding material, also known as 'rigidity' or Lame''s constant 
#' @param Youngs.modulus numeric; [Pa] Young's modulus of elasticity of the surrounding material
#' @param nu numeric; [0-1] Poisson's ratio of the surrounding material
#' @param verbose logical; should messages be given?
#' @param ... additional parameters to \code{.mogi_calc}
#' @param src numeric; the source strength
#' 
#' @references [1] \url{http://www.ipgp.fr/~beaudu/matlab.html#Mogi}
#' @references Mogi, K. (1958), Relations between the eruptions of various volcanoes and the
#'  	deformations of the ground surfaces around them, \emph{Bull. Earthquake Res.
#'		Inst. Univ. Tokyo}, 36, 99-134. (\url{http://hdl.handle.net/2261/11909})
#'  	
#' @author Original Matlab code 'mogi.m' written by Francois Beauducel; AJ Barbour ported to R code.
#' 
#' @seealso \code{\link{Uniaxial_extension}} and \code{\link{Tilt}} 
#' @examples
#' library(RColorBrewer)
#' seq.palfun <- function(n) brewer.pal(n, 'Reds')
#' div.palfun <- function(n) brewer.pal(n, 'Spectral')
#' # http://www.ipgp.fr/~beaudu/images/mogi_example.png
#' 
#' x <- y <- unique(sort(c(seq(-2,2,by=0.1), seq(-0.1,0.1,by=0.01))))
#' theta_r <- cart2pol(expand.grid(x, y))
#' r <- theta_r[,'Radius']
#' 
#' # calculate the deformation specifying a positive rate of volume-change (inflation)
#' MV <- mogi.volume(r, 1, 1e-5, verbose=TRUE)
#' 
#' filled.contour(x, y, matrix((MV[,'Ur']), length(x)), asp=1, main='Ur', 
#'     nlevels = 11, color.palette=div.palfun)
#' filled.contour(x, y, matrix((MV[,'Uz']), length(x)), asp=1, main='Uz', 
#'     color.palette=div.palfun, levels=seq(0,2.5e-6, length.out = 11))
#' 
#' filled.contour(x, y, matrix((MV[,'Ett']), length(x)), levels=seq(0,2.5e-6,length.out=9), 
#'     asp=1, main='Ett', color.palette=seq.palfun)
#' filled.contour(x, y, matrix((MV[,'Err']), length(x)), zlim=3e-6*c(-1,1), 
#'     asp=1, main='Err', nlevels = 11)
#' 
#' # There should be a null in the center of the tilt field
#' filled.contour(x, y, matrix((MV[,'Tilt']), length(x)), 
#'     asp=1, main='Tilt', levels=seq(0,2.5e-6,length.out=9), color.palette=seq.palfun)
#' 
#' # Calculate the undrained-to-drained effect:
#' #  first calculate for nu=1/3
#' MVud <- mogi.volume(r, 1, 1e-5, nu=1/3, verbose=TRUE)
#' #  then subtract the 1/4 result
#' Resp.ud <- matrix((MV[,'Uz']), length(x)) - matrix((MVud[,'Uz']), length(x))
#' filled.contour(x, y, log10(Resp.ud), 
#'     asp=1, main='Undrained response: Uz', color.palette=seq.palfun, 
#'     levels=seq(-8,-6.5,length.out=9))
#' #
#' 
#' #Using values comparable to the previous example, but specifying pressure changes
#' MP <- mogi.pressure(r, 1, 0.01, 1e10, shear.modulus=3.08e9)
#' MP2 <- mogi.pressure(r, 1, 0.01, 1e10, Youngs.modulus=10e9)
#' 
NULL

#' @rdname mogi
#' @export
mogi.volume <- function(surface.distance, sphere.depth, Volume.change, ...){
  .mogi_check(surface.distance, sphere.depth)
  Source <- Volume.change / pi
  .mogi_calc(Source, surface.distance, sphere.depth, ...)
}

#' @rdname mogi
#' @export
mogi.pressure <- function(surface.distance, sphere.depth, sphere.radius, Pressure.change, shear.modulus, Youngs.modulus, nu=1/4, ...){
  .mogi_check(surface.distance, sphere.depth, sphere.radius)
  if (missing(shear.modulus)){
    if (missing(Youngs.modulus)) stop('Youngs.modulus cannot be missing if shear.modulus is missing')
    shear.modulus <- Youngs.modulus / (2 * (1 + nu))
  }
  Source <- sphere.radius ^ 3 * Pressure.change / shear.modulus
  .mogi_calc(Source, surface.distance, sphere.depth, ...)
}

#' @rdname mogi
.mogi_check <- function(surface.distance, sphere.depth, sphere.radius=NULL){
  stopifnot(all(surface.distance >= 0))
  stopifnot(all(sphere.depth >= 0))
  if (!is.null(sphere.radius)){
    stopifnot(all(sphere.radius >= 0))
    if (max(sphere.radius) / min(sphere.depth) > 1/10) warning('inaccurate results if  sphere.depth  is not much greater than  sphere.radius')
  }
}

#' @rdname mogi
.mogi_calc <- function(src, surface.distance, sphere.depth, nu=1/4, verbose=FALSE){
  
  stopifnot(all(nu>=0 & nu <=1))
  
  # radial distance from source
  radial.distance <- sqrt(sphere.depth^2 + surface.distance^2)
  if (verbose) message("Poissons ratio:  ", paste(nu))
  C. <- (1 - nu) * src
  if (verbose) message("constant(s):  ", paste(signif(C.)))
  
  # tangential horizontal (hoop) strain, radial horizontal displacement, and vertical displacement
  Ett <- C. / radial.distance^3 
  Ur <- surface.distance * Ett
  Uz <- sphere.depth * Ett
  
  # tilt, and radial horizontal strain
  gradUz <- 3 * C. * sphere.depth * surface.distance / radial.distance^5
  Err <- C. * (sphere.depth^2 - 2 * surface.distance^2) / radial.distance^5
  
  data.frame(radial.distance, Ur, Uz, Ett, Err, Tilt=gradUz)
  
}
