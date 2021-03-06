#'
#' Visualization of 2D data of CYT
#'
#' @name plot2D
#'
#' @param object A CYT object
#' @param item.use character. Items use to 2D plot, axes x and y must be numeric.
#' @param color.by character. Dot or mesh color by which character. It can be one of the column
#'     of plot.meta, or it can be just "density" (the default value).
#' @param order.by vector. Order of color theme.
#' @param size numeric. Size of the dot
#' @param alpha numberic. Transparency (0-1) of the dot, default is 1.
#' @param category character. numeric or categorical
#' @param show.cluser.id logical. Whether to show cluster id in the plot.
#' @param show.cluser.id.size numeric. Size of the cluster id.
#' @param main character. Title of the plot.
#' @param plot.theme themes from \code{ggplot2}
#'
#' @import ggplot2
#' @importFrom stats aggregate
#'
#' @export
#' @return ggplot2 figure
#'
#' @examples
#'
#' cyt.file <- system.file("extdata/cyt.rds", package = "CytoTree")
#' cyt <- readRDS(file = cyt.file)
#'
#' # Default plot
#' plot2D(cyt)
#'
#' # PCA plot
#' plot2D(cyt, item.use = c("PC_1", "PC_2"))
#' plot2D(cyt, item.use = c("PC_1", "PC_2"), color.by = "cluster.id")
#' plot2D(cyt, item.use = c("PC_1", "PC_2"), color.by = "stage")
#' plot2D(cyt, item.use = c("PC_2", "PC_3"), color.by = "stage") 
#' plot2D(cyt, item.use = c("PC_2", "PC_3"), color.by = "CD43",
#'        category = "numeric")
#' plot2D(cyt, item.use = c("PC_2", "PC_3"), color.by = "CD43",
#'        category = "numeric")
#'
#' # tSNE plot
#' plot2D(cyt, item.use = c("tSNE_1", "tSNE_2"))
#' plot2D(cyt, item.use = c("tSNE_1", "tSNE_2"), color.by = "stage")
#' plot2D(cyt, item.use = c("tSNE_1", "tSNE_2"), color.by = "cluster.id",
#'        alpha = 0.5, main = "tSNE Plot")
#' plot2D(cyt, item.use = c("tSNE_1", "tSNE_2"), color.by = "cluster.id",
#'        alpha = 1, main = "tSNE Plot", show.cluser.id = TRUE)
#' plot2D(cyt, item.use = c("tSNE_1", "tSNE_2"), color.by = "CD43",
#'        category = "numeric", size = 3)
#' plot2D(cyt, item.use = c("tSNE_1", "tSNE_2"), color.by = "stage")
#'
#' # Diffusion Map plot
#' plot2D(cyt, item.use = c("DC_1", "DC_2"))
#' plot2D(cyt, item.use = c("DC_1", "DC_2"), color.by = "stage")
#' plot2D(cyt, item.use = c("DC_2", "DC_3"), color.by = "cluster.id",
#'        alpha = 0.5, main = "Diffusion Map Plot")
#' plot2D(cyt, item.use = c("DC_2", "DC_3"), color.by = "cluster.id",
#'        alpha = 1, main = "Diffusion Map Plot", show.cluser.id = TRUE)
#' plot2D(cyt, item.use = c("DC_1", "DC_2"), color.by = "CD43",
#'        category = "numeric", size = 3)
#'
#' # UMAP plot
#' plot2D(cyt, item.use = c("UMAP_1", "UMAP_2"))
#' plot2D(cyt, item.use = c("UMAP_1", "UMAP_2"), color.by = "stage")
#' plot2D(cyt, item.use = c("UMAP_1", "UMAP_2"), color.by = "cluster.id",
#'        alpha = 0.5, main = "UMAP Plot")
#' plot2D(cyt, item.use = c("UMAP_1", "UMAP_2"), color.by = "cluster.id",
#'        alpha = 1, main = "UMAP Plot", show.cluser.id = TRUE)
#' plot2D(cyt, item.use = c("UMAP_1", "UMAP_2"), color.by = "CD43",
#'        category = "numeric", size = 3)
#' plot2D(cyt, item.use = c("UMAP_1", "UMAP_2"), color.by = "stage")
#'
#' # Marker Plot
#' plot2D(cyt, item.use = c("CD43", "CD90"), color.by = "cluster.id")
#' plot2D(cyt, item.use = c("CD34", "CD90"), color.by = "CD43",
#'        category = "numeric", size = 3)
#'
#' # Pseudotime
#' plot2D(cyt, item.use = c("pseudotime", "CD43"), color.by = "stage")
#'
#' 
#'
plot2D <- function(object,
                   item.use = c("PC_1", "PC_2"),
                   color.by = "stage",
                   order.by = NULL,
                   size = 1,
                   alpha = 1,
                   category = "categorical",
                   show.cluser.id = FALSE,
                   show.cluser.id.size = 4,
                   main = "2D plot of CYT",
                   plot.theme = theme_bw()) {

  # update and fetch plot meta information
  plot.meta <- fetchPlotMeta(object, verbose = FALSE)

  idx <- match(c(color.by, item.use), colnames(object@log.data))
  idx <- idx[which(!is.na(idx))]
  if (length(idx) > 0) {
    sub <- as.data.frame(object@log.data[which(object@meta.data$dowsample == 1), idx])
    colnames(sub) <- colnames(object@log.data)[idx]
    plot.meta <- cbind(plot.meta, sub)
  }

  # check item.use parameter in plot.meta data.frame
  if ( !all(item.use %in% colnames(plot.meta)) ) stop(Sys.time(), " item.use is not in plot.meta of CYT, please run updatePlotMeta first.")

  # check color.by parameter in plot.meta data.frame
  if ( !all(color.by %in% colnames(plot.meta)) ) stop(Sys.time(), " color.by is not in plot.meta of CYT, please run updatePlotMeta first.")

  if (length(item.use) < 2) stop(Sys.time(), " item.use is less than two elements.")
  if (length(item.use) > 2) {
    warning(Sys.time(), " item.use has more than two elements. Only the first two will be used")
    item.use <- item.use[seq_len(2)]
  }
  if (length(color.by) > 1) {
    warning(Sys.time(), " color.by has more than one elements. Only the first one will be used")
    color.by <- color.by[1]
  }

  item.use.idx <- match(item.use, colnames(plot.meta))
  color.by.idx <- match(color.by, colnames(plot.meta))

  plot.x = plot.y =NULL

  plot.data <- data.frame(plot.x = plot.meta[, item.use.idx[1]],
                          plot.y = plot.meta[, item.use.idx[2]],
                          color.by = plot.meta[, color.by.idx])

  if ((length( unique(plot.data$color.by) ) > 256) & (category != "numeric")) {
    warning(Sys.time(), " color.by is categorical and has more than 256 elements. It will be used as numeric instead.")
    category = "numeric"
  }

  if (is.null(category)) {
    if (is.numeric(plot.data$color.by)) category="numeric" else category="categorical"
  }
  if (category == "categorical") {
    if (is.null(order.by)) {
      plot.data$color.by <- factor(plot.data$color.by)
    } else {
      plot.data$color.by <- factor(as.character(plot.data$color.by), levels = order.by)
    }
  } else if (category == "numeric") {
    if (!is.numeric(plot.data$color.by)) plot.data$color.by <- as.numeric(factor(plot.data$color.by))
  } else {
    warning(Sys.time(), " Unidentified parameters of category")
  }

  # plot
  gg <- ggplot(plot.data) + geom_point(aes(x=plot.x, y=plot.y, color = color.by), size = size, alpha = alpha)
  gg <- gg + plot.theme
  gg <- gg + labs(x = item.use[1], y = item.use[2], title = paste0(main))
  gg <- gg + labs(color = color.by)

  if (show.cluser.id & (category == "categorical")) {
     pos <- aggregate(  plot.data[, seq_len(2)], list( pos = plot.data$color.by ), mean)

     for ( i in seq_along(pos$pos)) {
       gg <- gg + annotate(geom="text", x = pos$plot.x[i], y = pos$plot.y[i], 
                           label = pos$pos[i],
                           size = show.cluser.id.size)
     }
  }

  return(gg)

}

#'
#' Visualization violin plot of CYT
#'
#' @name plotViolin
#'
#' @param object A CYT object
#' @param marker character. Markers used to plot
#' @param color.by character. Dot or mesh color by which character. It can be one of the column
#'     of plot.meta, or it can be just "density" (the default value).
#' @param order.by vector. Order of color theme.
#' @param size numeric. Size of the dot
#' @param text.angle numberic. Text angle of the violin plot
#' @param main character. Title of the plot.
#' @param plot.theme themes from \code{ggplot2}
#'
#' @import ggplot2
#' @importFrom stats aggregate
#'
#' @export
#' @return ggplot2 figure
#'
#' @examples
#'
#' cyt.file <- system.file("extdata/cyt.rds", package = "CytoTree")
#' cyt <- readRDS(file = cyt.file)
#' 
#' plotViolin(cyt, marker = "CD34")
#' plotViolin(cyt, marker = "CD34", order.by = "pseudotime")
#' 
#'
plotViolin <- function(object,
                       marker,
                       color.by = "cluster.id",
                       order.by = NULL,
                       size = 1,
                       text.angle = 0,
                       main = "Violin plot CYT",
                       plot.theme = theme_bw()) {

  # update plot meta information
  plot.meta <- fetchPlotMeta(object, verbose = FALSE)

  if (missing(marker)) stop(Sys.time(), " marker is missing.")
  # check item.use parameter in plot.meta data.frame
  if (length(marker) > 1) {
    warning(Sys.time(), " marker has more than two elements. Only the first two will be used")
    marker <- marker[1]
  }
  if ( marker %in% colnames(object@log.data) ) {
    plot.meta <- data.frame(plot.meta, marker = object@log.data[which(object@meta.data$dowsample == 1), marker])
  } else {
    stop(Sys.time(), " marker name is not correct")
  }


  # check color.by parameter in plot.meta data.frame
  if ( !all(color.by %in% colnames(plot.meta)) ) stop(Sys.time(), " color.by is not in plot.meta of CYT, please run updatePlotMeta first.")

  if (length(color.by) > 1) {
    warning(Sys.time(), " color.by has more than one elements. Only the first one will be used")
    color.by <- color.by[1]
  }
  color.by.idx <- match(color.by, colnames(plot.meta))

  marker.by = NULL

  plot.data <- data.frame(marker.by = plot.meta$marker,
                          color.by = plot.meta[, color.by.idx])

  if (length( unique(plot.data$color.by) ) > 128) {
    stop(Sys.time(), " color.by is categorical and has more than 128 elements.")
  }

  if (is.null(order.by)) {
    plot.data$color.by <- factor(plot.data$color.by)
  } else if (order.by == "pseudotime") {
    sub <- plot.meta[, c("pseudotime", color.by)]
    colnames(sub) <- c("pseudotime", "color.by.tag")
    sub <- aggregate(sub, list(color.by = sub$color.by.tag), mean)
    plot.data$color.by <- factor(as.character(plot.data$color.by), levels = sub$color.by.tag[order(sub$pseudotime)])
  }
  else {
    plot.data$color.by <- factor(as.character(plot.data$color.by), levels = order.by)
  }

  # plot
  gg <- ggplot(plot.data, aes(x = color.by, y= marker.by, fill = color.by)) + geom_violin(scale = "width")
  gg <- gg + plot.theme
  gg <- gg + stat_summary(fun.y=mean, geom="point", size = size, color="black")
  gg <- gg + labs(y = marker, x = color.by, title = paste0(main))
  gg <- gg + labs(fill = color.by)
  gg <- gg + theme(axis.text.x = element_text(angle = text.angle, hjust = 1, vjust = 1))

  return(gg)

}




#'
#' Visualization pie plot of cluster data of CYT
#'
#' @name plotPieCluster
#'
#' @param object A CYT object
#' @param item.use character. Items use to 2D plot, axes x and y must be numeric.
#' @param cex.size numeric. Size of the dot
#' @param size.by.cell.number logical. Whether to show size of cell number.
#' @param main character. Title of the plot.
#' @param plot.theme themes from \code{ggplot2}
#'
#' @import ggplot2
#' @return ggplot2 figure
#'
#' @export
#'
#' @examples
#'
#' cyt.file <- system.file("extdata/cyt.rds", package = "CytoTree")
#' cyt <- readRDS(file = cyt.file)
#' 
#' # Runs only have more than two stages
#' plotPieCluster(cyt, cex.size = 0.5)
#'
#' plotPieCluster(cyt, item.use = c("PC_1", "PC_2"), cex.size = 0.5)
#' plotPieCluster(cyt, item.use = c("PC_2", "PC_3"), cex.size = 0.5)
#'
#' plotPieCluster(cyt, item.use = c("tSNE_1", "tSNE_2"), cex.size = 20)
#'
#' plotPieCluster(cyt, item.use = c("DC_1", "DC_2"), cex.size = 0.5)
#'
#' plotPieCluster(cyt, item.use = c("UMAP_1", "UMAP_2"), cex.size = 1)
#' plotPieCluster(cyt, item.use = c("UMAP_1", "UMAP_2"), cex.size = 1) 
#' 
#'
plotPieCluster <- function(object,
                           item.use = c("PC_1", "PC_2"),
                           cex.size = 1,
                           size.by.cell.number = TRUE,
                           main = "2D pie plot of CYT",
                           plot.theme = theme_bw()) {

  if (missing(object)) stop(Sys.time(), " object is missing")
  if (is.null(object@network)) stop(Sys.time(), " network is missing, please run runCluster first!")
  if (length(unique(object@meta.data$stage)) <= 1) stop(Sys.time(), " plotPieCluster only fits elements in stage over 2!")

  # update plot meta information
  plot.data <- fetchClustMeta(object, verbose = FALSE)

  # check item.use parameter in cluster data.frame
  if ( !all(item.use %in% colnames(object@cluster)) ) stop(Sys.time(), " item.use is not in plot.meta of CYT, please run updatePlotMeta first.")

  if (length(item.use) < 2) stop(Sys.time(), " item.use is less than two elements.")
  if (length(item.use) > 2) {
    warning(Sys.time(), " item.use has more than two elements. Only the first two will be used")
    item.use <- item.use[seq_len(2)]
  }
  item.use.idx <- match(item.use, colnames(object@cluster))

  plot.cols <- paste0(unique(object@meta.data$stage), ".percent")

  pos.x = pos.y = cluster = cell.number.percent = NULL
  plot.data <- data.frame(plot.data,
                          pos.x = object@cluster[, item.use.idx[1]],
                          pos.y = object@cluster[, item.use.idx[2]])

  gg <- ggplot()
  if (size.by.cell.number) {
    gg <- gg + geom_scatterpie(aes(x = pos.x, y = pos.y, group = cluster, r = cell.number.percent*cex.size),
                               data = plot.data, cols = plot.cols, color=NA) + coord_equal()
  } else {
    gg <- gg + geom_scatterpie(aes(x = pos.x, y = pos.y, group = cluster, r = 0.1*cex.size),
                               data = plot.data, cols = plot.cols, color=NA) + coord_equal()
  }

  gg <- gg + plot.theme
  gg <- gg + labs(x = "", y = "", title = main)

  return(gg)

}

#'
#' Visualization of cluster data of CYT
#'
#' @name plotCluster
#'
#' @param object An CYT object
#' @param item.use character. Items use to 2D plot, axes x and y must be numeric.
#' @param color.by character. Dot or mesh color by which character. It can be one of the column
#'     of plot.meta, or it can be just "density" (the default value).
#' @param size.by character. Size of the dot
#' @param order.by vector. Order of color theme.
#' @param size numeric. Size of the dot
#' @param alpha numberic. Transparency (0-1) of the dot, default is 1.
#' @param category character. numeric or categorical
#' @param show.cluser.id logical. Whether to show cluster id in the plot.
#' @param show.cluser.id.size numeric. Size of the cluster id.
#' @param main character. Title of the plot.
#' @param plot.theme themes from \code{ggplot2}
#'
#' @import ggplot2
#' @return ggplot2 figure
#'
#' @export
#'
#' @examples
#'
#' cyt.file <- system.file("extdata/cyt.rds", package = "CytoTree")
#' cyt <- readRDS(file = cyt.file)
#' 
#' plotCluster(cyt)
#'
#' plotCluster(cyt, item.use = c("PC_1", "PC_2"))
#' plotCluster(cyt, item.use = c("PC_2", "PC_3"))
#' plotCluster(cyt, item.use = c("PC_2", "PC_3"), color.by = "CD43", category = "numeric")
#' plotCluster(cyt, item.use = c("PC_2", "PC_3"), color.by = "CD43", category = "numeric")
#'
#' plotCluster(cyt, item.use = c("tSNE_1", "tSNE_2"))
#' plotCluster(cyt, item.use = c("tSNE_1", "tSNE_2"), show.cluser.id = TRUE)
#'
#' plotCluster(cyt, item.use = c("DC_1", "DC_2"))
#'
#' plotCluster(cyt, item.use = c("UMAP_1", "UMAP_2"))
#' 
#'
plotCluster <- function(object,
                        item.use = c("PC_1", "PC_2"),
                        color.by = "cluster",
                        size.by = "cell.number.percent",
                        order.by = NULL,
                        size = 1,
                        alpha = 1,
                        category = "categorical",
                        show.cluser.id = FALSE,
                        show.cluser.id.size = 4,
                        main = "2D plot of cluster in CYT",
                        plot.theme = theme_bw()) {

  # update plot meta information
  plot.meta.data <- fetchClustMeta(object, verbose = FALSE)
  plot.meta.data <- cbind(plot.meta.data, object@cluster)

  # check item.use parameter in plot.meta data.frame
  if ( !all(item.use %in% colnames(plot.meta.data)) ) stop(Sys.time(), " item.use is not in cluster data of CYT, please run processingCluster first.")

  # check color.by parameter in plot.meta data.frame
  if ( !all(color.by %in% colnames(plot.meta.data)) ) stop(Sys.time(), " color.by is not in cluster data of CYT, please run processingCluster first.")

  # check size.by parameter in plot.meta data.frame
  if ( !all(size.by %in% colnames(plot.meta.data)) ) stop(Sys.time(), " size.by is not in cluster data of CYT, please run processingCluster first.")

  if (length(item.use) < 2) stop(Sys.time(), " item.use is less than two elements.")
  if (length(item.use) > 2) {
    warning(Sys.time(), " item.use has more than two elements. Only the first two will be used")
    item.use <- item.use[seq_len(2)]
  }
  if (length(color.by) > 1) {
    warning(Sys.time(), " color.by has more than one elements. Only the first one will be used")
    color.by <- color.by[1]
  }
  if (length(size.by) > 1) {
    warning(Sys.time(), " size.by has more than one elements. Only the first one will be used")
    size.by <- size.by[1]
  }

  item.use.idx <- match(item.use, colnames(plot.meta.data))
  color.by.idx <- match(color.by, colnames(plot.meta.data))
  size.by.idx <- match(size.by, colnames(plot.meta.data))

  plot.x = plot.y = cluster = cell.number.percent = NULL
  plot.data <- data.frame(plot.x = plot.meta.data[, item.use.idx[1]],
                          plot.y = plot.meta.data[, item.use.idx[2]],
                          color.by = plot.meta.data[, color.by.idx],
                          size.by = plot.meta.data[, size.by.idx])

  if ((length( unique(plot.data$color.by) ) > 256) & (category != "numeric")) {
    warning(Sys.time(), " color.by is categorical and has more than 256 elements. It will be used as numeric instead.")
    category = "numeric"
  }

  if (is.null(category)) {
    if (is.numeric(plot.data$color.by)) category="numeric" else category="categorical"
  }
  if (category == "categorical") {
    if (is.null(order.by)) {
      plot.data$color.by <- factor(plot.data$color.by)
    } else {
      plot.data$color.by <- factor(as.character(plot.data$color.by), levels = order.by)
    }
  } else if (category == "numeric") {
    if (!is.numeric(plot.data$color.by)) plot.data$color.by <- as.numeric(factor(plot.data$color.by))
  } else {
    warning(Sys.time(), " Unidentified parameters of category")
  }

  # plot
  gg <- ggplot(plot.data) + geom_point(aes(x=plot.x, y=plot.y, color = color.by, size = size*size.by), alpha = alpha)
  gg <- gg + plot.theme
  gg <- gg + labs(x = item.use[1], y = item.use[2], title = paste0(main))
  gg <- gg + labs(color = color.by)

  if (show.cluser.id) {
    for ( i in seq_along(rownames(plot.data))) {
      plot.x.anno = plot.data$plot.x
      plot.y.anno = plot.data$plot.y
      gg <- gg + annotate(geom="text", x = plot.x.anno[i], y = plot.y.anno[i],
                          label = rownames(plot.data)[i],
                          size = show.cluser.id.size)
    }
  }

  return(gg)

}


#'
#' Visualization heatmap of cluster data of CYT
#'
#' @name plotClusterHeatmap
#'
#' @param object A CYT object
#' @param color vector. Colors used in heatmap.
#' @param scale character. Whether the values should be centered and scaled in either
#'    the row direction or the column direction, or none. Corresponding values are
#'    "row", "column" and "none"
#' @param ... options to pass on to the \code{\link[pheatmap]{pheatmap}} function.
#'
#' @import pheatmap
#' @importFrom grDevices colorRampPalette
#'
#' @export
#' @return ggplot2 figure
#'
#' @examples
#'
#' cyt.file <- system.file("extdata/cyt.rds", package = "CytoTree")
#' cyt <- readRDS(file = cyt.file)
#'
#' plotClusterHeatmap(cyt)
#' plotClusterHeatmap(cyt, color = colorRampPalette(c("purple","white","yellow"))(100))
#' plotClusterHeatmap(cyt, cluster_row = FALSE)
#' plotClusterHeatmap(cyt, cluster_row = FALSE, cluster_col = FALSE)
#'
#' 
#'
plotClusterHeatmap <- function(object,
                               color = colorRampPalette(c("blue","white","red"))(100),
                               scale = "row", ...) {

  # update plot meta information
  plot.meta.data <- fetchClustMeta(object, verbose = FALSE)

  mat <- plot.meta.data[, object@markers]
  rownames(mat) <- plot.meta.data$cluster
  gg <- pheatmap(t(mat), color = color, scale = scale, border_color = NA, ...)

  return(gg)

}

#'
#' Visualization heatmap of branch data of CYT
#'
#' @name plotBranchHeatmap
#'
#' @param object A CYT object
#' @param color vector. Colors used in heatmap.
#' @param scale character. Whether the values should be centered and scaled in either
#'    the row direction or the column direction, or none. Corresponding values are
#'    "row", "column" and "none"
#' @param ... options to pass on to the \code{\link[pheatmap]{pheatmap}} function.
#'
#' @import pheatmap
#' @importFrom grDevices colorRampPalette
#' @importFrom stats aggregate
#'
#' @export
#' @return ggplot2 figure
#'
#' @examples
#'
#' cyt.file <- system.file("extdata/cyt.rds", package = "CytoTree")
#' cyt <- readRDS(file = cyt.file)
#'
#' plotBranchHeatmap(cyt)
#' plotBranchHeatmap(cyt, color = colorRampPalette(c("purple","white","yellow"))(100))
#' plotBranchHeatmap(cyt, cluster_row = FALSE)
#' plotBranchHeatmap(cyt, cluster_row = FALSE, cluster_col = FALSE)
#'
#' 
#'
plotBranchHeatmap <- function(object,
                              color = colorRampPalette(c("blue","white","red"))(100),
                              scale = "row", ...) {

  if (missing(object)) stop(Sys.time(), " object is missing")

  # update plot meta information
  plot.meta.data <- fetchClustMeta(object, verbose = FALSE)
  branch = NULL
  mat <- aggregate(plot.meta.data[, object@markers], list(branch = plot.meta.data[, "branch.id"]), mean)
  rownames(mat) <- mat$branch
  mat <- mat[, -1]
  gg <- pheatmap(t(mat), color = color, scale = scale, border_color = NA, ...)

  return(gg)

}

#'
#' Visualization heatmap of intermediate cells of CYT
#'
#' @name plotTrajHeatmap
#'
#' @param object A CYT object
#' @param cutoff numeric. value to identify intermediate state cells
#' @param markers markers to plot on the heatmap
#' @param color vector. Colors used in heatmap.
#' @param scale character. Whether the values should be centered and scaled in either
#'    the row direction or the column direction, or none. Corresponding values are
#'    "row", "column" and "none"
#' @param ... options to pass on to the \code{\link[pheatmap]{pheatmap}} function.
#'
#' @import pheatmap
#' @importFrom grDevices colorRampPalette
#' @importFrom stats aggregate
#'
#' @export
#' @return ggplot2 figure
#'
#'
plotTrajHeatmap <- function(object,
                            cutoff = 0,
                            markers = NULL,
                            color = colorRampPalette(c("blue","white","red"))(100),
                            scale = "row", ...) {

  if (missing(object)) stop(Sys.time(), " object is missing")
  object <- updatePlotMeta(object, verbose = FALSE)

  # update plot meta information
  plot.meta.data <- fetchClustMeta(object, verbose = FALSE)
  if (sum(plot.meta.data$traj.value.log) == 0) {
    stop(Sys.time(), " please run runWalk first")
  }
  plot.meta.data <- plot.meta.data[plot.meta.data$traj.value.log > cutoff, ]
  plot.meta.data <- plot.meta.data[order(plot.meta.data$pseudotime), ]

  if (is.null(markers)) {
    markers <- object@markers
  } else {
    markers <- markers[markers %in% object@markers]
  }
  mat <- object@log.data[match(plot.meta.data$cell, rownames(object@log.data)), object@markers.idx]
  gg <- pheatmap(t(mat), color = color, scale = scale, border_color = NA, ...)

  return(gg)

}



#'
#' Visualization heatmap of data of CYT
#'
#' @name plotHeatmap
#'
#' @param object A CYT object
#' @param color vector. Colors used in heatmap.
#' @param markers vector. markers to plot on the heatmap
#' @param scale character. Whether the values should be centered and scaled in either
#'    the row direction or the column direction, or none. Corresponding values are
#'    "row", "column" and "none"
#' @param downsize numeric. Cells size used to plot heatmap
#' @param cluster_rows logical. Whether rows should be clustered
#' @param cluster_cols logical. Whether columns should be clustered
#' @param ... options to pass on to the \code{\link[pheatmap]{pheatmap}} function.
#'
#' @import pheatmap
#' @importFrom grDevices colorRampPalette
#'
#' @export
#' @return ggplot2 figure
#'
#' @examples
#'
#' cyt.file <- system.file("extdata/cyt.rds", package = "CytoTree")
#' cyt <- readRDS(file = cyt.file)
#'
#' plotHeatmap(cyt)
#' plotHeatmap(cyt, cluster_rows = TRUE)
#' plotHeatmap(cyt, cluster_rows = TRUE, clustering_method = "ward.D")
#' plotHeatmap(cyt, cluster_rows = TRUE, cluster_cols = TRUE)
#'
#' 
#'
#'
plotHeatmap <- function(object,
                        markers = NULL,
                        color = colorRampPalette(c("blue","white","red"))(100),
                        scale = "row",
                        downsize = 1000,
                        cluster_rows = FALSE,
                        cluster_cols = FALSE,
                        ...) {
  if (missing(object)) stop(Sys.time(), " object is missing")
  object <- updatePlotMeta(object, verbose = FALSE)

  # update plot meta information
  plot.meta.data <- fetchPlotMeta(object, verbose = FALSE)

  if (downsize > dim(plot.meta.data)[1]) {
    downsize = dim(plot.meta.data)[1]
  }
  plot.meta.data <- plot.meta.data[sample(seq_len(dim(plot.meta.data)[1]), downsize), ]

  if (max(plot.meta.data$pseudotime) > 0) plot.meta.data <- plot.meta.data[order(plot.meta.data$pseudotime), ]

  mat <- object@log.data[match(plot.meta.data$cell, rownames(object@log.data)), ]
  if (is.null(markers)) {
    markers <- object@markers
  } else {
    markers <- markers[markers %in% object@markers]
  }
  mat <- mat[, markers]
  gg <- pheatmap(t(mat), color = color, scale = scale, cluster_rows = cluster_rows,
                 cluster_cols = cluster_cols, border_color = NA, fontsize_col = 0.01, ...)

  return(gg)

}



















