% Automated PD-L1 scoring of TPS, CPS, and ICS in whole slide images in a MATLAB/QuPath workflow
% Copyright (C) 2020-2021 Behrus Puladi
% https://orcid.org/0000-0001-5909-6105
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

% Reset MATLAB
clear; close all; clc;
 
% Load trained network
load('./models/HNSCC-shufflenet-8-CLASSES.mat');

% Set input size
inputSize = 224; % pixel
target_size_mc = 256; % µm

% Set WI folder
pathWSI = 'PATH-TO-FILE';
ImageStore = dir([pathWSI,'**\*.ndpi']);

% Create folder for results if not exist
if not(isfolder('results'))
    mkdir('results');
end 

% Process all WSIs
for i=1:numel(ImageStore)
    % Get WSI names
    currentWSI.name = ImageStore(i).name;
    currentWSI.folder = ImageStore(i).folder;
    currentWSI.path = [currentWSI.folder,'\',currentWSI.name];
    disp(currentWSI.name)

    % Load WSI with internal 
    WSI_openSlide = openSlideAdapter(currentWSI.path,1);
    WSI_bim = bigimage(currentWSI.path);
    tileSize = [round(target_size_mc/WSI_openSlide.Properties.mppX),round(target_size_mc/WSI_openSlide.Properties.mppY)]
    
    % Exclude background areas in the WSI to accelerate subsequent tumor annotation.
    clevel = 3;
    clevelLims = WSI_bim.SpatialReferencing(clevel);
    imcoarse = getFullLevel(WSI_bim,clevel);
    graycoarse = rgb2gray(imcoarse);
    graycoarse(graycoarse < 64) = 255;
    bwcoarse = imbinarize(graycoarse,0.85);
    binMask = imcomplement(bwcoarse);
    binMask = bigimage(binMask,'SpatialReferencing',clevelLims);
    t = 0.1;     
    tileSet = selectBlockLocations(WSI_bim,"BlockSize",tileSize, ... 
    	"Masks",binMask,"InclusionThreshold",t);   
    
    % Annotate the WSI in a sliding window manner
    labelFun = @(tile) labelTiles(tile,tileSet,trainedNet,inputSize);
	labelmap = blockproc(WSI_openSlide,tileSize,labelFun,'UseParallel',false);
    
    % Convert prediction map into binary labelmap, 8 for TUM
    binLabelmap = labelmap;
    binLabelmap(binLabelmap~=8) = 0;
    binLabelmap(binLabelmap==8) = 1;

    % Remove small and defragmented annotations
    binLabelmap = bwmorph(binLabelmap,'clean');
    binLabelmap = bwmorph(binLabelmap,'close');
    binLabelmap = bwmorph(binLabelmap,'open');
    binLabelmap = uint8(binLabelmap*255); 

    % Save binary labelmap as an image file to be imported into QuPath
    labelmapDownsample = target_size_mc/WSI_openSlide.Properties.mppX;
    wsiWidth = max(tileSet.BlockOrigin(:,1))+tileSet.BlockSize(1);
    wsiHeight = max(tileSet.BlockOrigin(:,2))+tileSet.BlockSize(2);
    labelMapFilename = [currentWSI.name,'_','TUM','_','(',num2str(labelmapDownsample),',',...
        '0,0,',num2str(wsiWidth),',',num2str(wsiHeight),')-labelmap','.png'];
    imwrite(binLabelmap,['.\results\',labelMapFilename],'BitDepth',8)
end
