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

%% Remove staff lines

bw_no_sl = bw

for i=1:length(staff_lines(:,1))
    bw_no_sl(staff_lines(i,1)-1, :) = 0;
    bw_no_sl(staff_lines(i,1), :) = 0;
    bw_no_sl(staff_lines(i,1)+1, :) = 0;
end

figure;
imshow(bw_no_sl)

% Expand objects to clean up holes etc
%se_line = strel('line', 4, 90);
%bw = imdilate(bw,se_line);
%locations = [locs_y{3}(:), locs_x{3}(:)]
%BW2 = imfill(logical(notes_row{3}), locations, 8)
%imshow(BW2)

%% Divide into subimages for each row block

split_pos(1) = 70;
for i=5:5:length(staff_lines(:,1))-1
    split_pos(end+1) = ceil(staff_lines(i,1) + ((staff_lines(i+1,1) - staff_lines(i,1)) / 2));
end
split_pos(end+1) = length(bw(:,1))-20;


%% Detect note heads

se_disk = strel('disk', 4);

notes_row = [];
subimg = [];
locs_x = [];
locs_y = [];
for i=1:length(split_pos)-1
    notes_row{i} = bw(split_pos(i):split_pos(i+1),:);
    
    subimg{i} = imerode(notes_row{i},se_disk);
    overlay1 = imoverlay(notes_row{i}, subimg{i}, [.3 1 .3]);
    figure;
    imshow(overlay1);
    
    [pks, locs_x{i}] = findpeaks(sum(subimg{i},1));
    
    locs_y{i} = [];
    for j = 1:length(locs_x{i})
        temp = subimg{i}(:, locs_x{i}(j)-2:locs_x{i}(j)+2);
        [pks, lo] = findpeaks(sum(temp,2));
        indexOfMaxValue = find(pks == max(pks));
        locs_y{i}(j) = lo(indexOfMaxValue(1));
    end
    
    %figure 
    %imshow(notes_row{i})
end 

%% Map staff lines to block rows

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

figure
imshow(notes_row{3})

%% Highlight note heads

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
    
%% Highlight note heads / fill after removal of stafflines

bw2 = imfill(notes_row{1},'holes');
bw3 = imopen(bw2, ones(2,2));
bw4 = bwareaopen(bw2, 5);
bw4_perim = bwperim(bw4);
imshow(bw4_perim)
overlay1 = imoverlay(notes_row{1}, bw4_perim, [.3 1 .3]);
%imshow(overlay1)

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

