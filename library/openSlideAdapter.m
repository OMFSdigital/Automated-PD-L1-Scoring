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

classdef openSlideAdapter < ImageAdapter
    properties
        Filename
        ImageInfo
        Properties
        Page
        OpenslidePointer
    end
    methods
        function obj = openSlideAdapter(path, page)
            if ~isfile(path)
                error(['File not found: ',path])
            end
            obj.OpenslidePointer = openslide_open(path);
            obj.Filename = path;
            obj.ImageInfo = imfinfo(path);
            obj.Page = page;
            obj.ImageSize = [obj.ImageInfo(page).Height-1 obj.ImageInfo(page).Width-1];
            [mppX,mppY,width,height] = openslide_get_slide_properties(obj.OpenslidePointer);
            obj.Properties.mppX = mppX;
            obj.Properties.mppY = mppY;
            obj.Properties.width = width;
            obj.Properties.height = height;
        end

        function result = readRegion(obj, start, count)
            result = openslide_read_region(obj.OpenslidePointer, start(2),start(1),count(2),count(1));
        end

        function result = close(obj) 
            openslide_close(obj.OpenslidePointer);
        end
    end
end
