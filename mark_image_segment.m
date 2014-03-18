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
function [grape_boolean, additional_grape_pts] = mark_image_segment( raw_image_rgb, x_start, y_start, segment_width, segment_height, all_pts, grape_boolean )
  %
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
  
  binary_image = false( size(cur_image_segment, 1), size(cur_image_segment, 2) );
  f = figure;
  set(f,'WindowButtonDownFcn',{@draw_to_binary_image,binary_image})
  
  while 1
    imshow(cur_image_segment);
    drawnow
    try
      [x,y,button] = ginput(1);
    catch
      return;
    end
    global_x = x + x_start;
    global_y = y + y_start;
    
    if button == 1
      additional_grape_pts = [additional_grape_pts, [global_x; global_y]];
      [raw_image_rgb, cur_image_segment] = draw_points_and_segment( raw_image_rgb, x_min, x_max, y_min, y_max, [], [], additional_grape_pts );
    elseif button == 2
      break;
    elseif button == 3
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
        min_ind = min_ind_2;
      elseif isempty(min_val_2)
        min_ind = min_ind_1;
      else
        if min_val_1 < min_val_2
          min_ind = min_ind_1;
        else
          min_ind = min_ind_2;
        end
      end
      
      min_global_ind = valid_idx_global( min_ind );
      % Just color a single point to invalid
      single_pt = all_pts(:, min_global_ind);
      grape_boolean(min_global_ind) = true;
      single_grape_boolean = [false];
      [raw_image_rgb, cur_image_segment] = draw_points_and_segment( raw_image_rgb, x_min, x_max, y_min, y_max, single_pt, single_grape_boolean, additional_grape_pts );
    end
  end
end

function draw_to_binary_image(hObject,~, binary_image)
  figure, imshow(binary_image);
  pos=get(hObject,'CurrentPoint');
  disp(['You clicked X:',num2str(pos(1)),', Y:',num2str(pos(2))]);
  binary_image(pos(1), pos(2)) = true;
end

function computeValidPoints(hObject,~, binary_image, all_pt_cords, valid_pts)
  %
  % Fill the binary image
  filled_binary_image = imfill( binary_image, 'holes' );
  % pts within the filled binary image are turned to false
  all_ind = sub2ind( size(binary_image), all_pt_cords(1, :), all_pt_cords(2, :));
  queried_pts = filled_binary_image(all_ind);
  selected = queried_pts > 0;
  valid_pts(selected) = false;
end