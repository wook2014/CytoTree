#'
#' Calculate k-nearest neighbors of CYT
#'
#' @name runKNN
#'
#' @description Calculates and stores a k-nearest neighbor graph based on Euclidean
#'    distance with (KMKNN) algorithm using log-transformed signaling matrix of
#'    flow cytometry data. The base function are base on \code{\link[BiocNeighbors]{findKNN}}.
#'
#' @param object an CYT object
#' @param given.mat matrix. Given matrix to run knn
#' @param knn numeric. Number of k-nearest neighbors.
#' @param knn.replace logic. Whether to replace knn in CYT object
#' @param verbose logical. Whether to print calculation progress.
#' @param ... Parameters passing to \code{\link[BiocNeighbors]{findKNN}} function
#'
#' @seealso \code{\link[BiocNeighbors]{findKNN}}
#'
#' @return A CYT object with knn, knn.index and knn.distance information.
#'
#' @import BiocNeighbors
#'
#' @export
#'
#'
#'
runKNN <- function(object,
                   given.mat = NULL,
                   knn = 30,
                   knn.replace = TRUE, 
                   verbose = FALSE, ...) {

  if (isTRUE(object@knn > 0) & !(knn.replace)) {
    if (verbose) message(Sys.time(), " Using knn in CYT object: ", object@knn )
  } else if ( isTRUE(object@knn > 0) & (knn.replace) ) {
    if (verbose) message(Sys.time(), " Using knn provided in this function: ", knn )
    object@knn <- knn
  } else {
    object@knn <- knn
  }

  if (length(which(object@meta.data$dowsample == 1)) < 10) {
    stop(Sys.time, " Not enough cells, please run processingCluster and choose correct downsampleing.size paramter. ")
  }

  if (is.null(given.mat)) {
    mat <- object@log.data[which(object@meta.data$seed.pseudotime == 1), object@markers.idx]
  } else {
    if (nrow(given.mat) != nrow(object@log.data[which(object@meta.data$seed.pseudotime == 1), object@markers.idx])) {
      stop(Sys.time, " Invalid given.mat ")
    } else {
      mat <- given.mat
    }
  }

  if (verbose) message(paste0(Sys.time(), " Calculating KNN " ) )
  fout <- suppressWarnings(findKNN(mat, k = object@knn, ...))

  rownames(fout$index) <- rownames(mat)
  rownames(fout$distance) <- rownames(mat)

  object@knn = knn
  object@knn.index = fout$index
  object@knn.distance = fout$distance

  if (verbose) message(Sys.time(), " Calculating KNN completed. ")
  return(object)
}

