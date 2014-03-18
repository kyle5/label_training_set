% function [labelled_image] = labelGUI( raw_image_rgb, split_rows, split_columns )
%
% Loads local file path values from a file or from the command line.
%
%   Arguments:
%
%     * [raw_image_rgb] A raw image that is to be labelled by the program
%     * [split_rows] Number of rows segments to split image for labelling
%     * [split_columns] Number of column segments to split image for labelling
%
%   Returns:
%
%     * [labelled_image] A labelled image from the program

function [labelled_image] = labelGUI( raw_image_rgb, split_rows, split_columns, all_pts )
  %
  % Split image into segments
  [image_height, image_width, ~] = size( raw_image_rgb );
  
  image_y_delta = floor( image_height / split_rows );
  image_x_delta = floor( image_width / split_columns );
  
  split_rows_markers = round(linspace( 1, image_height, split_rows+1 ));
  split_columns_markers = round(linspace( 1, image_width, split_columns+1 ));
  
  grape_boolean = true( size( all_pts, 2 ), 1 );
  for i = 1:split_rows
    for j = 1:split_columns
      row_segment_start = split_rows_markers(i);
      row_segment_end = split_rows_markers(i+1);
      
      column_segment_start = split_columns_markers(j);
      column_segment_end = split_columns_markers(j+1);
      
      segment_width = image_x_delta;
      segment_height = image_y_delta;
      
      i
      j
      row_segment_start
      row_segment_end
      column_segment_start
      column_segment_end
%       imshow(cur_image_segment)
%       keyboard;
      [grape_boolean, additional_grape_pts] = mark_image_segment( raw_image_rgb, column_segment_start, row_segment_start, segment_width, segment_height, all_pts, grape_boolean );
      
      all_pts = [all_pts, additional_grape_pts];
      grape_boolean = [grape_boolean(:); true(size(additional_grape_pts, 2), 1)];
    end
  end
  
  % Returns the final labelled image
  radius = 8;
  color_valid = [1, 0, 0];
  % Draw valid as red
  [labelled_image] = drawColoredDotsOntoImage( raw_image_rgb, all_pts(:, grape_boolean), radius, color_valid );
end