clear all;

local_parameters = load_local_parameters();

[ data_dir, calibration_train_sets, calibration_classify_set, parameters, result_dir, dataset_name ] = setupProcessing( local_parameters );

generateTrainingSetFromManualCenters( local_parameters, calibration_train_sets, calibration_classify_set, parameters );