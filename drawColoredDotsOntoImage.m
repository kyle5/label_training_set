function [outImg] = drawColoredDotsOntoImage( img, points, radius, color )
  %%%%
  [H W D] = size(img);
  points_mask = zeros(H,W);
  
  R = radius;
  circle = false(R*2+1,R*2+1);
  center_point = [R+1, R+1];
  for x = 1:size(circle, 2)
    for y = 1:size(circle, 1)
      offset_point = ([x, y] - center_point);
      circle(y, x)= sqrt( sum( offset_point .^ 2)) <= R;
    end
  end
  
  h = fspecial('disk', radius);
  circle = h > mean(h(:))*0.8;
  
  for j=1:size(points,2)
    if points(2,j) - R < 1 || points(1,j) - R < 1 || points(2,j) + R > size(img, 1) || points(1,j) + R > size(img, 2)
      continue;
    end
    points_mask(points(2,j)-R:points(2,j)+R, points(1,j)-R:points(1,j)+R) = points_mask(points(2,j)-R:points(2,j)+R, points(1,j)-R:points(1,j)+R) + circle;
  end
  
  points_mask = points_mask > 0;
  
  outImg = zeros(size(img));
  c = img(:,:,1);
  c(points_mask) = color(1);
  outImg(:,:,1) = c;
  c = img(:,:,2);
  c(points_mask) = color(2);
  outImg(:,:,2) = c;
  c = img(:,:,3);
  c(points_mask) = color(3);
  outImg(:,:,3) = c;
end
