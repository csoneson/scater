% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/runDiffusionMap.R
\docType{methods}
\name{calculateDiffusionMap}
\alias{calculateDiffusionMap}
\alias{runDiffusionMap}
\alias{calculateDiffusionMap,ANY-method}
\alias{calculateDiffusionMap,SummarizedExperiment-method}
\alias{calculateDiffusionMap,SingleCellExperiment-method}
\title{Create a diffusion map from cell-level data}
\usage{
calculateDiffusionMap(x, ...)

\S4method{calculateDiffusionMap}{ANY}(x, ncomponents = 2, ntop = 500,
  subset_row = NULL, feature_set = NULL, scale = FALSE,
  scale_features = NULL, transposed = FALSE, ...)

\S4method{calculateDiffusionMap}{SummarizedExperiment}(x, ...,
  exprs_values = "logcounts")

\S4method{calculateDiffusionMap}{SingleCellExperiment}(x, ...,
  exprs_values = "logcounts", dimred = NULL, use_dimred = NULL,
  n_dimred = NULL)

runDiffusionMap(x, ..., altexp = NULL, name = "DiffusionMap")
}
\arguments{
\item{x}{For \code{calculateDiffusionMap}, a numeric matrix of log-expression values where rows are features and columns are cells.
Alternatively, a \linkS4class{SummarizedExperiment} or \linkS4class{SingleCellExperiment} containing such a matrix.

For \code{runDiffusionMap}, a \linkS4class{SingleCellExperiment} object.}

\item{...}{For the \code{calculateDiffusionMap} generic, additional arguments to pass to specific methods.
For the ANY method, additional arguments to pass to \code{\link[destiny]{DiffusionMap}}.
For the SummarizedExperiment and SingleCellExperiment methods, additional arguments to pass to the ANY method.

For \code{runDiffusionMap}, additional arguments to pass to \code{calculateDiffusionMap}.}

\item{ncomponents}{Numeric scalar indicating the number of UMAP dimensions to obtain.}

\item{ntop}{Numeric scalar specifying the number of features with the highest variances to use for PCA, see \code{?"\link{scater-red-dim-args}"}.}

\item{subset_row}{Vector specifying the subset of features to use for PCA, see \code{?"\link{scater-red-dim-args}"}.}

\item{feature_set}{Deprecated, same as \code{subset_row}.}

\item{scale}{Logical scalar, should the expression values be standardised? See \code{?"\link{scater-red-dim-args}"} for details.}

\item{scale_features}{Deprecated, same as \code{scale} but with a different default.}

\item{transposed}{Logical scalar, is \code{x} transposed with cells in rows? See \code{?"\link{scater-red-dim-args}"} for details.}

\item{exprs_values}{Integer scalar or string indicating which assay of \code{x} contains the expression values, see \code{?"\link{scater-red-dim-args}"}.}

\item{dimred}{String or integer scalar specifying the existing dimensionality reduction results to use, see \code{?"\link{scater-red-dim-args}"}.}

\item{use_dimred}{Deprecated, same as \code{dimred}.}

\item{n_dimred}{Integer scalar or vector specifying the dimensions to use if \code{dimred} is specified, see \code{?"\link{scater-red-dim-args}"}.}

\item{altexp}{String or integer scalar specifying an alternative experiment to use to compute the PCA, see \code{?"\link{scater-red-dim-args}"}.}

\item{name}{String specifying the name to be used to store the result in the \code{reducedDims} of the output.}
}
\value{
For \code{calculateDiffusionMap}, a matrix is returned containing the diffusion map coordinates for each cell (row) and dimension (column).

For \code{runDiffusionMap}, a modified \code{x} is returned that contains the diffusion map coordinates in \code{\link{reducedDim}(x, name)}.
}
\description{
Produce a diffusion map for the cells, based on the data in a SingleCellExperiment object.
}
\details{
The function \code{\link[destiny]{DiffusionMap}} is used internally to compute the diffusion map.
The behaviour of \code{\link[destiny]{DiffusionMap}} seems to be non-deterministic, in a manner that is not responsive to any \code{\link{set.seed}} call.
The reason for this is unknown.
}
\examples{
example_sce <- mockSCE()
example_sce <- logNormCounts(example_sce)

example_sce <- runDiffusionMap(example_sce, scale_features=NULL)
reducedDimNames(example_sce)
head(reducedDim(example_sce))
}
\references{
Haghverdi L, Buettner F, Theis FJ (2015).
Diffusion maps for high-dimensional single-cell analysis of differentiation data. 
\emph{Bioinformatics} 31(18), 2989-2998.
}
\seealso{
\code{\link[destiny]{DiffusionMap}}, to perform the underlying calculations.

\code{\link[scater]{plotDiffusionMap}}, to quickly visualize the results.

\code{?"\link{scater-red-dim-args}"}, for a full description of various options.
}
\author{
Aaron Lun, based on code by Davis McCarthy
}
