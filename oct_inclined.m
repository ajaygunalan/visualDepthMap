%% 1. Load the Data
clear all;
close all;
clc;
% Define the file path
folderPath = 'data/oct_inclinded/badcut';  
fileName = '21-03-19_OE_Calibration_0001_Mode2D.oct';
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
firstFrameName = sprintf('octWYS.png', fileName);
saveas(gcf, fullfile(folderPath, firstFrameName));
savedImageFullPath1 = fullfile(folderPath, firstFrameName);
close(gcf);


folderPath = 'data/oct_inclinded/badcut';  
fileName = '21-03-19_OE_Calibration_0022_Mode2D.oct';
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
firstFrameName = sprintf('octTrue.png', fileName);
saveas(gcf, fullfile(folderPath, firstFrameName));
savedImageFullPath2 = fullfile(folderPath, firstFrameName);
close(gcf);
%%
% Read the image
depthWYS = imread(savedImageFullPath1);

% Create a figure and an axes to hold the image
fig = figure;
ax = axes('Parent', fig);
imgHandle = imshow(depthWYS, 'Parent', ax);

% Create a coarse slider control
sliderCoarse = uicontrol('Parent', fig, 'Style', 'slider', 'Position', [150, 5, 300, 20],...
    'value', 0, 'min', -180, 'max', 180);

% Create a fine slider control
sliderFine = uicontrol('Parent', fig, 'Style', 'slider', 'Position', [150, 35, 300, 20],...
    'value', 0, 'min', -1, 'max', 1);

% Store the image data, handle, and sliders using guidata
handles = guidata(fig);
handles.depthWYS = depthWYS;
handles.imgHandle = imgHandle;
handles.sliderCoarse = sliderCoarse;
handles.sliderFine = sliderFine;
guidata(fig, handles);

% Add a listener to the sliders
addlistener(sliderCoarse, 'ContinuousValueChange', @(src, event) rotateImage(fig));
addlistener(sliderFine, 'ContinuousValueChange', @(src, event) rotateImage(fig));

% Nested function to rotate and display the image
function rotateImage(fig)
    % Retrieve the image data, handle, and sliders from guidata
    handles = guidata(fig);
    depthWYS = handles.depthWYS;
    imgHandle = handles.imgHandle;
    sliderCoarse = handles.sliderCoarse;
    sliderFine = handles.sliderFine;

    % Get the values from both sliders
    angleCoarse = get(sliderCoarse, 'Value');
    angleFine = get(sliderFine, 'Value');

    % Combine the values of the two sliders to determine the rotation angle
    angle = angleCoarse + angleFine;

    % Rotate the image and update the display
    rotatedImage = imrotate(depthWYS, angle, 'bicubic', 'crop');
    set(imgHandle, 'CData', rotatedImage);
    title(['Rotation Angle: ', num2str(angle)]);
end


%%

% % Read the images
% depthWYS = imread(savedImageFullPath1);
% depthTrue = imread(savedImageFullPath2);
% 
% % Convert the images to double precision
% depthWYS = im2double(depthWYS);
% depthTrue = im2double(depthTrue);
% 
% % Convert the images to grayscale if they are color images
% if size(depthWYS, 3) > 1
%     depthWYS = rgb2gray(depthWYS);
% end
% if size(depthTrue, 3) > 1
%     depthTrue = rgb2gray(depthTrue);
% end
% 
% % Compute the Fourier Transform of the images
% depthWYS_FT = fft2(depthWYS);
% depthTrue_FT = fft2(depthTrue);
% 
% % Regularization constant to avoid division by zero
% epsilon = 1e-6;
% 
% % Estimate the PSF in the Fourier domain
% psf_FT = depthWYS_FT ./ (depthTrue_FT + epsilon);
% 
% % Compute the inverse Fourier Transform to get the PSF in the spatial domain
% estimated_psf = ifft2(psf_FT);
% 
% % Convolve the original image with the estimated PSF
% reblurred = conv2(depthTrue, abs(estimated_psf), 'same');
% 
% % Compute the Mean Squared Error between the reblurred image and the original blurred image
% mse = immse(reblurred, depthWYS);
% 
% % Display the results
% figure, imshow(depthWYS), title('Original Blurred Image');
% figure, imshow(abs(reblurred)), title('Reblurred Image with Estimated PSF');
% fprintf('The Mean Squared Error is %0.4f\n', mse);




