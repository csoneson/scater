# tests for feature pre-processing functions.
# library(scater); library(testthat); source("setup-sce.R"); source("test-feat-proc.R")

context("test feature pre-processing functions")

##########################################################

set.seed(10001)
test_that("we can summarise counts at feature set level", {
    ids <- sample(nrow(sce)/2, nrow(sce), replace=TRUE)
    out <- sumCountsAcrossFeatures(sce, ids)
    expect_identical(out, rowsum(counts(sce), ids))
    expect_identical(rownames(out), as.character(sort(unique(ids))))

    out2 <- sumCountsAcrossFeatures(counts(sce), ids)
    expect_identical(out, out2)

    # Handles averaging correctly.
    out2 <- sumCountsAcrossFeatures(sce, ids, average=TRUE)
    expect_identical(out2, rowsum(counts(sce), ids)/as.integer(table(ids)))

    # exprs_values= works correctly.
    alt <- sce
    assayNames(alt) <- "whee"
    out2 <- sumCountsAcrossFeatures(alt, ids, exprs_values="whee")
    expect_identical(out, out2)

    # Respects levels properly.
    fids <- factor(ids, levels=rev(sort(unique(ids))))
    fout <- sumCountsAcrossFeatures(sce, fids)
    expect_identical(out, fout[nrow(fout):1,])

    # Handles NA's correctly.
    ids2 <- sample(LETTERS, nrow(sce), replace=TRUE)
    out2 <- sumCountsAcrossFeatures(sce, ids2)

    ids3 <- ids2
    ids3[ids3=="A"] <- NA
    out3 <- sumCountsAcrossFeatures(sce, ids3)
    expect_identical(out2[setdiff(rownames(out2), "A"),], out3)
})

set.seed(10002)
test_that("by-feature count summarization behaves with odd inputs", {
    ids <- sample(nrow(sce)/2, nrow(sce), replace=TRUE)
    ref <- sumCountsAcrossFeatures(sce, ids)

    # Handles sparse matrices properly.
    library(Matrix)
    sparsified <- sce
    counts(sparsified) <- as(counts(sparsified), "dgCMatrix")
    spack <- sumCountsAcrossFeatures(sparsified, ids)
    expect_s4_class(spack, "dgCMatrix")
    expect_equal(ref, as.matrix(spack))

    unknown <- sce
    counts(unknown) <- as(counts(unknown), "dgTMatrix")
    spack <- sumCountsAcrossFeatures(unknown, ids)
    expect_true(is.matrix(spack))
    expect_equivalent(ref, as.matrix(spack))

    # Handles parallelization properly.
    alt <- sumCountsAcrossFeatures(sce, ids, BPPARAM=safeBPParam(2))
    expect_identical(alt, ref)

    alt <- sumCountsAcrossFeatures(sce, ids, BPPARAM=safeBPParam(3))
    expect_identical(alt, ref)
})

set.seed(100021)
test_that("Aggregation across features works correctly", {
    ids <- paste0("GENE_", sample(nrow(sce)/2, nrow(sce), replace=TRUE))
    alt <- aggregateAcrossFeatures(sce, ids)

    expect_identical(rownames(alt), sort(unique(ids)))
    expect_identical(counts(alt), sumCountsAcrossFeatures(counts(sce), ids))

    # Behaves in the presence of multiple assays.
    normcounts(sce) <- normalizeCounts(sce, log=FALSE)
    alt2 <- aggregateAcrossFeatures(sce, ids)
    expect_identical(alt, alt2)

    alt3 <- aggregateAcrossFeatures(sce, ids, use_exprs_values=c("counts", "normcounts"))
    expect_identical(counts(alt), counts(alt3))
    expect_identical(normcounts(alt3), sumCountsAcrossFeatures(sce, ids, exprs_values="normcounts"))
})

##########################################################

set.seed(10003)
test_that("we can summarise counts at cell cluster level", {
    ids <- sample(ncol(sce)/2, ncol(sce), replace=TRUE)
    out <- sumCountsAcrossCells(sce, ids)
    expect_identical(out, colsum(counts(sce), ids))

    out2 <- sumCountsAcrossCells(counts(sce), ids)
    expect_identical(out, out2)

    # Handles averaging correctly.
    out2 <- sumCountsAcrossCells(sce, ids, average=TRUE)
    expect_identical(out2, t(t(colsum(counts(sce), ids))/as.integer(table(ids))))

    # exprs_values= works correctly.
    alt <- sce
    assayNames(alt) <- "whee"
    out2 <- sumCountsAcrossCells(alt, ids, exprs_values="whee")
    expect_identical(out, out2)

    # Respects levels properly.
    fids <- factor(ids, levels=rev(sort(unique(ids))))
    fout <- sumCountsAcrossCells(sce, fids)
    expect_identical(out, fout[,ncol(fout):1])

    # Handles NA's correctly.
    ids2 <- sample(LETTERS, ncol(sce), replace=TRUE)
    out2 <- sumCountsAcrossCells(sce, ids2)

    ids3 <- ids2
    ids3[ids3=="A"] <- NA
    out3 <- sumCountsAcrossCells(sce, ids3)

    expect_identical(out2[,setdiff(colnames(out2), "A")], out3)
})

set.seed(10004)
test_that("by-cell count summarization behaves with odd inputs", {
    ids <- sample(ncol(sce)/2, ncol(sce), replace=TRUE)
    ref <- sumCountsAcrossCells(sce, ids)

    # Handles sparse matrices properly.
    library(Matrix)
    sparsified <- sce
    counts(sparsified) <- as(counts(sparsified), "dgCMatrix")
    spack <- sumCountsAcrossCells(sparsified, ids)
    expect_s4_class(spack, "dgCMatrix")
    expect_equal(ref, as.matrix(spack))

    unknown <- sce
    counts(unknown) <- as(counts(unknown), "dgTMatrix")
    spack <- sumCountsAcrossCells(unknown, ids)
    expect_true(is.matrix(spack))
    expect_equivalent(ref, as.matrix(spack))

    # Handles parallelization properly.
    alt <- sumCountsAcrossCells(sce, ids, BPPARAM=safeBPParam(2))
    expect_identical(alt, ref)

    alt <- sumCountsAcrossCells(sce, ids, BPPARAM=safeBPParam(3))
    expect_identical(alt, ref)
})

set.seed(1000401)
test_that("Aggregation across cells works correctly with DFs", {
    # One factor.
    ids <- sample(ncol(sce)/2, ncol(sce), replace=TRUE)
    ref <- sumCountsAcrossCells(sce, ids)
    out <- sumCountsAcrossCells(sce, DataFrame(X=ids))

    expect_identical(sort(colnames(ref)), sort(as.character(out$X)))
    m <- match(colnames(ref), as.character(out$X))
    expect_equivalent(ref, assay(out)[,m])

    # Two factors.
    extra <- sample(LETTERS[1:3], ncol(sce), replace=TRUE)
    combined <- paste0(ids, "-", extra)
    ref <- sumCountsAcrossCells(sce, combined)
    out <- sumCountsAcrossCells(sce, DataFrame(X=ids, Y=extra))

    post.combined <- paste0(out$X, "-", out$Y)
    expect_identical(sort(colnames(ref)), sort(post.combined))
    m <- match(colnames(ref), post.combined)
    expect_equivalent(ref, assay(out)[,m])

#    # Handles NAs correctly.
#    extra[1] <- NA
#    ids[2] <- NA
#    ref <- sumCountsAcrossCells(sce, DataFrame(X=ids, Y=extra))
#    out <- sumCountsAcrossCells(sce[,-(1:2)], DataFrame(X=ids, Y=extra)[-(1:2),])
#    expect_equal(ref, out)
})

set.seed(100041)
test_that("Aggregation across cells works correctly for SCEs", {
    ids <- paste0("CLUSTER_", sample(ncol(sce)/2, ncol(sce), replace=TRUE))
    alt <- aggregateAcrossCells(sce, ids)

    expect_identical(colnames(alt), sort(unique(ids)))
    expect_identical(counts(alt), sumCountsAcrossCells(counts(sce), ids))

    # Behaves in the presence of multiple assays.
    normcounts(sce) <- normalizeCounts(sce, log=FALSE)
    alt2 <- aggregateAcrossCells(sce, ids)
    expect_identical(alt, alt2)

    sce <- logNormCounts(sce, log=FALSE)
    alt3 <- aggregateAcrossCells(sce, ids, use_exprs_values=c("counts", "normcounts"))
    expect_identical(counts(alt), counts(alt3))
    expect_identical(normcounts(alt3), sumCountsAcrossCells(sce, ids, exprs_values="normcounts"))

    # Behaves for alternative experiments.
    copy <- sce
    altExp(copy, "THING") <- sce
    copy <- aggregateAcrossCells(copy, ids)
    expect_identical(counts(altExp(copy, "THING")), counts(alt))

    copy <- aggregateAcrossCells(sce, ids, use_altexps=FALSE)
    expect_identical(altExpNames(copy), character(0))
})

set.seed(1000411)
test_that("Aggregation across cells works correctly for SCEs with DFs", {
    ids <- paste0("CLUSTER_", sample(ncol(sce)/2, ncol(sce), replace=TRUE))
    extra <- sample(LETTERS[1:3], ncol(sce), replace=TRUE)

    combined <- DataFrame(X=ids, Y=extra)
    agg <- aggregateAcrossCells(sce, combined)
    ref <- sumCountsAcrossCells(counts(sce), combined)

    expect_identical(counts(agg), assay(ref))
    expect_identical(agg$X, ref$X)
    expect_identical(agg$Y, ref$Y)

    # Same for alternative experiments.
    copy <- sce
    altExp(copy, "THING") <- sce
    copy <- aggregateAcrossCells(copy, combined)
    expect_identical(counts(altExp(copy, "THING")), assay(ref))
    expect_identical(ref$X, altExp(copy)$X)
    expect_identical(ref$Y, altExp(copy)$Y)
})

set.seed(100042)
test_that("Aggregation across cells works correctly for SEs", {
    ids <- paste0("CLUSTER_", sample(ncol(sce)/2, ncol(sce), replace=TRUE))
    alt <- aggregateAcrossCells(sce, ids)
    expect_identical(colnames(alt), sort(unique(ids)))
    expect_identical(counts(alt), sumCountsAcrossCells(counts(sce), ids))
})

##########################################################

test_that("we can uniquify the feature names", {
    all.genes <- sample(c(LETTERS, LETTERS[1:5], NA, NA))
    all.ids <- paste0("GENE", seq_along(all.genes))
    out <- uniquifyFeatureNames(all.ids, all.genes)
    out.factor.names <- uniquifyFeatureNames(all.ids, factor(all.genes))
    out.factor.id <- uniquifyFeatureNames(factor(all.ids), all.genes)
    
    lost <- is.na(all.genes)
    expect_identical(out[lost], all.ids[lost])
    dup <- all.genes %in% all.genes[duplicated(all.genes)]
    expect_identical(out[!dup & !lost], all.genes[!dup & !lost])
    expect_identical(out[dup & !lost], paste0(all.genes, "_", all.ids)[dup & !lost])
    
    expect_identical(out, out.factor.names)
    expect_identical(out, out.factor.id)
})

