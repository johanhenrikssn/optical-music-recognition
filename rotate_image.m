function [ rotated_image ] = rotate_image( image )
% FIND ROTATION 
%   Inputs, binary image
%   Outputs, binary image that is rotatated with an angle based on Hough
%   transform

    [H, theta, rho] = hough(image, 'theta', -89.9:0.1:89.9);
    peak = houghpeaks(H);
    barAngle = theta(peak(2));

    if barAngle > 0
        angle = 270 + barAngle;
    else
        angle = 90 + barAngle;
    end
    
     rotated_image = imrotate(image, angle, 'bilinear','crop');
end

