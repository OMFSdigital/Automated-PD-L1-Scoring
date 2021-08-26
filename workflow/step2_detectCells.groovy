/* Automated PD-L1 scoring of TPS, CPS, and ICS in whole slide images in a MATLAB/QuPath workflow
   Copyright (C) 2020-2021 Behrus Puladi
   https://orcid.org/0000-0001-5909-6105
   
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. */

import qupath.tensorflow.stardist.StarDist2D

//  Set model folder for pretrained StarDist model
def pathModel = QPEx.buildFilePath(QPEx.PROJECT_BASE_DIR, 'models/he_heavy_augment')

// Define StarDist model
def stardist = StarDist2D.builder(pathModel)
    .threshold(0.5)
    .normalizePercentiles(1, 99)
    .pixelSize(0.5)
    .cellExpansion(5.0)
    .measureShape()
    .measureIntensity()
    .includeProbability(true)
    .nThreads(16)    
    .build()

// Run cell detection for the annotations 
def imageData = getCurrentImageData()
selectAnnotations()
def pathObjects = getSelectedObjects()
stardist.detectObjects(imageData, pathObjects)

// Apply the changes
fireHierarchyUpdate()
