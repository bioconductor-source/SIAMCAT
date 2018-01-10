image: r-base
before_script:
  - cd Rscript_flavor
  - Rscript 00_setup.r
  - cd ../
  - R CMD build ./
  - mv SIAMCAT*.tar.gz Rscript_flavor/.
  - cd Rscript_flavor
  - wget http://congo.embl.de/downloads/siamcat_test_data.tar.gz
  - tar -zxf siamcat_test_data.tar.gz && rm siamcat_test_data.tar.gz

test:
  stage: test
  script:
    - Rscript 00_setup.r
    - Rscript 01_validate_data.r --srcdir .. --metadata_in num_metadata_cancer-vs-healthy_study-pop-I_N141_tax_profile_mocat_bn_genus.tsv --metadata_out valMetaData.tsv --label_in label_cancer-vs-healthy_study-pop-I_N141_tax_profile_mocat_bn_genus.tsv --label_out valLabel.tsv --feat_in feat_cancer-vs-healthy_study-pop-I_N141_tax_profile_mocat_bn_genus.tsv --feat_out valFeat.tsv
    - Rscript 02_select_samples.r --srcdir .. --metadata_in valMetaData.tsv --metadata_out valMetaData_sel.tsv --label_in valLabel.tsv --label_out valLabel_sel.tsv --feat_in valFeat.tsv --feat_out valFeat_sel.tsv --filter_var="age" --allowed_range="[0,120]"
    - Rscript 03_check_for_confounders.r --srcdir .. --metadata_in valMetaData_sel.tsv --plot metaCheck.pdf --label_in valLabel_sel.tsv
    - Rscript 04_filter_features.r --feat_in valFeat_sel.tsv --feat_out valFeat_sel_filtered.tsv --method="abundance" --cutoff="0.001" --recomp_prop="FALSE" --rm_unmapped="TRUE"
    - Rscript 05_check_associations.r --srcdir .. --feat_in valFeat_sel_filtered.tsv --label_in valLabel_sel.tsv --plot assoc.pdf --col_scheme="RdYlBu" --alpha="0.7" --min_fc="0" --mult_test="fdr" --max_show="50" --detect_limit="1e-06" --plot_type="bean"
    - Rscript 06_normalize_features.r --feat_in valFeat_sel_filtered.tsv --feat_out valFeat_sel_norm.tsv --param_out param_out.tsv --method="log.unit" --log_n0="1e-08" --sd_min_quantile="0.2" --vector_norm="2" --norm_margin="1"
    - Rscript 07_add_metadata_as_predictor.r --feat_in valFeat_sel_norm.tsv --feat_out valFeat_sel_norm.tsv --metadata_in valMetaData_sel.tsv --pred_names="fobt" --std_meta="TRUE"
    - Rscript 08_split_data.r --srcdir .. --label_in valLabel_sel.tsv --train_sets trainSets.tsv --test_sets testSets.tsv --num_folds="10" --resample="5" --stratify="TRUE" --inseparable="NULL" --metadata_in valMetaData_sel.tsv
    - Rscript 09_train_models.r --srcdir .. --feat_in valFeat_sel_norm.tsv --label_in valLabel_sel.tsv --method="lasso" --train_sets trainSets.tsv --mlr_models_list models.RData --stratify="TRUE" --sel_criterion="auprc" --min_nonzero_coeff="2"
    - Rscript 10_make_predictions.r --srcdir .. --label_in valLabel_sel.tsv --feat_in valFeat_sel_norm.tsv --test_sets testSets.tsv --pred pred.tsv --mlr_models_list models.RData
    - Rscript 11_evaluate_predictions.r --srcdir .. --label_in valLabel_sel.tsv --plot evalPlot.pdf --pred pred.tsv
    - Rscript 12_interpret_model.r --srcdir .. --label_in valLabel_sel.tsv --feat valFeat_sel_norm.tsv --origin_feat valFeat_sel.tsv --meta valMetaData_sel.tsv --model models.RData --plot interpretation.pdf --pred pred.tsv --col_scheme="BrBG" --heatmap_type="zscore" --consens_thres="0.5"
  only:
    - master
    - development
after_script:
  - rm -r *.tsv
  - echo "cleaned up"