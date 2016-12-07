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
bw_original = 1-imbinarize(image(:,:,3),'adaptive','ForegroundPolarity','dark','Sensitivity',0.4);

% Find rotation using Hough transform
[H, theta, rho] = hough(bw_original, 'theta', -89.9:0.1:89.9);
peak = houghpeaks(H);
barAngle = theta(peak(2));

if barAngle > 0
    rotationAngle = 270 + barAngle;
else
    rotationAngle = 90 + barAngle;
end

B = imrotate(image, rotationAngle, 'loose');
bw_original = 1-im2bw(B, 0.8);

crop = abs(round(tand(rotationAngle) * length(bw_original(1,:))));

% Remove rotation distortion
bw_original = bw_original(crop:end-crop,crop:end-crop);

bw = bw_original;


% STAFF LINE IDENTIFICATION 
staff_lines = staff_line_identification(bw);


% Remove staff lines
bw_no_sl = bw;
for i=1:length(staff_lines(:))
    bw_no_sl(staff_lines(i)-1, :) = 0;
    bw_no_sl(staff_lines(i), :) = 0;
    bw_no_sl(staff_lines(i)+1, :) = 0;
end


% Identify positions to split into subimages for each row block
split_pos(1) = max(staff_lines(1)-75, 1);
for i=5:5:length(staff_lines(:))-1
    split_pos(end+1) = ceil(staff_lines(i) + ((staff_lines(i+1) - staff_lines(i)) / 2));
end
split_pos(end+1) = length(bw(:,1));

% Split bw and bw without staff lines
subimg = [];
subimg_no_sl = [];
for i=1:length(split_pos)-1
    subimg{i} = bw(split_pos(i):split_pos(i+1),:);
    subimg_no_sl{i} = bw_no_sl(split_pos(i):split_pos(i+1),:);
end


% Detect note heads
se_disk_small = strel('disk', 3);
se_disk = strel('disk', 4);
se_disk_large = strel('disk', 5);

subimg_temp = [];

for i_img=1:length(split_pos)-1
        
    % Filter out round objects i.e. note heads
    subimg_temp{i_img} = imerode(subimg{i_img},se_disk);
    
    
    L = bwlabel(subimg_temp{i_img});
    note_heads = regionprops(L, 'Area');
    max_area = max([note_heads.Area]);
    
   
    % Remove noise
    subimg_temp{i_img} = bwareaopen(subimg_temp{i_img}, round(max_area*0.4));
    % Merge close objects
    subimg_temp{i_img} = imdilate(subimg_temp{i_img},se_disk_large);
    
    
    overlay = imoverlay(subimg{i_img}, subimg_temp{i_img}, [.3 1 .3]);
    figure;
    imshow(overlay);
    note_heads = regionprops(subimg_temp{i_img}, 'Centroid');
    centroids = cat(1, note_heads.Centroid);
    locs_x{i_img} = centroids(:,1);
    locs_y{i_img} = centroids(:,2);
end 



%
% Map staff lines to block rows
subimg_staff_lines = [];
for i=1:length(split_pos)-1
    for j=1:5
        subimg_staff_lines{i}(j) = staff_lines((i-1)*5+j) - split_pos(i);
    end
end

%figure
%imshow(subimg_no_sl{1})


% Expand from note heads to clean up holes etc
se_line = strel('line', 4, 90);
subimg_clean = [];
for i_img=1:length(split_pos)-1
    subimg_clean{i_img} = imdilate(subimg_no_sl{i_img},se_line);
    
    %figure
    %imshow(subimg_clean{i_img})

end


%figure
%imshow(subimg_clean{1})

% Draw bounding boxes around note heads
%objects = [];
for i_img=1:length(split_pos)-1
    % Get all coherent regions
    L = bwlabel(subimg_clean{i_img});
    objects{i_img} = regionprops(L, 'BoundingBox');
    
    %figure
    %imshow(subimg_clean{i_img})

    for i = 1:length(locs_x{i_img})
        for k = 1:length(objects{i_img})
            bb = objects{i_img}(k).BoundingBox;
            % Find right bounding box for each note head
            if locs_x{i_img}(i) > bb(1) && locs_x{i_img}(i) < bb(1)+bb(3) && locs_y{i_img}(i) > bb(2) && locs_y{i_img}(i) < bb(2)+bb(4)
                % Draw and store bounding box
                %rectangle('Position',bb,'EdgeColor','green');                
                locs_bb{i_img}{i} = [bb(1), bb(2), bb(3), bb(4)];
            end
        end
    end
end

% Clean up everything except the notes
for i_img=1:length(split_pos)-1

   for k = 1:length(objects{i_img})
       bb_mat = cell2mat(locs_bb{i_img});
       bb = objects{i_img}(k).BoundingBox;
       if ~ (ismember(bb(2), bb_mat(2:4:end)) && ismember(bb(1), bb_mat(1:4:end)))
            subimg_clean{i_img}(round(bb(2)):round(bb(2)+bb(4)),round(bb(1)):round(bb(1)+bb(3))) = 0;
       end
   end

   %figure
   %imshow(subimg_clean{i_img})
end


%
% Check if multiple noteheads share bounding box and classify as eighth notes
locs_group_size = [];
for i_img=1:length(split_pos)-1
    bb_mat = cell2mat(locs_bb{i_img});
    for i = 1:length(locs_bb{i_img})
        locs_group_size{i_img}(i) = length(find(bb_mat(1:4:end) == locs_bb{i_img}{i}(1)));
    end
end

locs_eighth_note = [];
locs_fourth_note = [];
pks_temp = [];
for i_img=1:length(split_pos)-1
    locs_eighth_note{i_img} = zeros(1,length(locs_x{i_img}));
    locs_fourth_note{i_img} = zeros(1,length(locs_x{i_img}));
    
    bb_mat = cell2mat(locs_bb{i_img});

    for i = 1:length(locs_x{i_img})
        % Horizontal projection to classify note type
        x_min = floor(locs_bb{i_img}{i}(1));
        y_min = floor(locs_bb{i_img}{i}(2));
        width = floor(locs_bb{i_img}{i}(3));
        height = floor(locs_bb{i_img}{i}(4));

        i_group = find(bb_mat(1:4:end) == locs_bb{i_img}{i}(1));
        mean_y = mean(locs_y{i_img}(i_group));

        if mean_y > y_min+height/2
            tempimg = subimg_clean{i_img}(y_min:(round(locs_y{i_img}(i))-7), round(locs_x{i_img}(i))-10:round(locs_x{i_img}(i))+10);
            flag_size = mean(tempimg(:,end));

        else
            tempimg = subimg_clean{i_img}((round(locs_y{i_img}(i))+7):(y_min+height), round(locs_x{i_img}(i))-10:round(locs_x{i_img}(i))+10);
            flag_size = mean(tempimg(:,end-6));

        end
        
        % Single notes
        if locs_group_size{i_img}(i) == 1
            
            if flag_size < 0.2
                locs_fourth_note{i_img}(i) = true;
            elseif flag_size < 0.95
                locs_eighth_note{i_img}(i) = true;
            else
                locs_fourth_note{i_img}(i) = false;
                locs_eighth_note{i_img}(i) = false;
            end
            
        % Group notes
        else 
            %i
            beam_size = max(sum(tempimg(:,1)), sum(tempimg(:,end)))/length(tempimg(:,1));
            %figure
            %imshow(tempimg(:,:))
            if beam_size < 0.4
                locs_eighth_note{i_img}(i) = true;
            else
                locs_eighth_note{i_img}(i) = false;
                locs_fourth_note{i_img}(i) = false;        
            end
        end
    end
end



% Determine tones

notes = {'E4','D4','C4','B3','A3','G3','F3','E3','D3','C3','B2','A2','G2','F2','E2','D2','C2','B1','A1','G1'};
result = '';
diff = mean(diff(subimg_staff_lines{1}))/2;
for i_img=1:length(split_pos)-1
    
    ref_staff_line = subimg_staff_lines{i_img}(5);

    for i = 1:length(locs_y{i_img})
        distance = ref_staff_line-locs_y{i_img}(i);
        
        
        ref_note = 15;
        tone_distance = distance/diff;
        
        if tone_distance < ref_note && tone_distance > -5
            tone = notes{round(ref_note-tone_distance)}
        else
            locs_eighth_note{i_img}(i) = false;
            locs_fourth_note{i_img}(i) = false; 
        end
        
        
        if locs_eighth_note{i_img}(i)
            tone = lower(tone);
            result = strcat(result, tone);

        elseif locs_fourth_note{i_img}(i)
            result = strcat(result, tone);
        end

    end
    
    if i_img ~= length(split_pos)-1
        result = strcat(result, 'n');
    end
end

result