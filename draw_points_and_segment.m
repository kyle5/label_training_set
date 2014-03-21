function [raw_image_rgb, cur_image_segment] = draw_points_and_segment( raw_image_rgb, x_min, x_max, y_min, y_max, all_pts, valid_pts, additional_grape_pts, selection_lines )
  %
  radius = 8;
  color_valid = [1, 0, 0];
  color_invalid = [0, 0, 1];
  color_lines = [1, 0, 1];
  % Draw valid as red
  [raw_image_rgb] = drawColoredDotsOntoImage( raw_image_rgb, all_pts(:, valid_pts), radius, color_valid );
  [raw_image_rgb] = drawColoredDotsOntoImage( raw_image_rgb, additional_grape_pts, radius, color_valid );
  % Draw
  [raw_image_rgb] = drawColoredDotsOntoImage( raw_image_rgb, all_pts(:, ~valid_pts), radius, color_invalid );

  [raw_image_rgb] = drawColoredDotsOntoImage( raw_image_rgb, selection_lines, radius, color_lines );

  cur_image_segment = raw_image_rgb( y_min:y_max, x_min:x_max, : );
end