 ###
# SIAMCAT -  Statistical Inference of Associations between Microbial Communities And host phenoTypes
# RScript flavor
#
# written by Georg Zeller
# with additions by Nicolai Karcher and Konrad Zych
# EMBL Heidelberg 2012-2017
#
# version 0.2.0
# file last updated: 26.06.2017
# GNU GPL 3.0
###

#' @title Add metadata as predictors
#' @description This function adds metadata to the feature matrix to be later used as predictors
#' @param siamcat object of class \link{siamcat-class}
#' @param pred.names vector of names of the metavariables to be added to the feature matrix as predictors
#' @param std.meta boolean, should added metadata features be standardized?
#' @keywords SIAMCAT add.meta.pred
#' @export
#' @return features object with added metadata
add.meta.pred <- function(siamcat, pred.names=NULL, std.meta){
  ### add metadata as predictors to the feature matrix
  cnt <- 0

  if (pred.names != '' && !is.null(pred.names)) {

    for (p in pred.names) {
      if(!p%in%colnames(siamcat@phyloseq@sam_data)) stop("There is no metadata variable called ",p,"\n")
      idx <- which(colnames(siamcat@phyloseq@sam_data) == p)
      if(length(idx) != 1) stop(p, "matches multiple columns in the metada\n")

      cat('adding ', p, '\n', sep='')
      m   <-  unlist(siamcat@phyloseq@sam_data[,idx])

      if (!all(is.finite(m))) {
        na.cnt <- sum(!is.finite(m))
        cat('filling in', na.cnt, 'missing values by mean imputation\n')
        mn     <- mean(m, na.rm=TRUE)
        m[!is.finite(m)] <- mn
      }

      if (std.meta) {
        cat('standardize metadata feature', p, '\n')
        m.mean <- mean(m, na.rm = TRUE)
        m.sd   <- sd(m, na.rm = TRUE)
        stopifnot(!m.sd == 0)
        m      <- (m - m.mean)/m.sd
      }

      siamcat@phyloseq@otu_table                       <- otu_table(rbind(siamcat@phyloseq@otu_table, m),taxa_are_rows=T)
      rownames(siamcat@phyloseq@otu_table)[nrow(siamcat@phyloseq@otu_table)] <- paste('META_', toupper(p), sep='')
      cnt                        <- cnt + 1
    }
      cat('added', cnt, 'meta-variables as predictors to the feature matrix\n')
  } else {
      cat('Not adding any of the meta-variables as predictor to the feature matrix\n')
  }
  stopifnot(all(!is.na(siamcat@phyloseq@otu_table)))

  return(siamcat)
}
