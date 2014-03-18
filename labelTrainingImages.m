% function [] = labelTrainingImages( local_parameters, traindir_root, prior_dataset_dir, split_rows, split_cols )
%
% Loads parameters from text file and pass them to runDataset to execute.
%
% Parameters could define a single dataset, a set of datasets and/or a set of different parameters.
%
%   Arguments:
%
%     * [local_parameters] Filepath to file that defines the repository, data directory, results directory, and the running parameters
%     * [traindir_root] path to the new raw training images
%			* [prior_dataset_dir] path to a previously completed dataset directory with a full training set
%			* [split_rows] number of rows to split images into for labelGUI()
%			* [split_cols] number of cols to split images into for labelGUI()
%
%   Returns:
%
%     * nothing
%%

function labelTrainingImages( local_parameters, traindir_root, prior_dataset_dir, split_rows, split_columns )
  %
  setupPaths( local_parameters );
  
	all_training_images = dir( fullfile( [ traindir_root, 'raw/*.pgm' ] ) );
  training_dataset_name = '2013_06_17_Colony_Petite_Syrah';
  dataset_name = training_dataset_name;
  [parameters] = getParameters( local_parameters.ROOT_DATA_DIR, dataset_name );
  parameters.keypoint_detector_type = 'MAXIMAL';
  parameters.descriptor_type = 'FREAK';
  
  classifyParams = [];
	% get the features from all of the training images?
	if (prior_dataset_dir ~= -1)
		% Get features
		% Build KD Forest -> cur_kd_forest
    
    trainingStructure_prior_dataset = [];
    %%%%%%
    training_dataset_dir = [ local_parameters.ROOT_DATA_DIR, '/', training_dataset_name, '/train/' ];

    %%If trainingFeatures passed into function then do not re-extract
    save_vars = 0;
    save_path = '/home/kyle/saved_features_temp.mat';
    if save_vars == 1
      [extracted_features] = extractTrainingFeaturesAndLabels( training_dataset_dir, parameters );
      save( save_path, 'extracted_features' );
    else
      load( save_path, 'extracted_features' );
    end
    trainingStructure_prior_dataset.featuresAndLabels = extracted_features;
    
    %%concatenate all training feature descriptors and labels
    trainingStructure_prior_dataset.all_primFeatVals = horzcat(trainingStructure_prior_dataset.featuresAndLabels.primFeatVal);
    trainingStructure_prior_dataset.all_othFeatVals = horzcat(trainingStructure_prior_dataset.featuresAndLabels.othFeatVal);
    trainingStructure_prior_dataset.all_training_labels = vertcat(trainingStructure_prior_dataset.featuresAndLabels.training_labels);
    trainingStructure_prior_dataset.LOO_kdForests = {};

    %checks that there were no errors in training feature extraction
    if(isempty(trainingStructure_prior_dataset.all_primFeatVals)) && strcmp(parameters.descriptor_type, 'ONLY_COLOR') ~= 1
      error_and_exit('There are no feature values extracted at training');
    end
    if(isempty(trainingStructure_prior_dataset.all_training_labels))
      error_and_exit('There are no training labels');
    end
    if(size(trainingStructure_prior_dataset.all_primFeatVals,2) ~= size(trainingStructure_prior_dataset.all_othFeatVals,2)) && strcmp(parameters.descriptor_type, 'ONLY_COLOR') ~= 1
      error_and_exit('Not the same number of texture and color features');
    end
    
    %%build KD forest and setup the classification parameters
    classifyParams = buildKDForest( trainingStructure_prior_dataset.all_primFeatVals, trainingStructure_prior_dataset.all_othFeatVals, trainingStructure_prior_dataset.all_training_labels, parameters );
    %%%%%%%
  end
  
  parameters_classification_dataset = parameters;
  parameters_classification_dataset.radius_small = 10;
  parameters_classification_dataset.radius_large = 20;
  
  runOnce=1;
  im_norm=[];
  
  for i = 1:size(all_training_images) %training_images)
		% Obtain the current image
    trainingFeatures=struct([]);
    trainingFeatures(i).name = all_training_images(i).name;
		imgfname = [traindir_root, 'raw/', trainingFeatures(i).name];
    raw_image = imread( imgfname );
    [ raw_image_rgb, runOnce, im_norm ] = preProcess( raw_image, runOnce, im_norm );

    if ( ~isempty( classifyParams ) )
			% Get features for the image
      
			% Needs to have the whole setup of combinedFeatureExtractionMex(), etc....
      
      %%%if we are using the cpp implementation we have to initialize the C++ class memory
      fruitDetectorHandle = fruitDetectorClassMex('new');

      [~, trainingFeatures(i).name_wo_ext, ~] = fileparts(imgfname);

      %% step 2 get keypoints
      keypoint_type = parameters_classification_dataset.keypoint_detector_type;
      feature_descriptor_type = parameters_classification_dataset.descriptor_type;
      small_radius = parameters_classification_dataset.radius_small;
      large_radius = parameters_classification_dataset.radius_large;
      radial_symmetry_threshold = parameters_classification_dataset.nonMaxSuppThresh;
      [ x_keypoints, y_keypoints, texture_descriptors, color_descriptors ] = combinedFeatureExtractionMex( imgfname, keypoint_type, feature_descriptor_type, small_radius, large_radius, radial_symmetry_threshold, fruitDetectorHandle);
      
      texture_descriptors = texture_descriptors';
      x_keypoints = double(x_keypoints);
      y_keypoints = double(y_keypoints);
      trainingFeatures(i).keypoint_centers = double([x_keypoints(:), y_keypoints(:)]');
      [trainingFeatures(i).primFeatVal] = double(texture_descriptors);
      
      trainingFeatures(i).othFeatVal = [];
      if(parameters_classification_dataset.use_color_data == 1)
        [trainingFeatures(i).othFeatVal ] = single(color_descriptors);
        %%we need to replicate when there are multiple scale texture features (ie SIFT_MEX). Could we improve this????
        if(size(trainingFeatures(i).primFeatVal,2) == 3*size(trainingFeatures(i).othFeatVal,2))
           trainingFeatures(i).othFeatVal = repmat(trainingFeatures(i).othFeatVal,[1 3]);
        end
      end
      %%%%%%%%%%%%%%%%% End Features
      
			% classifyOneImage() works without labels
      % Later change to accept just one entry in the trainingFeatures
      % struct
			initial_detections = classifyOneImage( classifyParams, trainingFeatures, i, parameters );
      fruit_idx = initial_detections > round( parameters.K_knn / 2 );
      classified_grapes = trainingFeatures(i).keypoint_centers( :, fruit_idx );
      
      % Label image with the initial detections
      radius = 8;
      color = [1, 0, 0];
			[uncorrected_img] = drawColoredDotsOntoImage( raw_image_rgb, classified_grapes, radius, color );
    else
			% Use the raw image to manually select centers
      uncorrected_img = raw_image_rgb;
      classified_grapes = [];
    end
    
    uncorrected_img_dir = [traindir_root, 'uncorrected_cent_red/'];
    mkdir(uncorrected_img_dir);
    [p, n, e] = fileparts( all_training_images(i).name );
    
    uncorrected_img_path = [uncorrected_img_dir, n, '_uncorrected.png'];
    imwrite( uncorrected_img, uncorrected_img_path );
    
    % Get manually labelled image
    labelled_img_dir = [traindir_root, 'labelled_cent_red/'];
    mkdir(labelled_img_dir);
    
    labelled_img_path = [ labelled_img_dir, n, '_cent_red.png' ];
    
    % Save the manually labelled image
      % Save in traindir_root for now
    %
    [labelled_image] = labelGUI( raw_image_rgb, split_rows, split_columns, classified_grapes );
    imwrite( labelled_image, labelled_img_path );
    
    % Build a new kd-tree using all of the manually labelled images
	end
end