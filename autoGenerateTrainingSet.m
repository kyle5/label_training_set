function [] = autoGenerateTrainingSet( local_parameters, calibration_train_sets, calibration_classify_set, parameters_classify_set )
  %
  dataset_path = local_parameters.ROOT_DATA_DIR;

  training_set_size = 10;

  cur_classify_dataset_name = calibration_classify_set{1, 1}{1, 1};
  cur_training_dataset_name = calibration_train_sets{1, 1}{1, 1};

  path_results_generic_training = sprintf( '%s/training_generation_%s/', local_parameters.ROOT_RESULT_DIR, cur_classify_dataset_name );
  classifying_dataset_path = sprintf( '%s/%s/', dataset_path, cur_classify_dataset_name);
  classifying_training_path = sprintf( '%s/train/', classifying_dataset_path );
  path_auto_gen_training = sprintf( '%s/auto_gen_from_%s', path_results_generic_training, cur_training_dataset_name );
  path_auto_gen_training_raw = sprintf( '%s/raw/', path_auto_gen_training );
  mkdir( path_auto_gen_training );
  classifying_set_rows_path = sprintf( '%s/rows/', classifying_dataset_path);

  pgm_already_existing = dir(sprintf( '%s/*.pgm', path_auto_gen_training_raw ));
  jpg_already_existing = dir(sprintf( '%s/*.JPG', path_auto_gen_training_raw ));  
  if size(pgm_already_existing, 1) > size(jpg_already_existing, 1)
    images = pgm_already_existing;
  else
    images = jpg_already_existing;
  end
  images_already_made = size( images, 1 );
	num_new_images = training_set_size - images_already_made;
  classification_dataset_rows = dir([classifying_set_rows_path, 'row*']);
  num_rows = size(classification_dataset_rows, 1);

  train_set_created = struct([]);
  count = 0;
  for i = 1:num_new_images
    valid_image = -1;
    while valid_image == -1
      count = count + 1;
      if count > 100;
        disp('All cam0_images.txt files are empty!?');
        keyboard;
      end
      random_number = randi(num_rows,1,1);
      row_name = classification_dataset_rows(random_number).name;
      row_path = [ classifying_set_rows_path, row_name, '/' ];
      images_txt_path = [row_path, 'cam0_images.txt'];
      fid = fopen(images_txt_path, 'r');
      image_paths = textscan(fid, '%s');
      if numel(image_paths) < 1;
        keyboard;
        continue;
      end
      num_imgs = size(image_paths{1}, 1);
      if num_imgs == 0
        keyboard;
        continue;
      else
        % Pick a random image
        random_img_number = randi(num_imgs,1,1);
        img_partial_path = image_paths{1}{random_img_number};
        [~, cur_img_name, ext] = fileparts( img_partial_path );
        img_full_path = sprintf( '%s/%s', row_path, img_partial_path );
        if ~exist(img_full_path)
          keyboard;
          continue;
        end
        if size(train_set_created, 1) > 1
          all_img_names_created = cell( size(train_set_created, 1) );
          [all_img_names_created{:}] = deal( cur_img_name );
          equal_names_created = cellfun( @strcmp, {train_set_created(:).name}, all_img_names_created );

          all_img_names_already_completed = cell( size(images, 1) );
          [all_img_names_already_completed{:}] = deal( cur_img_name );
          equal_names_already_completed = cellfun( @strcmp, {images(:).name}, all_img_names_already_completed );
          if (sum(equal_names_created(:)) > 1) || (sum(equal_names_already_completed(:)) > 1)
            continue;
          end
        end
        new_img_path = sprintf( '%s/%s%s', path_auto_gen_training_raw, cur_img_name, ext );
        train_set_created(i).name = cur_img_name;
        train_set_created(i).original_row_name = row_name;
        train_set_created(i).original_path = img_full_path;
        train_set_created(i).new_training_path = new_img_path;
        valid_image = 1;
      end
    end
  end
	
  fid_filepaths = fopen( sprintf('%s/filepaths.txt', path_auto_gen_training), 'w' );
  mkdir( path_auto_gen_training_raw );
  for i = 1:numel(train_set_created)
    copyfile( train_set_created(i).original_path, train_set_created(i).new_training_path );
    fprintf(fid_filepaths, 'Img: %d\tRow Name: %s\tImage Name: %s\n', i, train_set_created(i).original_row_name, train_set_created(i).name );
  end
  fclose(fid_filepaths);
  
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Before:
	% Load and Save the training images that have been selected
	
	% Break between 2 new subfunctions
	
	% After:
	% All of the subfunctions that we have previously talked about
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
  [classifyParams] = getClassificationParamsTrainingSet(dataset_path, calibration_train_sets, parameters_classify_set);
  [unlabelledFeatureSet] = getUnlabelledFeatureSet( path_auto_gen_training_raw, parameters_classify_set );
  
  if numel(calibration_train_sets) > 1
    disp( 'Only one train set should be used for automatic training set generation' );
    keyboard;
  end
  path_auto_gen_training_generic_class_img = sprintf('%s/generic_classification/image_as_background/', path_auto_gen_training );
  path_auto_gen_training_generic_class_blk = sprintf('%s/generic_classification/black_background/', path_auto_gen_training );
  path_auto_gen_training_keypoints_img = sprintf('%s/keypoints/image_as_background/', path_auto_gen_training );
  path_auto_gen_training_keypoints_blk = sprintf('%s/keypoints/black_background/', path_auto_gen_training );
	
  mkdir( path_auto_gen_training_generic_class_img );
  mkdir( path_auto_gen_training_generic_class_blk );
  mkdir( path_auto_gen_training_keypoints_img );
  mkdir( path_auto_gen_training_keypoints_blk );
	
  runOnce=1;
  im_norm=[];
  for im_num = 1:numel( unlabelledFeatureSet )
    cur_classify_im_name = unlabelledFeatureSet(im_num).name;
    fprintf('Auto-generating classifications for %s\n', cur_classify_im_name );
    %%%%%%%%%%%%%%%%%%Classification %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% step 1-preprocess
    
    imgfname = [path_auto_gen_training, 'raw/', cur_classify_im_name];
    img=imread(imgfname);
    [img,runOnce,im_norm]=preProcess(img,runOnce,im_norm);
    [~, imgname ~] = fileparts( cur_classify_im_name );

    %% step 3 -Classification
    [fruit_classifications] = classifyOneImage( classifyParams, unlabelledFeatureSet, im_num, parameters_classify_set );
    
    % Draw the detections
    cur_keypoints = unlabelledFeatureSet(im_num).centers;
    [clustFruit] = knnThresholdAndClusterOneImage(img,fruit_classifications,cur_keypoints, parameters_classify_set);

    % Keypoints
    detections_img = drawCirclesToImage( img, cur_keypoints, 3 );
    path_image_background = sprintf('%s/%s.png', path_auto_gen_training_keypoints_img, imgname);
    imwrite( detections_img, path_image_background );

    black_background = zeros(size(detections_img));
    detections_img = drawCirclesToImage( black_background, cur_keypoints, 3 );
    path_black_background = sprintf('%s/%s.png', path_auto_gen_training_keypoints_blk, imgname);
    imwrite(detections_img, path_black_background);

    % Generic Classification
    detections_img = drawCirclesToImage( img, clustFruit, 3 );
    path_image_background = sprintf('%s/%s.png', path_auto_gen_training_generic_class_img, imgname);
    imwrite( detections_img, path_image_background );

    black_background = zeros(size(detections_img));
    detections_img = drawCirclesToImage( black_background, clustFruit, 3 );
    path_black_background = sprintf('%s/%s.png', path_auto_gen_training_generic_class_blk, imgname);
    imwrite(detections_img, path_black_background);
  end
end
