function [ locs_fourth_note, locs_eighth_note ] = get_note_type( locs_x, locs_y, locs_bb, locs_group_size, subimg_clean, n )
% GET NOTE TYPE 
%   Inputs, locations of notes and their boundingboxes and clean subimages
%   Outputs, the type of the notes

    locs_eighth_note = [];
    locs_fourth_note = [];
    pks_temp = [];
    for i_img=1:n
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
                tempimg = subimg_clean{i_img}(y_min:(round(locs_y{i_img}(i))-7),...
                    round(locs_x{i_img}(i))-10:round(locs_x{i_img}(i))+10);
                flag_size = mean(tempimg(:,end));

            else
                tempimg = subimg_clean{i_img}((round(locs_y{i_img}(i))+7):(y_min+height),...
                    round(locs_x{i_img}(i))-10:round(locs_x{i_img}(i))+10);
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
                beam_size = max(sum(tempimg(:,1)), sum(tempimg(:,end)))/length(tempimg(:,1));
                
                % Print the cropped bounding box
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
end

