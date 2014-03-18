function mytestfunction_temp()
  %# RGB image
  global sz;
  global hFig;
  global hAx;
  global binary_image;
  global painter_set;
  binary_image = zeros(200, 200);
  sz = size(binary_image);

  %# show image
  hFig = figure();
  hAx = axes();

  imshow(binary_image);
  painter_set = 0;
  
  resetMouseCallbacks();
end

%# hook-up mouse button-down event
function mouseDown( ~, ~ )
  global hAx;
  global sz;
  global binary_image;
  global painter_set;
  if painter_set == 1
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

    %# show (x,y) pixel in title
    title( sprintf( 'image pixel = (%d,%d)', x_pos, y_pos ) );
  end
end

function resetMouseCallbacks(  )
  global hFig;
  set( hFig, 'WindowButtonDownFcn',@setPainter );
  set( hFig, 'WindowButtonUpFcn',@showImage );
  set( hFig, 'WindowButtonMotionFcn',@mouseDown );
end

function setPainter( ~, ~)
  %
  global painter_set;
  painter_set = 1;
end

function showImage( fig, ~)
  %
  global  binary_image;
  global  painter_set;
  global hFig;
  global hAx;
  painter_set = 0;
  hFig = figure;
  hAx = axes();
  close(fig);
  imshow(binary_image);
  resetMouseCallbacks();
end