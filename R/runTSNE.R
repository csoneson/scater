#' Perform t-SNE on cell-level data
#'
#' Perform t-stochastic neighbour embedding (t-SNE) for the cells, based on the data in a SingleCellExperiment object.
#'
#' @param x For \code{calculateTSNE}, a numeric matrix of log-expression values where rows are features and columns are cells.
#' Alternatively, a \linkS4class{SummarizedExperiment} or \linkS4class{SingleCellExperiment} containing such a matrix.
#'
#' For \code{runTSNE}, a \linkS4class{SingleCellExperiment} object.
#' @param ncomponents Numeric scalar indicating the number of t-SNE dimensions to obtain.
#' @param ntop Numeric scalar specifying the number of features with the highest variances to use for PCA, see \code{?"\link{scater-red-dim-args}"}.
#' @param subset_row Vector specifying the subset of features to use for PCA, see \code{?"\link{scater-red-dim-args}"}.
#' @param feature_set Deprecated, same as \code{subset_row}.
#' @param exprs_values Integer scalar or string indicating which assay of \code{x} contains the expression values, see \code{?"\link{scater-red-dim-args}"}.
#' @param scale Logical scalar, should the expression values be standardised? See \code{?"\link{scater-red-dim-args}"} for details.
#' @param scale_features Deprecated, same as \code{scale} but with a different default.
#' @param transposed Logical scalar, is \code{x} transposed with cells in rows? See \code{?"\link{scater-red-dim-args}"} for details.
#' @param normalize Logical scalar indicating if input values should be scaled for numerical precision, see \code{\link[Rtsne]{normalize_input}}.
#' @param perplexity Numeric scalar defining the perplexity parameter, see \code{?\link[Rtsne]{Rtsne}} for more details.
#' @param theta Numeric scalar specifying the approximation accuracy of the Barnes-Hut algorithm, see \code{\link[Rtsne]{Rtsne}} for details.
#' @param ... For the \code{calculateTSNE} generic, additional arguments to pass to specific methods.
#' For the ANY method, additional arguments to pass to \code{\link[Rtsne]{Rtsne}}.
#' For the SummarizedExperiment and SingleCellExperiment methods, additional arguments to pass to the ANY method.
#'
#' For \code{runTSNE}, additional arguments to pass to \code{calculateTSNE}.
#' @param external_neighbors Logical scalar indicating whether a nearest neighbors search should be computed externally with \code{\link{findKNN}}.
#' @param BNPARAM A \linkS4class{BiocNeighborParam} object specifying the neighbor search algorithm to use when \code{external_neighbors=TRUE}.
#' @param BPPARAM A \linkS4class{BiocParallelParam} object specifying how the neighbor search should be parallelized when \code{external_neighbors=TRUE}.
#' @param pca Logical scalar indicating whether a PCA step should be performed inside \code{\link[Rtsne]{Rtsne}}.
#' @param altexp String or integer scalar specifying an alternative experiment to use to compute the PCA, see \code{?"\link{scater-red-dim-args}"}.
#' @param dimred String or integer scalar specifying the existing dimensionality reduction results to use, see \code{?"\link{scater-red-dim-args}"}.
#' @param use_dimred Deprecated, same as \code{dimred}.
#' @param n_dimred Integer scalar or vector specifying the dimensions to use if \code{dimred} is specified, see \code{?"\link{scater-red-dim-args}"}.
#' @param name String specifying the name to be used to store the result in the \code{reducedDims} of the output.
#'
#' @return 
#' For \code{calculateTSNE}, a numeric matrix is returned containing the t-SNE coordinates for each cell (row) and dimension (column).
#' 
#' For \code{runTSNE}, a modified \code{x} is returned that contains the t-SNE coordinates in \code{\link{reducedDim}(x, name)}.
#'
#' @details 
#' The function \code{\link[Rtsne]{Rtsne}} is used internally to compute the t-SNE. 
#' Note that the algorithm is not deterministic, so different runs of the function will produce differing results. 
#' Users are advised to test multiple random seeds, and then use \code{\link{set.seed}} to set a random seed for replicable results. 
#'
#' The value of the \code{perplexity} parameter can have a large effect on the results.
#' By default, the function will set a \dQuote{reasonable} perplexity that scales with the number of cells in \code{x}.
#' (Specifically, it is the number of cells divided by 5, capped at a maximum of 50.)
#' However, it is often worthwhile to manually try multiple values to ensure that the conclusions are robust.
#'
#' If \code{external_neighbors=TRUE}, the nearest neighbor search step will use a different algorithm to that in the \code{\link[Rtsne]{Rtsne}} function.
#' This can be parallelized or approximate to achieve greater speed for large data sets.
#' The neighbor search results are then used for t-SNE via the \code{\link[Rtsne]{Rtsne_neighbors}} function.
#' 
#' If \code{dimred} is specified, the PCA step of the \code{Rtsne} function is automatically turned off by default.
#' This presumes that the existing dimensionality reduction is sufficient such that an additional PCA is not required.
#'
#' @references
#' van der Maaten LJP, Hinton GE (2008).
#' Visualizing High-Dimensional Data Using t-SNE.
#' \emph{J. Mach. Learn. Res.} 9, 2579-2605.
#'
#' @name runTSNE
#' @seealso 
#' \code{\link[Rtsne]{Rtsne}}, for the underlying calculations.
#' 
#' \code{\link{plotTSNE}}, to quickly visualize the results.
#'
#' \code{?"\link{scater-red-dim-args}"}, for a full description of various options.
#'
#' @author Aaron Lun, based on code by Davis McCarthy
#'
#' @examples
#' example_sce <- mockSCE()
#' example_sce <- logNormCounts(example_sce)
#'
#' example_sce <- runTSNE(example_sce, scale_features=NULL)
#' reducedDimNames(example_sce)
#' head(reducedDim(example_sce))
NULL

#' @importFrom BiocNeighbors KmknnParam findKNN 
#' @importFrom BiocParallel SerialParam
.calculate_tsne <- function(x, ncomponents = 2, ntop = 500, 
    subset_row = NULL, feature_set=NULL,
    scale=FALSE, scale_features=NULL,
    transposed=FALSE,
    perplexity=NULL, normalize = TRUE, theta = 0.5, ...,
    external_neighbors=FALSE, BNPARAM = KmknnParam(), BPPARAM = SerialParam())
{ 
    if (!transposed) {
        x <- .get_mat_for_reddim(x, subset_row=subset_row, ntop=ntop, scale=scale) 
    }
    x <- as.matrix(x) 

    if (is.null(perplexity)) {
        perplexity <- min(50, floor(nrow(x) / 5))
    }

    args <- list(perplexity=perplexity, dims=ncomponents, theta=theta, ...)
    if (!external_neighbors || theta==0) {
        tsne_out <- do.call(Rtsne::Rtsne, c(list(x, check_duplicates = FALSE, normalize=normalize), args))
    } else {
        if (normalize) {
            x <- Rtsne::normalize_input(x)
        }
        nn_out <- findKNN(x, k=floor(3*perplexity), BNPARAM=BNPARAM, BPPARAM=BPPARAM)
        tsne_out <- do.call(Rtsne::Rtsne_neighbors, c(list(nn_out$index, nn_out$distance), args))
    }

    tsne_out$Y
}

#' @export
#' @rdname runTSNE
setMethod("calculateTSNE", "ANY", .calculate_tsne)

#' @export
#' @rdname runTSNE
#' @importFrom SummarizedExperiment assay
setMethod("calculateTSNE", "SummarizedExperiment", function(x, ..., exprs_values="logcounts") {
    .calculate_tsne(assay(x, exprs_values), ...)
})

#' @export
#' @rdname runTSNE
setMethod("calculateTSNE", "SingleCellExperiment", function(x, ..., pca=is.null(dimred), 
    exprs_values="logcounts", dimred=NULL, use_dimred=NULL, n_dimred=NULL)
{
    dimred <- .switch_arg_names(use_dimred, dimred)
    mat <- .get_mat_from_sce(x, exprs_values=exprs_values, dimred=dimred, n_dimred=n_dimred)
    .calculate_tsne(mat, transposed=!is.null(dimred), pca=pca, ...)
})

#' @export
#' @rdname runTSNE
#' @importFrom SingleCellExperiment reducedDim<- 
runTSNE <- function(x, ..., altexp=NULL, name="TSNE") {
    if (!is.null(altexp)) {
        y <- altExp(x, altexp)
    } else {
        y <- x
    }
    reducedDim(x, name) <- calculateTSNE(y, ...)
    x
}
