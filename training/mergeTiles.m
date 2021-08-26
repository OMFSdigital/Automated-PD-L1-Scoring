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

% Select tiles
% Set tiles source LYM, STR or TUM
label = 'TUM';
tilesSource = ['PATH-TO-FOLDER',label,'\'];  
mergedTilesTarget = 'PATH-TO-FOLDER';
imdsAllTiles = imageDatastore(tilesSource,'IncludeSubfolders',false,'LabelSource','foldernames', 'ReadFcn',@normalizeImageSize);
 
% Merge tiles 12 x 12
mergedTiles = imtile(imdsAllTiles,'GridSize', [12 12]);
disp('Tiles successfully merged')

% Save tiles
mkdir(mergedTilesTarget);
t = Tiff(fullfile(mergedTilesTarget,strcat(label,'.tiff')),'w8');
tagstruct.ImageLength = size(mergedTiles,2);
tagstruct.ImageWidth = size(mergedTiles,1);
tagstruct.Photometric = Tiff.Photometric.RGB;
tagstruct.BitsPerSample = 8;
tagstruct.SamplesPerPixel = 3;
tagstruct.RowsPerStrip = 64;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.XResolution = 2;
tagstruct.YResolution = 2;
t.setTag(tagstruct);
t.write(mergedTiles);
t.close();

% Resize images
function data = normalizeImageSize(filename) 
    tmp = imread(filename);
    data = imresize(tmp, [512 512]);
end
