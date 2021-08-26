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

% Set tiles source
tilesSource = 'PATH-TO-FOLDER';  
imdsAllTiles = imageDatastore(tilesSource,'IncludeSubfolders',true,'LabelSource','foldernames','ReadFcn',@deconvolveImage);

% Select a subset (n = 5000) of tile images
numTiles = 5000;
imdsSelectedTiles = splitEachLabel(imdsAllTiles,numTiles,'randomize','Exclude','EXCLUDED');

% Save tiles into following path
writeall(imdsSelectedTiles,'PATH-TO-FOLDER\');

% Extract the haematoxylin channel
function [H] = deconvolveImage(filename)
I = imread(filename);
stains = Deconvolve( I, [], 0 );
[H] = PseudoColourStains( stains, [] );
end
