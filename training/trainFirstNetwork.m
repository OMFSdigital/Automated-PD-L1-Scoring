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

% Externally used functions
% edit(fullfile(matlabroot,'examples','nnet','main','freezeWeights.m'))
% edit(fullfile(matlabroot,'examples','nnet','main','createLgraphUsingConnections.m'))

% Reset MATLAB
clear; close all; clc;

% Choose training data
% Set the folder with the tile images for training
trainingTilesPath = 'PATH-TO-FOLDER';  

% Load the tile images as data storage for images. The subfolders correspond 
% to the individual classes that can be recognized.
imdsAllTiles = imageDatastore(trainingTilesPath,'IncludeSubfolders',true,'LabelSource','foldernames');

% Splitting the data into training, validation and test data. Training and 
% validation data are used to train the network and the test is used to 
% evaluate the network at the end.
[imdsTrainingTiles, imdsValidationTiles, imdsTestingTiles] = splitEachLabel(imdsAllTiles,.7,.15,.15);

numberOutputClasses = numel(unique(imdsTrainingTiles.Labels));

% Modify pretrained CNN for transfer learning
% Choose pretrained CNN and get input size of the choosen CNN
pretrainedNet = shufflenet;
inputSize = pretrainedNet.Layers(1).InputSize(1:2);

% Freeze first 30 layer by setting the learning rates to zero
lgraph = layerGraph(pretrainedNet);
layers = lgraph.Layers;
connections = lgraph.Connections;
freezeIndex = 1:(numel(layers)-30);
layers(freezeIndex) = freezeWeights(layers(freezeIndex));
lgraph = createLgraphUsingConnections(layers,connections);

% Modification of the output layer to match the training data for shufflenet
layersToRemove = {'node_202', 'node_203','ClassificationLayer_node_203'};
layersToReconnect = {'node_200','fc'};
lgraph = removeLayers(lgraph,layersToRemove);
newLayers = [fullyConnectedLayer(numberOutputClasses,'Name','fc','WeightLearnRateFactor', 2,'BiasLearnRateFactor', 2),...
             softmaxLayer('Name','softmax'),...
             classificationLayer('Name','classoutput')];
lgraph = addLayers(lgraph,newLayers);
modifiedNet = connectLayers(lgraph,layersToReconnect{1},layersToReconnect{2});

% Augmentation of the training data 
augmentTiles = imageDataAugmenter('FillValue',255,...
    'RandXReflection',true,'RandYReflection',true,...
    'RandXTranslation',[-5,5],'RandYTranslation',[-5,5],...
    'RandXShear',[-5,5],'RandYShear',[-5,5]);

% Prepare training data
imdsAugmentedTrainingTiles = augmentedImageDatastore(inputSize,imdsTrainingTiles,'DataAugmentation',augmentTiles);
imdsAugmentedValidationTiles = augmentedImageDatastore(inputSize,imdsValidationTiles,'DataAugmentation',augmentTiles);
imdsAugmentedTestingTiles = augmentedImageDatastore(inputSize,imdsTestingTiles,'DataAugmentation',augmentTiles);

% Training of the modified CNN
% Hyperparamters for training
options  = trainingOptions('adam');
options.GradientDecayFactor = 0.9;
options.SquaredGradientDecayFactor = 0.999; %
options.Epsilon = 1e-8;
options.MaxEpochs = 8;
options.MiniBatchSize = 256;
options.ValidationPatience = 5;
options.Plots = 'training-progress';
options.Verbose = true;
options.ValidationData = imdsAugmentedValidationTiles;
 
% Train the modified CNN
[trainedNet, trainingInfo] = trainNetwork(imdsAugmentedTrainingTiles, modifiedNet, options);

% Test and save trained Network
% Train network
[YPred,scores] = classify(trainedNet, imdsAugmentedTestingTiles);

% Show confusion matrix
plotconfusion(imdsTestingTiles.Labels,YPred);

%
% Create folder models if not exist
if not(isfolder('models'))
    mkdir('models');
end 

% Save trained network into a file
save(['./models/trainedNet',...
    '-D',datestr(now,'yyyy-mm-dd'),...
    '-T',datestr(now,'HH-MM'),...
    '-NumClass-',num2str(numberOutputClasses),...
    '.mat'],'trainedNet');
 
