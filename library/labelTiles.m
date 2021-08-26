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

function label = labelTiles(tile,tileSet,trainedNet,inputSize)

% Filter all image tiles, which are not in tileSet
if ismember(flip(tile.location),tileSet.BlockOrigin,'rows')
    
    % Changing the image size to the target size of the trained network
    resizedTile = imresize(tile.data,[inputSize,inputSize]);
  
    % Extract the hematoxylin channel
    Hematoxylin_DAB = [0.651 0.701 0.29; 0.269 0.568 0.778;];
    [deconvolvedTile] = PseudoColourStains(Deconvolve(resizedTile,[],0),Hematoxylin_DAB);
    
    % Classify image tile
    [YPred,scores] = classify(trainedNet, deconvolvedTile);
    switch char(YPred)
        case char('ADI')
            label = 1;
        case char('CHR')
            label = 2;    
        case char('EPI')           
            label = 3;
        case char('GLD')
            label = 4;        
        case char('LYM')
            label = 5;        
        case char('MUS')
            label = 6;  
        case char('STR')
            label = 7;              
        case char('TUM')
            label = 8;  
        otherwise
            label = 9;
    end
else
    label = 0;
end
end
