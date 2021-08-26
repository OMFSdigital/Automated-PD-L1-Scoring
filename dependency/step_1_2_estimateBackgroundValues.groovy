/** 
 * Script to estimate the background value in a brightfield whole slide image. 
 * 
 * This effectively looks for the circle of a specified radius with the highest 
 * mean intensity (summed across all 3 RGB channels), and takes the mean red, 
 * green and blue within this circle as the background values. 
 * 
 * The background values are then set in the ColorDeconvolutionStains object 
 * for the ImageData, so that they are used for any optical density calculations. 
 * 
 * This is implemented with the help of ImageJ (www.imagej.net). 
 * 
 * @author Pete Bankhead 
 * @modfied Behrus Puladi
 */ 
 
import ij.plugin.filter.RankFilters 
import ij.process.ColorProcessor 
import qupath.imagej.tools.IJTools
import qupath.lib.common.ColorTools 
import qupath.lib.regions.RegionRequest 
import qupath.lib.scripting.QP 
 import qupath.lib.images.PathImage
 
// Radius used for background search, in microns (will be used approximately) 
double radiusMicrons = 1000 
 
// Calculate a suitable 'preferred' pixel size 
// Keep in mind that downsampling involves a form of smoothing, so we just choose 
// a reasonable filter size and then adapt the image resolution accordingly 
double radiusPixels = 10 
double requestedPixelSizeMicrons = radiusMicrons / radiusPixels 
 
// Get the ImageData & ImageServer 
def imageData = QP.getCurrentImageData() 
def server = imageData.getServer() 
 
// Check we have the right kind of data 
if (!imageData.isBrightfield() || !server.isRGB()) { 
    print("ERROR: Only brightfield RGB images can be processed with this script, sorry") 
    return 
} 
 
// Extract pixel size 
double pixelSize = server.getPixelCalibration().getAveragedPixelSizeMicrons() 
// Choose a default if we need one (i.e. if the pixel size is missing from the image metadata) 
if (Double.isNaN(pixelSize)) 
    pixelSize = 0.5 

// Figure out suitable downsampling value 
double downsample = Math.round(requestedPixelSizeMicrons / pixelSize) 
 
// Get a downsampled version of the image as an ImagePlus (for ImageJ) 
def request = RegionRequest.createInstance(server.getPath(), downsample, 0, 0, server.getWidth(), server.getHeight()) 
//def serverIJ = ImagePlusServerBuilder.ensureImagePlusWholeSlideServer(server) 
//def ImageServer<BufferedImage> serverIJ = QP.getCurrentImageData().getServer()
def imp = IJTools.convertToImagePlus(server, request).getImage()

def ip = imp.getProcessor() 
if (!(ip instanceof ColorProcessor)) { 
    print("Sorry, the background can only be set for a ColorProcessor, but the current ImageProcessor is " + ip) 
    return 
} 
 
// Apply filter 
if (ip.getWidth() <= radiusPixels*2 || ip.getHeight() <= radiusPixels*2) { 
    print("The image is too small for the requested radius!") 
    return 
} 
new RankFilters().rank(ip, radiusPixels, RankFilters.MEAN) 
 
// Find the location of the maximum across all 3 channels 
double maxValue = Double.NEGATIVE_INFINITY 
double maxRed = 0 
double maxGreen = 0 
double maxBlue = 0 
for (int y = radiusPixels; y < ip.getHeight()-radiusPixels; y++) { 
    for (int x = radiusPixels; x < ip.getWidth()-radiusPixels; x++) { 
        int rgb = ip.getPixel(x, y) 
        int r = ColorTools.red(rgb) 
        int g = ColorTools.green(rgb) 
        int b = ColorTools.blue(rgb) 
        double sum = r + g + b 
        if (sum > maxValue) { 
            maxValue = sum 
            maxRed = r 
            maxGreen = g 
            maxBlue = b 
        } 
    } 
} 
 
// Print the result 
print("Background RGB values: " + maxRed + ", " + maxGreen + ", " + maxBlue) 
 
// Set the ImageData stains 
def stains = imageData.getColorDeconvolutionStains() 
def stains2 = stains.changeMaxValues(maxRed, maxGreen, maxBlue) 
imageData.setColorDeconvolutionStains(stains2) 
