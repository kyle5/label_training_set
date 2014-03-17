% function [] = labelTrainingImages( local_parameters, training_dir, prior_dataset_dir, split_rows, split_cols )
%
% Loads parameters from text file and pass them to runDataset to execute.
%
% Parameters could define a single dataset, a set of datasets and/or a set of different parameters.
%
%   Arguments:
%
%     * [local_parameters] Filepath to file that defines the repository, data directory, results directory, and the running parameters
%     * [training_dir] path to the new raw training images
%			* [prior_dataset_dir] path to a previously completed dataset directory with a full training set
%			* [split_rows] number of rows to split images into for labelGUI()
%			* [split_cols] number of cols to split images into for labelGUI()
%
%   Returns:
%
%     * nothing
%%

function labelTrainingImages( local_parameters, training_dir, prior_dataset_dir, split_rows, split_columns )
  %
	all_training_images = dir( fullfile( [ training_dir, '*.pgm' ] ) );
  training_dataset_name = '2013_06_17_Colony_Petite_Syrah';
  dataset_name = training_dataset_name;
  [parameters] = getParameters(local_parameters.ROOT_DATA_DIR, dataset_name);
  
	% get the features from all of the training images?
	if (prior_dataset_dir ~= -1)
		% Get features
		% Build KD Forest -> cur_kd_forest
    
    trainingStructure = struct([]);
    %%%%%%
    training_dataset_dir = [local_parameters.ROOT_DATA_DIR,'/', training_dataset_name,'/train/'];
    %%If trainingFeatures passed into function then do not re-extract
    [trainingStructure.featuresAndLabels] = extractTrainingFeaturesAndLabels( training_dataset_dir, parameters );

    %%concatenate all training feature descriptors and labels
    trainingStructure.all_primFeatVals = horzcat(trainingStructure.featuresAndLabels.primFeatVal);
    trainingStructure.all_othFeatVals = horzcat(trainingStructure.featuresAndLabels.othFeatVal);
    trainingStructure.all_training_labels = vertcat(trainingStructure.featuresAndLabels.training_labels);
    trainingStructure.LOO_kdForests = {};

    %checks that there were no errors in training feature extraction
    if(isempty(trainingStructure.all_primFeatVals)) && strcmp(parameters.descriptor_type, 'ONLY_COLOR') ~= 1
      error_and_exit('There are no feature values extracted at training');
    end
    if(isempty(trainingStructure.all_training_labels))
      error_and_exit('There are no training labels');
    end
    if(size(trainingStructure.all_primFeatVals,2) ~= size(trainingStructure.all_othFeatVals,2)) && strcmp(parameters.descriptor_type, 'ONLY_COLOR') ~= 1
      error_and_exit('Not the same number of texture and color features');
    end
    
    %%build KD forest and setup the classification parameters
    classifyParams = buildKDForest( trainingStructure.all_primFeatVals, trainingStructure.all_othFeatVals, trainingStructure.all_training_labels, parameters );
    %%%%%%%
  end
  
  traindir_root = training_dir;
  
  runOnce=1;
  im_norm=[];
  
  for i = 1:size(all_training_images) %training_images)
		% Obtain the current image
		raw_image = all_training_images(i);
    [raw_image_rgb, runOnce, im_norm] = preProcess(raw_image, runOnce, im_norm);

    if ( exist( cur_kd_forest ) )
			% Get features for the image
      
			% Needs to have the whole setup of combinedFeatureExtractionMex(), etc....
      
      trainingFeatures=struct([]);

      %%%if we are using the cpp implementation we have to initialize the C++ class memory
      fruitDetectorHandle = fruitDetectorClassMex('new');

      trainingFeatures(i).name=all_training_images(i).name;
      [~, trainingFeatures(i).name_wo_ext, ~] = fileparts(dirImgs(i).name);
      
      %% step 1 - preprocess image
      imgfname = [traindir_root, 'raw/', trainingFeatures(i).name];
      parameters_classification_dataset = parameters;
      parameters_classification_dataset.radius_small = 10;
      parameters_classification_dataset.radius_large = 20;
      
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
      trainingFeatures(i).keypoint_centers = double([x_keypoints, y_keypoints]');
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
      
      % Use the PCA parameters in classifyParams to reduce the trainingFeatures
      % data down to the correct size
      
			% classifyOneImage() works without labels
      % Later change to accept just one entry in the trainingFeatures
      % struct
			initial_detections = classifyOneImage( classifyParams, trainingFeatures, i, parameters );
      classified_grapes = trainingFeatures(i).keypoint_centers( :, initial_detections );
      
      % Label image with the initial detections
      points = classified_grapes;
      radius = 10;
      color = [255, 0, 0];
			[uncorrected_img] = drawColoredDotsOntoImage( raw_image_rgb, points, radius, color );
    else
			% Use the raw image to manually select centers
      uncorrected_img = raw_image_rgb;
    end
    
    % Get manually labelled image
    [ labelled_image ] = labelGUI( raw_image, split_rows, split_columns );
    
    % Save the manually labelled image
      % Save in training_dir for now
    %
    
    % Build a new kd-tree using all of the manually labelled images
    
	end
end