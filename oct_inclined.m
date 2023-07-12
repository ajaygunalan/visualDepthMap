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
firstFrameName = sprintf('octDeblurred.png', fileName);
saveas(gcf, fullfile(folderPath, firstFrameName));
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
firstFrameName = sprintf('oct.png', fileName);
saveas(gcf, fullfile(folderPath, firstFrameName));
close(gcf);