# Dependency
The following dependencies must be included:
- OpenSlide for MATLAB: https://github.com/openslide/openslide
- Stain Normalisation Toolbox v2.2: https://warwick.ac.uk/fac/cross_fac/tia/software/sntoolbox/
- Following MATLAB functions:
  - edit(fullfile(matlabroot,'examples','nnet','main','freezeWeights.m'))
  - edit(fullfile(matlabroot,'examples','nnet','main','createLgraphUsingConnections.m'))
- Following Groovy scripts:
  - QuPath-Import binary masks.groovy: https://gist.github.com/petebankhead/f807395f5d4f4bf0847584458ab50277
  - Estimate_background_values.groovy: See supplementary - https://doi.org/10.1038/s41598-017-17204-5
  - After permission of Peter Bankhead inclusion of two modified copies:
    - [step_1_2_estimateBackgroundValues.groovy](step_1_2_estimateBackgroundValues.groovy)
    - [step_1_3_importBinaryLabelmaps.groovy ](step_1_3_importBinaryLabelmaps.groovy)
