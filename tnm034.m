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

%imshow(image);


%% STAFF LINE IDENTIFICATION 

% Horizontal projection

bw = 1-im2bw(image, 0.8);
figure
plot(sum(bw,2), fliplr(1:size(bw,1)));
[pks, locs] = findpeaks(sum(bw,2));

% Remove all peaks less than half of maximum peak
tresh = pks > max(pks)/2;
locs = locs .* tresh;
pks = pks .* tresh;

pks_tresh = pks(pks~=0);
locs_tresh = locs(locs~=0);
cluster_i = kmeans(locs_tresh, 3);

%cluster = [locs_tresh, pks_tresh, cluster_i];

imshow(bw)
    hold on

% Print located staff lines
for i = 1:length(locs_tresh)
     
    p1 = [locs_tresh(i),0];
    p2 = [locs_tresh(i), pks_tresh(i)];
    
    if(cluster_i(i) == 1)
        plot([p1(2),p2(2)],[p1(1),p2(1)],'Color','r','LineWidth',2)
    elseif(cluster_i(i) == 2)
        plot([p1(2),p2(2)],[p1(1),p2(1)],'Color','g','LineWidth',2)
    elseif(cluster_i(i) == 3)
        plot([p1(2),p2(2)],[p1(1),p2(1)],'Color','b','LineWidth',2)
    end
        
    hold on    
end


