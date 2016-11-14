function [ staff_lines ] = staff_line_identification( bw_image )
% STAFF LINE IDENTIFICATION 
%   Inputs, binary image
%   Outputs, positions and cluster of the staff lines


    % Find locations using Horizontal projection
    figure
    plot(sum(bw_image,2), fliplr(1:size(bw_image,1)));
    [pks, locs] = findpeaks(sum(bw_image,2));

    % Remove all unrelevant peaks based on threshold
    % Can be improved by using cluster classification
    tresh = pks > max(pks)/3;
    locs = locs .* tresh;
    pks = pks .* tresh;

    pks_tresh = pks(pks~=0);
    locs_tresh = locs(locs~=0);
    staff_lines = [];

    % Classification of stafflines clusters
    if mod(length(locs_tresh), 5) == 0
        for i = 1:length(locs_tresh)
            staff_lines(i,1) = locs_tresh(i);
            staff_lines(i,2) = ceil(i/5);
        end
    end

end

