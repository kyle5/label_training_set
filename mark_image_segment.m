  % function [cur_image_segment_marked] = mark_image_segment( cur_image_segment )
%
% Loads local file path values from a file or from the command line.
%
%   Arguments:
%
%     * [cur_image_segment] A raw image patch that is to be labelled by the program
%
%   Returns:
%
%     * [cur_image_segment_marked] A labelled image patch returned from the program

function [grape_boolean, all_pts] = mark_image_segment( raw_image_rgb, x_start, y_start, segment_width, segment_height, all_pts, grape_boolean )
  %
  global sz;
  global hFig;
  global hAx;
  global binary_image;
  global painter_set;
  
  global all_pts_global;
  global valid_pts;
  global x_start_global;
  global y_start_global;
  global x_end_global;
  global y_end_global;
  global cur_image_segment;
  global grape_boolean_global;
  global R;
  global finished;  
  global positive;
  global raw_image_rgb_global;
  global count;
  global selection_lines;
  global last_idx;
  
  last_idx = 1;
  count = 0;
  selection_lines = zeros([2, 10000]);
  
  finished = 0;
  x_start_global = x_start;
  y_start_global = y_start;
  all_pts_global = all_pts;
  grape_boolean_global = grape_boolean;
  raw_image_rgb_global = raw_image_rgb;
  
  R = 5;
  positive = 1;
  
  additional_grape_pts = zeros(2, 0);
  
  x_min = x_start;
  x_max = (x_start+segment_width);
  y_min = y_start;
  y_max = (y_start+segment_height);
  
  x_end_global = x_max;
  y_end_global = y_max;
  
  % Draw all the points onto the image
  [raw_image_rgb, cur_image_segment] = draw_points_and_segment( raw_image_rgb, x_min, x_max, y_min, y_max, all_pts_global, grape_boolean_global, additional_grape_pts, selection_lines );

  pts_x = all_pts_global(1, :);
  pts_y = all_pts_global(2, :);
  
  valid_pts = pts_x > x_start & pts_x < ( x_start + segment_width ) & pts_y > y_start & pts_y < ( y_start + segment_height );
  
  binary_image = false( size(cur_image_segment, 1), size(cur_image_segment, 2) );

  sz = size( binary_image );
  painter_set = 0;

  hFig = figure;
	hAx = axes();

  imshow(cur_image_segment);
  drawnow;
  hold on;
  
  % Task 1: Draw point to image
  h = size(cur_image_segment, 1);
  w = size(cur_image_segment, 2);
  
  set_mouse_callbacks();
  set_keyboard_callbacks();
  
  % Keyboard callback will signal finished
  disp('Waiting for user to signal that program should continue');
  
  while 1
    pause(0.5);
    if finished == 1
      close all;
      break;
    end
  end
  
  all_pts = all_pts_global;
  grape_boolean = grape_boolean_global;
end

function set_mouse_callbacks()
	%
	global hFig;
  set( hFig, 'WindowButtonDownFcn',@setPainter );
  set( hFig, 'WindowButtonUpFcn',@mouse_released_callback );
  set( hFig, 'WindowButtonMotionFcn',@mouse_moved );	
end

function set_keyboard_callbacks()
	%
	global hFig;
  set( hFig, 'KeyPressFcn',@keyPressedCallback );
end

function keyPressedCallback(h_obj_local, evt)
  %
  global positive;
  global finished;
  disp(evt.Key);
  if strcmp( evt.Key, 'return' )
    % Skip to the next image
    finished = 1;
  elseif strcmp( evt.Key, 'space' )
    % Skip to the next image
    if positive == 0
      positive = 1;
    else
      positive = 0;
    end
  end
end

function setPainter( ~, ~)
  %
  global painter_set;
  global positive;
  global hAx;
  p = get(hAx,'CurrentPoint');
  p = p(1,1:2);
  if positive == 0
    plot( hAx, p(1), p(2), 'b*' );
  else
    plot( hAx, p(1), p(2), 'r*' );
  end
  painter_set = 1;
end

function mouse_moved( fig, ~ )
  global hAx;
  global sz;
  global binary_image;
  global painter_set;
  global R;
  global positive;
  
  if painter_set == 1
    disp('mouse moved with paint_set == 1');
    p = get(hAx,'CurrentPoint');
    p = p(1,1:2);
    binary_image = draw_to_binary_image(binary_image, sz, p, R);
    
    % Task 2: Draw a set of points to an image
    if positive == 0
      plot( hAx, p(1), p(2), 'b*' );
    else
      plot( hAx, p(1), p(2), 'r*' );
    end
  end
end

function [binary_image] = draw_to_binary_image(binary_image, sz, p, R)
  %
  x_pos = round( axes2pix(sz(2), [1 sz(2)], p(1)) );
  y_pos = round( axes2pix(sz(1), [1 sz(1)], p(2)) );

  img_width = size(binary_image, 2);
  x_min = max(x_pos-R, 1);
  x_max = min(x_pos+R, img_width);

  img_height = size(binary_image, 1);
  y_min = max(y_pos-R, 1);
  y_max = min(y_pos+R, img_height);

  disp( ['x_min: ', num2str(x_min), 'x_max: ', num2str(x_max), 'y_min: ', num2str(y_min), 'y_max: ', num2str(y_max)] );
  binary_image(y_min:y_max, x_min:x_max) = true;
end

function [grape_boolean_global, all_pts_global, valid_pts] = mouse_released_callback_positive( binary_image, all_pts_global, valid_pts, x_start_global, y_start_global, grape_boolean_global )
	%
  valid_binary_image = binary_image > 0;
  [y_cords, x_cords] = find( valid_binary_image );
  avg_y = mean(y_cords(:));
  avg_x = mean(x_cords(:));
  
  mouse_click_pt_global = [avg_x+x_start_global; avg_y+y_start_global];
  
  all_pts_global = [ all_pts_global, mouse_click_pt_global ];
  grape_boolean_global = logical([ grape_boolean_global(:); true ]);
  valid_pts = logical([valid_pts(:); true]);
end

function [grape_boolean_global] = mouse_released_callback_negative( binary_image, all_pts_global, valid_pts, x_start_global, y_start_global, grape_boolean_global )
	% Will be called in case of a small mouse click
  % Find the closest point to the current point clicked

  valid_binary_image = binary_image > 0;
  [y_cords, x_cords] = find(valid_binary_image);
  avg_y = mean(y_cords(:));
  avg_x = mean(x_cords(:));

  mouse_click_pt = [ avg_x; avg_y ];

  valid_idx_global = find( valid_pts );
  cur_segment_pts = all_pts_global(:, valid_pts);
  cur_segment_pts_local = cur_segment_pts - repmat( [x_start_global; y_start_global], [1, size(cur_segment_pts, 2)] );

%   additional_grape_pts = zeros([2, 0]);
%   pnts_1 = repmat( mouse_click_pt, [1, size(additional_grape_pts, 2)] );
%   err_1 = pnts_1-additional_grape_pts;
%   [min_val_1,min_ind_1] = min(sum(err_1.*err_1).^.5);

  pnts_2 = repmat( mouse_click_pt, [1, size(cur_segment_pts_local, 2)] );
  err_2 = pnts_2-cur_segment_pts_local;
  [min_val_2,min_ind_2] = min(sum(err_2.*err_2).^.5);
  min_ind = -1;
  if isempty(min_val_2)
    disp('elseif isempty(min_val_2)')
    keyboard;
  else
    min_ind = min_ind_2;
  end
  
  min_global_ind = valid_idx_global( min_ind );
  % Just color a single point to invalid
  grape_boolean_global(min_global_ind) = false;
end

function [grape_boolean_global] = large_mouse_callback( binary_image, all_pts_global, valid_pts, x_start_global, y_start_global, grape_boolean_global )
  %
  % Draw binary image
	image_seg_path = '/home/kyle/testing_image_segmentation/';
	mkdir( image_seg_path );
	imwrite( binary_image, [ image_seg_path, 'img_seg_binary_img.png' ] );
  
  % Fill the binary image
  binary_image_filled = imfill( binary_image, 'holes' );
  imwrite( binary_image_filled, [ image_seg_path, 'img_seg_binary_img_filled.png' ] );
  
  % Find points that are on the filled binary image
  % Use global points
  % Get valid in global space
  cur_segment_pts_global = all_pts_global(:, valid_pts);
  % Off set global points by the current x_start and y_start
  cur_segment_pts_local = cur_segment_pts_global - repmat( [x_start_global; y_start_global], [1, size(cur_segment_pts_global, 2)] );
  
  % Get points on the filled mask
  idx_from_coordinates = sub2ind( size(binary_image), cur_segment_pts_local(2, :), cur_segment_pts_local(1, :) );
  cur_segment_pts_local_on_mask_b = logical(binary_image_filled( idx_from_coordinates ) );
  
  % Turn points on the filled binary images to false for now
  cur_segment_grape_boolean = grape_boolean_global(valid_pts);
  
  cur_segment_grape_boolean(cur_segment_pts_local_on_mask_b) = false;
  grape_boolean_global(valid_pts) = cur_segment_grape_boolean;
end

function mouse_released_callback( fig, ~ )
	%
	global binary_image;
  global painter_set;

  global hFig;
  global hAx;
  global x_start_global;
  global y_start_global;
  global x_end_global;
  global y_end_global;
  
  global valid_pts;
  global grape_boolean_global;
  global all_pts_global;
  global R;
  
  global positive;
  global raw_image_rgb_global;
  global selection_lines;
  global sz;
  global cur_image_segment;
  
  p = get(hAx,'CurrentPoint');
  p = p(1,1:2);
  [binary_image] = draw_to_binary_image(binary_image, sz, p, R);
  
  painter_set = 0;
  
	% Find area clicked:
	% If large: consider as circled
	% If small: consider as single point
  
  % Determine if it is a small or large mouse click
  
  if ( sum(binary_image(:)) > ((R^2)*10))
    if positive == 1
      disp('Large/Positive Mouse Click');
      disp('Not Supported: Large/Positive Mouse Click');
    else
      [grape_boolean_global] = large_mouse_callback( binary_image, all_pts_global, valid_pts, x_start_global, y_start_global, grape_boolean_global );
      disp('Large/Negative Mouse Click');
    end
  else
    if positive == 1
      [grape_boolean_global, all_pts_global, valid_pts] = mouse_released_callback_positive( binary_image, all_pts_global, valid_pts, x_start_global, y_start_global, grape_boolean_global );
      disp('Small/Positive Mouse Click');
    else
      [grape_boolean_global] = mouse_released_callback_negative( binary_image, all_pts_global, valid_pts, x_start_global, y_start_global, grape_boolean_global );
      disp('Small/Negative Mouse Click');
    end
  end
  
  % Reset binary image
  binary_image = zeros( size(binary_image) );
  
  [~, cur_image_segment] = draw_points_and_segment( raw_image_rgb_global, x_start_global, x_end_global, y_start_global, y_end_global, all_pts_global, grape_boolean_global, zeros(2, 0), selection_lines );
%   hFig = figure;
%   hAx = axes();
%   imshow( cur_image_segment );
%   hold on;
%   close(fig);

%   hFig = figure;
  axes(hAx);
  imshow( cur_image_segment );
  hold on;
%   close(fig);
  
  % Reset the mouse and keyboard callbacks
	set_mouse_callbacks();
  set_keyboard_callbacks();
end