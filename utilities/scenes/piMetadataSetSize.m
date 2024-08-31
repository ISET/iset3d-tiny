function sensor = piMetadataSetSize(oi,sensor)
% Convert metadata from OI to sensor; ultimately to IP through piOI2IP
%
% Brief
%   In some applications we want to carry the metadata from the oi to
%   the sensor.  Seems to need some simplification with piOI2IP.
%
% Syntax
%   sensor = piMetadataSetSize(oi,sensor)
%
% Inputs
%   oi
%   sensor
%
% Optional key/val pairs
%   'ip'
%
% Return
%  sensor
%  ip
%
% Description
%   The related function piOI2IP converts from oi to sensor to ip.
%   Describe the issues and algorithm here. It seems to me we should
%   have a single function, maybe piMetadata(oi,varargin), that
%   converts from the oi to the sensor and, optionally, to the ip.
%   Maybe like this:  piMetadata(oi,sensor,'ip',ip);
%
% Zhenyi Liu, 2019
%
% See also
%   We should rename and integrate with piOI2IP
%

% sensorSize = sensorGet(sensor,'size');
% ImgSize    = size(sensor.metadata.meshImage);
% crop_rec = [(ImgSize(2)-sensorSize(2))/2 (ImgSize(1)-sensorSize(1))/2 ...
%             sensorSize(2) sensorSize(1)];

%% We need to decribe the algorithm here

spacing = 1;
r = oiGet(oi,'rows'); c = oiGet(oi,'cols');
rSamples = (0:(r-1));
cSamples = (0:(c-1));
sampleHeight = oiGet(oi,'hres'); 
sampleWidth  = oiGet(oi,'wres');
[theseRows,theseCols] = sample2space(rSamples,cSamples,sampleHeight,sampleWidth);
[U,V] = meshgrid(theseCols, theseRows);

% The values of newRols and newCols are sampled positions on the image
% sensor array. If spacing < 1, they are spaced more finely than the pixel
% samples.  We haven't done a lot of calculations in recent years with
% spacing < 1.  For some cases, this could be an issue - maybe for a very
% small point in the oi.
r = sensorGet(sensor,'rows'); c = sensorGet(sensor,'cols');
rSamples = (0:spacing:(r-spacing)) + (spacing/2);
cSamples = (0:spacing:(c-spacing)) + (spacing/2);
sampleHeight = sensorGet(sensor,'hres'); sampleWidth = sensorGet(sensor,'wres');
[newRows,newCols] = sample2space(rSamples,cSamples,sampleHeight,sampleWidth);
[X,Y] = meshgrid(newCols,newRows); 

sensor.metadata.meshImage = interp2(U,V,double(sensor.metadata.meshImage),X,Y,'nearest');
sensor.metadata.depthMap  = interp2(U,V,sensor.metadata.depthMap,X,Y,'nearest');
        
% % crop depth and mesh
% 
% sensor.metadata.meshImage = imcrop(sensor.metadata.meshImage,crop_rec);
% sensor.metadata.depthMap  = imcrop(sensor.metadata.depthMap, crop_rec);

end