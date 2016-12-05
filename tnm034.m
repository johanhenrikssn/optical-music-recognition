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
bw_original = 1-im2bw(image, 0.8);

% Find rotation using Hough transform
[H, theta, rho] = hough(bw_original, 'theta', -89.9:0.1:89.9);
peak = houghpeaks(H);
barAngle = theta(peak(2));
B = imrotate(image, 90 + barAngle, 'loose');
bw_original = 1-im2bw(B, 0.8);

% Remove rotation distortion
bw_original = bw_original(20:end-20,20:end-20);

bw = bw_original;

% STAFF LINE IDENTIFICATION 
staff_lines = staff_line_identification(bw);

% Remove staff lines

bw_no_sl = bw;

for i=1:length(staff_lines(:,1))
    bw_no_sl(staff_lines(i,1)-1, :) = 0;
    bw_no_sl(staff_lines(i,1), :) = 0;
    bw_no_sl(staff_lines(i,1)+1, :) = 0;
end

% Identify positions to split into subimages for each row block

split_pos(1) = 70;
for i=5:5:length(staff_lines(:,1))-1
    split_pos(end+1) = ceil(staff_lines(i,1) + ((staff_lines(i+1,1) - staff_lines(i,1)) / 2));
end
split_pos(end+1) = length(bw(:,1))-20;

% Split bw and bw without staff lines

subimg = [];
subimg_no_sl = [];
for i=1:length(split_pos)-1
    subimg{i} = bw(split_pos(i):split_pos(i+1),:);
    subimg_no_sl{i} = bw_no_sl(split_pos(i):split_pos(i+1),:);
end


% Detect note heads

se_disk = strel('disk', 4);

subimg_temp = [];
locs_x = [];
locs_y = [];
for i=1:length(split_pos)-1
    subimg_temp{i} = imerode(subimg{i},se_disk);
    %overlay1 = imoverlay(subimg{i}, subimg_temp{i}, [.3 1 .3]);
    %figure;
    %imshow(overlay1);
    
    [pks, locs_x{i}] = findpeaks(sum(subimg_temp{i},1));
    
    locs_y{i} = [];
    for j = 1:length(locs_x{i})
        temp = subimg_temp{i}(:, locs_x{i}(j)-2:locs_x{i}(j)+2);
        [pks, lo] = findpeaks(sum(temp,2));
        indexOfMaxValue = find(pks == max(pks));
        locs_y{i}(j) = lo(indexOfMaxValue(1));
    end
    
    %figure 
    %imshow(subimg{i})
end 

% Map staff lines to block rows

subimg_staff_lines = [];
for i=1:length(split_pos)-1
    for j=1:5
        subimg_staff_lines{i}(j) = staff_lines((i-1)*5+j, 1) - split_pos(i);
    end
end

subimg_notes = [];
for i=1:9
    if mod(i,2) == 0
        subimg_notes(i) = subimg_staff_lines{3}(i/2)+5;
    else
        subimg_notes(i) = subimg_staff_lines{3}(i-floor(i/2));
    end
end

%figure
%imshow(subimg{3})


%% Expand from note heads to clean up holes etc
se_line = strel('line', 4, 90);
bw2 = imdilate(subimg_no_sl{3},se_line);

imshow(bw2)

%{
locations = [locs_x{3}(:),locs_y{3}(:)];

bw2 = subimg_no_sl{3};
counter = 0;
for i=1:length(locations)
    if subimg_no_sl{3}(locations(i,2), locations(i,1)) == 1
        counter = counter +1
        bw2 = imfill(logical(subimg_no_sl{3}), [locations(i,2), locations(i,1)], 18);
    end
end
counter
imshow(bw2);
%}

%% Draw bounding boxes around note heads
imshow(bw2);

L = bwlabel(bw2);
objects = regionprops(L, 'Area', 'BoundingBox');
for i_img=1:length(split_pos)-1
    for i = 1:length(locs_x{i_img})
        for k = 1:length(objects)
            bb = objects(k).BoundingBox;
            if locs_x{i_img}(i) > bb(1) && locs_x{i_img}(i) < bb(1)+bb(3) && locs_y{i_img}(i) > bb(2) && locs_y{i_img}(i) < bb(2)+bb(4)
                rectangle('Position',[bb(1) bb(2) bb(3) bb(4)],'EdgeColor','green');
            end
        end
    end
end


%% Highlight note heads
figure
imshow(subimg_no_sl{3})
hold on;

for i = 1:length(locs_x{3})
    
    p1 = [0, locs_x{3}(i)];
    p2 = [1000, locs_x{3}(i)];

   % p11 = [locs_y{3}(i), 0];
   % p22 = [locs_y{3}(i), 1000];
    
    plot([p1(2),p2(2)],[p1(1),p2(1)],'Color','r','LineWidth',2)
   % plot([p11(2),p22(2)],[p11(1),p22(1)],'Color','g','LineWidth',2)

    
        
    hold on    
end

%% Determine tones

notes = ['f', 'e', 'd', 'c', 'b', 'a', 'g', 'f', 'e'];
result = '';
for i = 1:length(locs_y{3})
    [~, I] = min(abs(subimg_notes-locs_y{3}(i)));
    c = subimg_notes(I);
    result = strcat(result, notes(I));
end

result

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

