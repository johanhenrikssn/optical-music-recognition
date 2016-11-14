%%%%%%%%%%%%%%%%%%%%%%%%%%
%function strout = tnm034(Im)
%
% Im: Input image of captured sheet music. Im should be in
% double format, normalized to the interval [0,1]
%
% strout: The resulting character string of the detected notes.
% The string must follow the pre-defined format, explained below.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%


%% READ IMAGE

clear all
close all

image = imread('images/im1s.jpg');

% PREPROCESSING 

% Convert to binary image
bw = 1-im2bw(image, 0.8);

% Find rotation using Hough transform
[H, theta, rho] = hough(bw, 'theta', -89.9:0.1:89.9);
peak = houghpeaks(H);
barAngle = theta(peak(2));
B = imrotate(image, 90 + barAngle, 'loose');
bw = 1-im2bw(B, 0.8);


% STAFF LINE IDENTIFICATION 


close all

staff_lines = staff_line_identification(bw);

% Remove staff lines
j = 1;
for i=1:length(staff_lines(:,1))
    bw(staff_lines(i,1)-1, :) = 0;
    bw(staff_lines(i,1), :) = 0;
    bw(staff_lines(i,1)+1, :) = 0;
end

% Expand objects to clean up holes etc
se_line = strel('line', 4, 90);
bw = imdilate(bw,se_line);

% Divide into subimages for each row block
split_pos(1) = bw(1,1);
for i=5:5:length(staff_lines(:,1))-1
    split_pos(end+1) = staff_lines(i,1) + ((staff_lines(i+1,1) - staff_lines(i,1)) / 2);
end
split_pos(end+1) = length(bw(:,1));

notes_row = [];
for i=1:length(split_pos)-1
    i
    notes_row{i} = bw(split_pos(i):split_pos(i+1),:);
    
    figure 
    imshow(notes_row{i})
end 

%%

figure 
imshow(bw)

figure

imshow(bw)
hold on
% Print located staff lines
for i = 1:length(staff_lines)
     
    p1 = [staff_lines(i,1),0];
    p2 = [staff_lines(i,1), 1000];
    
    if(staff_lines(i,2) == 1)
        plot([p1(2),p2(2)],[p1(1),p2(1)],'Color','r','LineWidth',2)
    elseif(staff_lines(i,2) == 2)
        plot([p1(2),p2(2)],[p1(1),p2(1)],'Color','g','LineWidth',2)
    elseif(staff_lines(i,2) == 3)
        plot([p1(2),p2(2)],[p1(1),p2(1)],'Color','b','LineWidth',2)
    elseif(staff_lines(i,2) == 4)
        plot([p1(2),p2(2)],[p1(1),p2(1)],'Color','c','LineWidth',2)
    end
        
    hold on    
end

%%

