%% 1. Load the Data
clear all;
close all;
clc;
% Define the file path
folderPath = 'data/sample2';  
fileName = '0003.oct'; 
fullPath = fullfile(folderPath, fileName);
% Load the OCT Data
handle1 = OCTFileOpen(fullPath);
Intensity1 = OCTFileGetIntensity(handle1);
% Load depth image
frame1 = Intensity1;
figure; % Explicitly create a figure
im_obj1 = imagesc(frame1);
colormap gray;
axis off;
set(gca,'Position',[0 0 1 1]);
firstFrameName = sprintf('firstFrame_%s.png', fileName);
saveas(gcf, fullfile(folderPath, firstFrameName));
close(gcf);
savedImageFullPath = fullfile(folderPath, firstFrameName);
%% 2. Detect the ablate surface -> Binary, Dilate, Erode, edge, Contnour. 
depthI = imread(savedImageFullPath);

% Check if the image is RGB
if ndims(depthI) == 3
    % Convert RGB to grayscale
    depthI = rgb2gray(depthI);
end

% Convert the intensity data to binary image
BW = imbinarize(depthI, 'adaptive');

% Perform dilation + erosion to close gaps in between object edges
se = strel('disk',5);
BW = imdilate(BW,se);
BW = imerode(BW,se);

% Edge detection using Canny method
% Set thresholds for edge detection
lowerThreshold = 0.8; % Lower threshold for edge detection, can adjust this value
upperThreshold = 0.85; % Upper threshold for edge detection, can adjust this value
sigma = 2;

BW = edge(BW, 'Canny', [lowerThreshold upperThreshold], sigma);

% Find contours (boundaries in this case)
boundaries = bwboundaries(BW);
surface = cell(1, length(boundaries)); % Initialize surface as cell array

% Initialize a threshold for boundary size
sizeThreshold = 1000; % You can adjust this value

% Draw contours on a copy of the original frame
frame_contours = depthI;
surface_idx = 0; % Index to track contours added to surface
for k = 1:length(boundaries)
    boundary = boundaries{k};
    if length(boundary) > sizeThreshold
        surface_idx = surface_idx + 1;
        surface{surface_idx} = boundary;
        frame_contours(sub2ind(size(frame_contours), boundary(:,1), boundary(:,2))) = 255;
    end
end
surface = surface(1:surface_idx); % Remove unused cells

% Visualize the image with contours
figure;
imshow(frame_contours, []);
title('Contour Image');
%% 3. Approximate contour points with Line Segments
% Initialize cell array to hold the reduced surfaces and the ablate surfaces
surface_reduced = cell(1, surface_idx);
ablate_surface = cell(1, surface_idx); % Initialize ablate_surface cell array

% Loop over each surface
for idx = 1:surface_idx
    % Reduce the polygon using Douglas-Peucker algorithm
    tolerance = 0.02; % you can adjust this
    surface_reduced{idx} = reducepoly(surface{idx}, tolerance);
end

% Overlay the reduced surfaces on the original image
frame_contours_with_reduced = depthI;
ablate_surface_idx = 0; % Initialize ablate_surface index
for idx = 1:surface_idx
    % Calculate dx for the first line segment in the reduced surface
    dx = abs(surface_reduced{idx}(2,2) - surface_reduced{idx}(1,2));
    
    % If dx is less than 2, add the current contour to ablate_surface and skip to the next iteration
    if dx > 2
        ablate_surface_idx = ablate_surface_idx + 1;
        ablate_surface{ablate_surface_idx} = surface_reduced{idx};
        continue;
    end
    
    frame_contours_with_reduced(sub2ind(size(frame_contours_with_reduced), round(surface_reduced{idx}(:,1)), round(surface_reduced{idx}(:,2)))) = 255;
end

% Visualize the image with reduced contours
figure;
imshow(frame_contours_with_reduced, []);
hold on;

% Draw each ablate surface
for idx = 1:ablate_surface_idx
    line(ablate_surface{idx}(:,2), ablate_surface{idx}(:,1), 'color','r','linewidth',1.5,'marker','o','markersize',5);
    
    % Annotate the surface with surface_idx value
    mid_point = round(size(ablate_surface{idx}, 1)/2);
    text(ablate_surface{idx}(mid_point, 2), ablate_surface{idx}(mid_point, 1), num2str(idx), 'Color', 'yellow', 'FontSize', 14);
end

title('Original and Ablate Contour Image');
%% 4. Combine the contour and find depth
% Filter out empty matrices
ablate_surface = ablate_surface(~cellfun(@isempty, ablate_surface));

% Concatenate all the ablate_surface into one list
all_surfaces = vertcat(ablate_surface{:});

% Apply reducepoly function
tolerance = 0.002;  % Set the tolerance
reduced_all_surfaces = reducepoly(all_surfaces, tolerance);

% Sort reduced_all_surfaces by the x-coordinate (column 2) in increasing order
reduced_all_surfaces = sortrows(reduced_all_surfaces, 2);

% Get the first two and last two points from reduced_all_surfaces
first_two_points = reduced_all_surfaces(1:2,:);
last_two_points = reduced_all_surfaces(end-1:end,:);
top_layer_points = [first_two_points; last_two_points];

% Define threshold and filter depth_points based on change in x-coordinate
threshold = 10; % Set your threshold
depth_points = reduced_all_surfaces(3:end-2,:);
dX = [threshold+1; abs(diff(depth_points(:, 2)))]; % Calculate dX, ensuring first point is kept
depth_points = depth_points(dX > threshold, :);

% Combine these points back into one array
reduced_all_surfaces = [first_two_points; depth_points; last_two_points];

% Calculate the slope and intercept of the Top Layer line
slope = (last_two_points(2,1) - first_two_points(1,1)) / (last_two_points(2,2) - first_two_points(1,2));
intercept = first_two_points(1,1) - slope * first_two_points(1,2);

% Calculate the vertical distances from depth_points to the Top Layer line
vertical_distances = abs(slope * depth_points(:,2) - depth_points(:,1) + intercept) / sqrt(slope^2 + 1);

% Create a copy of the original image to plot on
overlay_image = depthI;

% Overlay the original and reduced contours on the image
figure;
imshow(overlay_image, []);
hold on;

numSurfaces = numel(ablate_surface); % Compute once outside loop

% Plot the reduced all surfaces
line(reduced_all_surfaces(:,2), reduced_all_surfaces(:,1), 'color', 'r', 'marker', 'o');

% Draw the line representing the "Top Layer"
line(top_layer_points(:,2), top_layer_points(:,1), 'color', 'g', 'LineWidth', 2);

% Plot the vertical distances from depth_points to the Top Layer line
numDepthPoints = size(depth_points, 1); % Compute once outside loop
for i = 1:numDepthPoints
    line([depth_points(i,2), depth_points(i,2)], [depth_points(i,1), depth_points(i,1) - vertical_distances(i)], 'color', 'y', 'LineWidth', 1);
end

% Set title
title('Ablated Surfaces (Red), Top Layer (Green), and Vertical Distances (Yellow) on Depth Image');

% Keep the hold off
hold off;

% Initialize an array to hold x-coordinates and vertical distances
x_coords_vertical_distances = zeros(size(reduced_all_surfaces, 1), 2);

% Store x-coordinates
x_coords_vertical_distances(:, 1) = reduced_all_surfaces(:, 2);

% Calculate vertical distances for depth points
numDepthPoints = size(depth_points, 1); % Compute once outside loop
for i = 1:numDepthPoints
    x_coords_vertical_distances(i+2, 2) = abs(slope * depth_points(i,2) - depth_points(i,1) + intercept) / sqrt(slope^2 + 1);
end

pts = x_coords_vertical_distances(:, 1);
depth = x_coords_vertical_distances(:, 2);
%% 5. Register with RGB Image
% Fetch the RGB image from the OCT file
VideoImage1 = OCTFileGetColoredData(handle1, 'VideoImage');

% Save the image with a dynamic filename
VideoImageName = sprintf('VideoImage_%s.png', fileName);
imwrite(VideoImage1, fullfile(folderPath, VideoImageName));

% Display RGB image
figure;
imshow(VideoImage1);
title('Select two points representing the scanner path. Press enter when done.');

% User selects two points on RGB image
[rgbX, rgbY] = ginput(2);

% Define start and end points for the RGB image
startPt = [rgbX(1), rgbY(1)];
endPt = [rgbX(2), rgbY(2)];

% Compute the distance between the start and end points in the RGB image
distRGB = sqrt((endPt(1)-startPt(1))^2 + (endPt(2)-startPt(2))^2);

% Compute the scaling factor
scalingFactor = distRGB / sum(pts);

% Calculate the slope (m) and y-intercept (b) of the line
slope = (endPt(2) - startPt(2)) / (endPt(1) - startPt(1));
intercept = startPt(2) - slope * startPt(1);

% Display the equation of the line
disp(['Equation of the line: y = ' num2str(slope) 'x + ' num2str(intercept)]);

% Compute the normalized direction vector for the line
directionVector = [endPt(1) - startPt(1), endPt(2) - startPt(2)];
directionVector = directionVector / norm(directionVector);

% Initialize a variable to hold the coordinates of the points to be plotted
plotPoints = startPt;
depthColors = [];

% For each distance in 'pts', compute the corresponding point on the line
for i = 1:numel(pts)
    % Compute the displacement from the last point
    displacement = directionVector * pts(i) * scalingFactor;
    
    % Compute the new point and add it to the list
    newPoint = plotPoints(end,:) + displacement;
    
    % Check if the new point is beyond the end point
    if norm(newPoint - startPt) > distRGB
        break;
    end
    
    % Add the new point to the list
    plotPoints = [plotPoints; newPoint];
    depthColors = [depthColors; depth(i)];
end

% Ensure depthColors and plotPoints have the same length
if length(depthColors) < size(plotPoints, 1)
    depthColors = [depthColors; repmat(depthColors(end), size(plotPoints, 1) - length(depthColors), 1)];
elseif length(depthColors) > size(plotPoints, 1)
    depthColors = depthColors(1:size(plotPoints, 1));
end

% Draw a line segment between the selected points
hold on;
line(rgbX, rgbY, 'Color', 'k', 'LineWidth', 2);

% Plot the generated points on the line with colors representing depth
scatter(plotPoints(:,1), plotPoints(:,2), 36, depthColors, 'filled');
colorbar;
colormap('jet');

%%



























%% 5. Register with RGB Image
% Fetch the RGB image from the OCT file
VideoImage1 = OCTFileGetColoredData(handle1, 'VideoImage');

% Save the image with a dynamic filename
VideoImageName = sprintf('VideoImage_%s.png', fileName);
imwrite(VideoImage1, fullfile(folderPath, VideoImageName));

% Display RGB image
figure;
imshow(VideoImage1);
title('Select two points representing the scanner path. Press enter when done.');

% User selects two points on RGB image
[rgbX, rgbY] = ginput(2);
%%
% Define start and end points for the RGB image
startPt = [rgbX(1), rgbY(1)];
endPt = [rgbX(2), rgbY(2)];

% Define start and end points for the RGB image
startPt = [rgbX(1), rgbY(1)];
endPt = [rgbX(2), rgbY(2)];

% Compute the distance between the start and end points in the RGB image
distRGB = sqrt((endPt(1)-startPt(1))^2 + (endPt(2)-startPt(2))^2);

% Define start and end points for the depth image
startPt_depth = reduced_all_surfaces(1, :);
endPt_depth = reduced_all_surfaces(end, :);

% Compute the distance between the start and end points in the depth image
distDepth = sqrt((endPt_depth(1)-startPt_depth(1))^2 + (endPt_depth(2)-startPt_depth(2))^2);

% Compute the scaling factor
scalingFactor = distRGB / distDepth;

% Calculate the slope (m) and y-intercept (b) of the line
slope = (endPt(2) - startPt(2)) / (endPt(1) - startPt(1));
intercept = startPt(2) - slope * startPt(1);

% Display the equation of the line
disp(['Equation of the line: y = ' num2str(slope) 'x + ' num2str(intercept)]);

% Compute the normalized direction vector for the line
directionVector = [endPt(1) - startPt(1), endPt(2) - startPt(2)];
directionVector = directionVector / norm(directionVector);

% Initialize a variable to hold the coordinates of the points to be plotted
plotPoints = startPt;

% For each distance in 'pts', compute the corresponding point on the line
for i = 1:numel(pts)
    % Compute the displacement from the last point
    displacement = directionVector * pts(i) * scalingFactor*0.1;
    
    % Compute the new point and add it to the list
    newPoint = plotPoints(end,:) + displacement;
    
    % Add the new point to the list
    plotPoints = [plotPoints; newPoint];
end

% Draw a line segment between the selected points
hold on;
line(rgbX, rgbY, 'Color', 'k', 'LineWidth', 3);

% Plot the generated points on the line
scatter(plotPoints(:,1), plotPoints(:,2), 'y');
hold off;

% Force MATLAB to update the figure immediately
drawnow;

% Save selected points
rgbPoints = [rgbY, rgbX];  % Note the swap in X and Y coordinates. ginput() returns [x,y] but the image coordinate system is [row=y, col=x].



%% 5. Register with RGB Image
% Fetch the RGB image from the OCT file
VideoImage1 = OCTFileGetColoredData(handle1, 'VideoImage');

% Save the image with a dynamic filename
VideoImageName = sprintf('VideoImage_%s.png', fileName);
imwrite(VideoImage1, fullfile(folderPath, VideoImageName));

% Display RGB image
figure;
imshow(VideoImage1);
title('Select two points representing the scanner path. Press enter when done.');

% User selects two points on RGB image
[rgbX, rgbY] = ginput(2);

% Define start and end points for the RGB image
startPt = [rgbX(1), rgbY(1)];
endPt = [rgbX(2), rgbY(2)];

% Calculate the slope (m) and y-intercept (b) of the line
slope = (endPt(2) - startPt(2)) / (endPt(1) - startPt(1));
intercept = startPt(2) - slope * startPt(1);

% Display the equation of the line
disp(['Equation of the line: y = ' num2str(slope) 'x + ' num2str(intercept)]);

% Generate x coordinates between the start and end points
x_coords = linspace(startPt(1), endPt(1), size(pts, 1));  % The third argument now equals the number of elements in 'pts'

% Calculate the corresponding y coordinates using the equation of the line
y_coords = slope * x_coords + intercept;

% Draw a line segment between the selected points
hold on;
line(rgbX, rgbY, 'Color', 'k', 'LineWidth', 3);

% Plot the generated points on the line
scatter(x_coords, y_coords, 'y');
hold off;

% Force MATLAB to update the figure immediately
drawnow;

% Save selected points
rgbPoints = [rgbY, rgbX];  % Note the swap in X and Y coordinates. ginput() returns [x,y] but the image coordinate system is [row=y, col=x].
%% 7. Apply scale and offset
% Define the x and y offsets
xOffset = rgbX(1) - scalingFactor * pts(1);
yOffset = rgbY(1) - scalingFactor * depth(1);

% Create a new matrix to hold the scaled points
scaled_pts = pts * scalingFactor;
scaled_depth = depth * scalingFactor;

% Calculate the number of points
num_pts = length(pts);

% Calculate normalized depth values for color coding (assuming depth values are positive)
normalized_depth = scaled_depth - min(scaled_depth);
normalized_depth = normalized_depth / max(normalized_depth);

% Generate the line segment
linSegX = linspace(startPt(1), endPt(1), num_pts);
linSegY = linspace(startPt(2), endPt(2), num_pts);

% Add the offsets and scale to the depth points
offset_scaled_pts = [scaled_pts + xOffset, scaled_depth + yOffset];

% Visualize the offset and scaled points on the RGB image
figure; imshow(VideoImage1); hold on;

for i = 1:num_pts
    % Draw a filled circle at each point along the line
    % The color of the circle corresponds to the depth at that point
    scatter(linSegX(i), linSegY(i), 36, [1, 1-normalized_depth(i), 1-normalized_depth(i)], 'filled');
end

title('Offset and Scaled Depth Points on RGB Image');
hold off;



% %% 6. Compute distances and scale
% % Compute distances between the selected points in both images
% pts_distance = pdist(pts([1,end], :), 'euclidean');
% rgb_distance = pdist([rgbPoints(1,:); rgbPoints(2,:)], 'euclidean');
% 
% % Compute scaling factor
% scalingFactor = rgb_distance / pts_distance;\






%% 6. Feature matching and image alignment
% Create a geometric transformation that maps the depth image to the RGB image
tform = fitgeotrans(depthPoints, rgbPoints, 'NonreflectiveSimilarity');

% Apply the transformation to the depth points
depth_points_transformed = transformPointsForward(tform, depth_points);

%% 7. Overlay depth points on the RGB image
% Now, the transformed depth points can be overlaid on the RGB image as before

% Normalize the vertical distances
vertical_distances_normalized = (vertical_distances - min(vertical_distances)) / (max(vertical_distances) - min(vertical_distances));

%Create a colormap
colormap_depth = jet(256);
VideoImage1_depth = VideoImage1;
for i = 1:size(depth_points_transformed, 1)
    position = fliplr(depth_points_transformed(i, :));  % flip x and y coordinates
    index = max(round(vertical_distances_normalized(i)*255)+1, 1);  % ensure index is always at least 1
    color = colormap_depth(index, :);  % get the color from the colormap
    VideoImage1_depth = insertShape(VideoImage1_depth, 'FilledCircle', [position, 5], 'Color', color*255, 'Opacity', 1);  % draw a filled circle with a radius of 5 pixels
end

% Show the RGB image with depth overlay
figure;
imshow(VideoImage1_depth);
title('RGB Image with Depth Overlay');


