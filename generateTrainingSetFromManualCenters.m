% This will be a function to enter precision and recall and get manual
% centers like that

function [] = generateTrainingSetFromManualCenters( local_parameters, calibration_train_sets, calibration_classify_set, parameters_classify_set )
  % Load all of the manual centers images
  dataset_path = local_parameters.ROOT_DATA_DIR;

  cur_classify_dataset_name = calibration_classify_set{1, 1}{1, 1};
  cur_training_dataset_name = calibration_train_sets{1, 1}{1, 1};
  cur_training_train_set_specifier = calibration_train_sets{1, 1}{1, 2};
  cur_training_train_set_path = sprintf( '%s/%s/train/', dataset_path, cur_training_dataset_name );
  
  path = '/home/kyle/temp/feature_space_auto_gen_training.mat';
  save_file = 0;
  if save_file == 1
    [featureSet] = getFeatureSetFromDatasetTrainImages( cur_training_train_set_path, cur_training_train_set_specifier, parameters_classify_set );
    save( path, 'featureSet' );
  else
    load( path, 'featureSet' );
  end
  
  recall = 1.0;
  precision = 0.97;
  
  path_altered_manual_centers_dir = sprintf( '%s/manual_centers_recall_%.2f_precision_%.2f/', local_parameters.ROOT_RESULT_DIR, recall, precision );
  mkdir( path_altered_manual_centers_dir );
  
  img_names_to_use = { 'frame000692', 'frame001211', 'frame001532' };
  
  runOnce = 1;
  im_norm = [];
  for i = 1:numel(featureSet)
    
    img_name_repeated = cell( 1, numel(img_names_to_use) );
    [img_name_repeated{:}] = deal( featureSet(i).name_wo_ext );
    
    equal_names = cellfun( @strcmp, img_names_to_use, img_name_repeated );
    if (sum(equal_names(:)) == 0); continue; end
    cur_msk_centers = featureSet(i).msk_cents;
    
    % Cut out (1-recall)% of points
    len_msk_centers = size(cur_msk_centers, 2);
    len_valid_msk_centers = round(len_msk_centers * recall);
    len_invalid_msk_centers = len_valid_msk_centers*(1-precision);
    
    random_idx_full = randperm( len_msk_centers );
    correct_classifications = random_idx_full( 1:len_valid_msk_centers );
    cur_msk_centers_recall = cur_msk_centers( :, correct_classifications );
    
    y_dim = featureSet(i).img_size(1);
    x_dim = featureSet(i).img_size(2);
    if precision ~= 1
      % Add in ((1-precision)% random points
      r = rand([2,len_invalid_msk_centers]);
      
      random_image_cords = round(r .* repmat( [x_dim; y_dim], [1, len_invalid_msk_centers] ));

      random_image_cords( random_image_cords(:) == 0 ) = 1;
      random_image_cords( random_image_cords(1, :) > x_dim ) = x_dim;
      random_image_cords( random_image_cords(2, :) == y_dim) = y_dim;

      all_points_drawn = [ cur_msk_centers_recall, random_image_cords ];
    else
      all_points_drawn = [ cur_msk_centers_recall ];
    end
    
    imgfname = [ cur_training_train_set_path, 'raw/', featureSet(i).name ];
    img=imread( imgfname );
    [img,runOnce,im_norm]=preProcess(img,runOnce,im_norm);
    
    
    x_cords = all_points_drawn(1,:);
    y_cords = all_points_drawn(2,:);
    dist_edge = 50;
    valid_x = x_cords > dist_edge & x_cords<(x_dim-dist_edge);
    valid_y = y_cords > dist_edge & y_cords<(y_dim-dist_edge);
    valid = valid_x & valid_y;
    all_points_drawn = all_points_drawn( :, valid );
    
    % Keypoints
    detections_img = drawCirclesToImage( img, all_points_drawn, 3 );
    
    path_cur_training_img = sprintf( '%s/%s/', path_altered_manual_centers_dir, featureSet(i).name_wo_ext );
    mkdir( path_cur_training_img );
    
    imwrite( img, [ path_cur_training_img, 'original_rgb_img.png' ] );
    
    count = 0;
    % Break the image into 3 pieces
    pieces = 3;
    x_step = (x_dim/pieces);
    y_step = (y_dim/pieces);
    for x = 1:pieces
      for y = 1:pieces
        edge_overlap = 50;
        optimal_x_min = max( (x-1)*x_step - edge_overlap, 1 );
        optimal_x_max = min( (x)*x_step + edge_overlap, size(img, 2) );
        optimal_y_min = max( (y-1)*y_step - edge_overlap, 1 );
        optimal_y_max = min( (y)*y_step + edge_overlap, size(img, 1) );
        
        x_segment = floor([optimal_x_min, optimal_x_max]);
        y_segment = floor([optimal_y_min, optimal_y_max]);
        
        cur_segment = segment_image( detections_img, x_segment, y_segment );
        count = count + 1;
        
        path_img_write = sprintf( '%s/%d.png', path_cur_training_img, count );
        imwrite( cur_segment, path_img_write );
      end
    end
  end
end

function [segment] = segment_image( detections_img, x_segment, y_segment )
  %
  segment = detections_img( y_segment(1):y_segment(2), x_segment(1):x_segment(2), : );
end