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

function [labelled_image] = labelGUI( raw_image_rgb, split_rows, split_columns )
  % 
  % Split image into segments
  [image_height, image_width] = size( raw_image_rgb );
  
  split_rows_markers = linspace( 1, image_height, split_rows );
  split_columns_markers = linspace( 1, image_width, split_columns );
  
  image_segments = cell( split_rows, split_columns );
  image_segments_marked = cell( split_rows, split_columns );
  for i = 1:split_rows
    for j = 1:split_columns
      row_segment_start = split_rows_markers(i);
      row_segment_end = split_rows_markers(i+1);
      
      column_segment_start = split_columns_markers(i);
      column_segment_end = split_columns_markers(i+1);
      
      cur_image_segment = raw_image_rgb( row_segment_start:row_segment_end, column_segment_start:column_segment_end );

      cur_image_segment_marked = mark_image_segment( cur_image_segment );

      image_segments{i, j} = cur_image_segment;
      image_segments_marked{i, j} = cur_image_segment_marked;
      % Mark each image segment, while iterating through the function
    end
  end
  
  % Reproduce the combined image
  % For
  
  % Returns the final labelled image
  labelled_image = -1;
end