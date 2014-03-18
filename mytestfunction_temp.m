% This is a testing script to handle mouse clicks in matlab




function mytestfunction_temp()
  %
  binary_image = false(200, 200);
  pt_cords = round(rand(2, 100));
  valid_pts = true([size(pt_cords, 2), 1]);

  f=figure;
  imshow(binary_image);
  painter_set = 0;
  set(f,'WindowButtonDownFcn',{@setPainter, painter_set})
  set(f,'WindowButtonMotionFcn',{@mytestcallback, binary_image, painter_set})
end

function setPainter( hObject, ~, painter_set)
  %
  painter_set = 1;
end

function mytestcallback( hObject, ~, binary_image, painter_set )
  %
  if painter_set == 1
    pos=get(hObject,'CurrentPoint');
    disp(['You clicked X:',num2str(pos(1)),', Y:',num2str(pos(2))]);
  end
  disp( ['painter_set: ', num2str( painter_set )] );
end