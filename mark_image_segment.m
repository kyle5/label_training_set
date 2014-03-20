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

  additional_grape_pts = zeros(2, 0);
  
  x_min = x_start;
  x_max = (x_start+segment_width);
  y_min = y_start;
  y_max = (y_start+segment_height);

  % Draw all the points onto the image
  [raw_image_rgb, cur_image_segment] = draw_points_and_segment( raw_image_rgb, x_min, x_max, y_min, y_max, all_pts, grape_boolean, additional_grape_pts );

  pts_x = all_pts(1, :);
  pts_y = all_pts(2, :);

  valid_pts = pts_x > x_start & pts_x < ( x_start + segment_width ) & pts_y > y_start & pts_y < ( y_start + segment_height );
  valid_idx_global = find( valid_pts );
  cur_segment_pts_global = all_pts( :, valid_pts );
  additional_grape_global_idx_starting_idx = numel(valid_pts);
  current_last_grape_global_idx = additional_grape_global_idx_starting_idx;
  binary_image = false( size(cur_image_segment, 1), size(cur_image_segment, 2) );

  sz = size( binary_image );
  painter_set = 0;

  hFig = figure;
	hAx = axes();

  imshow(cur_image_segment);
  set_mouse_callbacks();
  pause(100);
  keyboard;
end

function set_mouse_callbacks()
	%
	global hFig;
  set( hFig, 'WindowButtonDownFcn',@setPainter );
  set( hFig, 'WindowButtonUpFcn',@mouse_released_callback );
  set( hFig, 'WindowButtonMotionFcn',@mouse_moved );	
end

function setPainter( ~, ~)
  %
  global painter_set;
  painter_set = 1;
  disp('bbb');
end

function mouse_moved( ~, ~ )
  global hAx;
  global sz;
  global binary_image;
  global painter_set;
  if painter_set == 1
    disp('mouse moved with paint_set == 1');
    p = get(hAx,'CurrentPoint');
    p = p(1,1:2);

    %# convert axes coordinates to image pixel coordinates
    %# I am also rounding to integers
    x_pos = round( axes2pix(sz(2), [1 sz(2)], p(1)) );
    y_pos = round( axes2pix(sz(1), [1 sz(1)], p(2)) );

    R = 5;

    img_width = size(binary_image, 2);
    x_min = max(x_pos-R, 1);
    x_max = min(x_pos+R, img_width);

    img_height = size(binary_image, 1);
    y_min = max(y_pos-R, 1);
    y_max = min(y_pos+R, img_height);

    disp( ['x_min: ', num2str(x_min), 'x_max: ', num2str(x_max), 'y_min: ', num2str(y_min), 'y_max: ', num2str(y_max)] );
    binary_image(y_min:y_max, x_min:x_max) = true;
  end
end

%{
function mouse_released_callback_positive()
	%
  new_pt = [global_x; global_y];
%       additional_grape_pts = [additional_grape_pts, new_pt];
  additional_grape_pts = zeros(2, 0);
  % Add point to both local and global vectors that organize grape
  % classifications and locations
  cur_segment_pts_global = [cur_segment_pts_global, new_pt];
  all_pts = [all_pts, new_pt];
  grape_boolean = [ grape_boolean; true ];
  
  % Signify the global idx of the added point
  new_idx = current_last_grape_global_idx + 1;
  valid_idx_global = [valid_idx_global, new_idx];
  current_last_grape_global_idx = new_idx;
  
  [raw_image_rgb, cur_image_segment] = draw_points_and_segment( raw_image_rgb, x_min, x_max, y_min, y_max, [new_pt], [true], additional_grape_pts );
end


function mouse_released_callback_negative(  )
	%
  % Find the closest point to the current point clicked
  pnts_1 = repmat([global_x; global_y],[1, size(additional_grape_pts, 2)]);
  err_1 = pnts_1-additional_grape_pts;
  [min_val_1,min_ind_1] = min(sum(err_1.*err_1).^.5);
  
  pnts_2 = repmat([global_x; global_y],[1, size(cur_segment_pts_global, 2)]);
  err_2 = pnts_2-cur_segment_pts_global;
  [min_val_2,min_ind_2] = min(sum(err_2.*err_2).^.5);
  if isempty(min_val_1) && isempty(min_val_2)
    disp('There are no true grapes');
    continue;
  elseif isempty(min_val_1)
    disp('elseif isempty(min_val_1)')
    min_ind = min_ind_2;
  elseif isempty(min_val_2)
    disp('elseif isempty(min_val_2)')
    min_ind = min_ind_1;
  else
    if min_val_1 < min_val_2
      disp('if min_val_1 < min_val_2')
      min_ind = min_ind_1;
    else
      disp('~   if min_val_1 < min_val_2')
      min_ind = min_ind_2;
    end
  end

  min_global_ind = valid_idx_global( min_ind );
  
  % Just color a single point to invalid
  single_pt = all_pts(:, min_global_ind);
  grape_boolean(min_global_ind) = false;
  single_grape_boolean = [false];
  
  % Draw the entire image
  [raw_image_rgb, cur_image_segment] = draw_points_and_segment( raw_image_rgb, x_min, x_max, y_min, y_max, single_pt, single_grape_boolean, additional_grape_pts );
end
%}

function mouse_released_callback(~, ~)
	%
	global binary_image;
  global painter_set;
  global hAx;
  painter_set = 0;

  p = get(hAx,'CurrentPoint');
  x = p(1,1);
  y = p(1,2);

  x_start = 0;
  y_start = 0;
  global_x = x + x_start;
  global_y = y + y_start;

	% Find area clicked:
	% If large: consider as circled
	% If small: consider as single point

	% Draw binary image
	image_seg_path = '/home/kyle/testing_image_segmentation/';
	mkdir( image_seg_path );
	imwrite( binary_image, [ image_seg_path, 'img_seg_binary_img.png' ] );

	set_mouse_callbacks();
	% If posititive:
	% call positive callback
	% call negative callback
end

% function computeValidPoints(hObject,~, binary_image, all_pt_cords, valid_pts)
%   %
%   % Fill the binary image
%   filled_binary_image = imfill( binary_image, 'holes' );
%   % pts within the filled binary image are turned to false
%   all_ind = sub2ind( size(binary_image), all_pt_cords(1, :), all_pt_cords(2, :));
%   queried_pts = filled_binary_image(all_ind);
%   selected = queried_pts > 0;
%   valid_pts(selected) = false;
% end
