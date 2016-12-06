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


%figure
%imshow(subimg{3})


% Expand from note heads to clean up holes etc
se_line = strel('line', 4, 90);
subimg_clean = [];
for i_img=1:length(split_pos)-1
    subimg_clean{i_img} = imdilate(subimg_no_sl{i_img},se_line);
    
    %figure
    %imshow(subimg_clean{i_img})

end

% Draw bounding boxes around note heads

for i_img=1:length(split_pos)-1
    % Get all coherent regions
    L = bwlabel(subimg_clean{i_img});
    objects = regionprops(L, 'BoundingBox');
    
    %figure
    %imshow(subimg_clean{i_img})

    for i = 1:length(locs_x{i_img})
        for k = 1:length(objects)
            bb = objects(k).BoundingBox;
            % Find right bounding box for each note head
            if locs_x{i_img}(i) > bb(1) && locs_x{i_img}(i) < bb(1)+bb(3) && locs_y{i_img}(i) > bb(2) && locs_y{i_img}(i) < bb(2)+bb(4)
                % Draw and store bounding box
                %rectangle('Position',bb,'EdgeColor','green');
                locs_bb{i_img}(i) = objects(k);
            end
        end
    end
end

% Check if multiple noteheads share bounding box and classify as eighth
% notes
locs_eighth_note = [];
for i_img=1:length(split_pos)-1
    locs_eighth_note{i_img} = zeros(1,length(locs_x{i_img}));
    for i = 1:length(locs_bb{i_img})
        for j = 1:length(locs_bb{i_img})
            if (i ~= j && locs_bb{i_img}(i).BoundingBox(1) == locs_bb{i_img}(j).BoundingBox(1))
                locs_eighth_note{i_img}(i) = true;
                break
            end
        end
    end
end


for i_img=1:length(split_pos)-1
    for i = 1:length(locs_bb{i_img})
        if ~locs_eighth_note{i_img}(i)
            % Horizontal projection to find eighth flag
            x_min = floor(locs_bb{i_img}(i).BoundingBox(1));
            y_min = floor(locs_bb{i_img}(i).BoundingBox(2));
            width = floor(locs_bb{i_img}(i).BoundingBox(3));
            height = floor(locs_bb{i_img}(i).BoundingBox(4));

            tempimg = subimg_clean{i_img}(y_min:(y_min+height), x_min:(x_min+width));

            [pks, locs] = findpeaks(sum(tempimg, 2));
            if length(pks) > 2
                locs_eighth_note{i_img}(i) = true;
            end
        end
    end
end

% Determine tones

notes = {'E4','D4','C4','B3','A3','G3','F3','E3','D3','C3','B2','A2','G2','F2','E2','D2','C2','B1','A1','G1'};
result = '';
for i_img=1:1
    reference_staff_line = subimg_staff_lines{i_img}(5);
    subresult = '';
    for i = 1:2
        distance = reference_staff_line-locs_y{i_img}(i)
        
        
        reference_note = 15;
        diff = mean(diff(subimg_staff_lines{i_img}))
        tone_distance = round(distance/diff)
        
        
        
        %if locs_eighth_note{i_img}(i)
         %   tone = lower(tone);
        %end
        %subresult = strcat(subresult, tone);

        %result = strcat(result, tone);
    end
    
    %i_img
    %subresult
    %result = strcat(result, 'n');
end

%result


