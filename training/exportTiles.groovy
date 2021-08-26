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

import qupath.lib.common.GeneralTools
import qupath.lib.images.ImageData
import qupath.lib.images.servers.ImageServerMetadata
import qupath.lib.images.servers.TransformedServerBuilder
import qupath.lib.images.writers.TileExporter
import javax.imageio.ImageIO 

// Get server and path
def server = getCurrentServer()
def serverPath = server.getPath()

// Define down-sampling and target path
def targetPath = 'PATH-TO-FILES'

// Define size of tiles
def downsampleFactor = 1.0
def cal = server.getPixelCalibration()
def mpp_x = cal.getPixelWidthMicrons()
def mpp_y = cal.getPixelHeightMicrons()

// Define target size of tiles in µm
def target_width_mic = 256
def target_width_px = Math.round(target_width_mic / mpp_x) as int 

// Pixel width and height in microns should be the same
if (mpp_x != mpp_y) {
    print("Image dimensions not equal! Mpp X != Y")
}


// Remove old tiles
removeObjects(getDetectionObjects(),true)

// Select all annotations to be exported
selectAnnotations()

// Create tiles form annotations
runPlugin('qupath.lib.algorithms.TilerPlugin', '{"tileSizeMicrons": ' + target_width_mic + ',  "trimToROI": false,  "makeAnnotations": false,  "removeParentAnnotation": false}');

// Create folders for tile classes
for (annotation in getAnnotationObjects()) {
    pathClass = annotation.getPathClass().getName().replace('*','')
    RMDir = new File("$targetPath/$pathClass")
    if(!RMDir.exists())
    {
        RMDir.mkdirs()
    }
}
print('Class folders created')

// Random name to be included into filename
String randomString 

// Export tiles
for (tile in getDetectionObjects()) {
    pathClass = tile.getParent().getPathClass().getName().replace('*','')
    roi = tile.getROI()
    x = roi.getBoundsX()
    y = roi.getBoundsY()
    print(roi.getBoundsWidth())
    if (roi.getBoundsWidth()!= target_width_px) {
        continue
    }
    if (roi.getBoundsWidth()!= roi.getBoundsHeight()) {
        continue
    }
    request = RegionRequest.createInstance(path, downsampleFactor, roi)
    imgTile = server.readBufferedImage(request)
    randomString = org.apache.commons.lang.RandomStringUtils.random(9, true, true);
    ImageIO.write(imgTile, 'png', new File(targetPath+'/'+pathClass,pathClass+'-'+randomString+'-'+x+'x'+y+'.png'))
}

print('Tiles exported!')
