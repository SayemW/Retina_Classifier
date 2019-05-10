%% Function
function opticDiscImg = opticDiscCH(inputImg) 
%% Get green channel
% Green channel provides best contrast between the optical disc and the
% background
image1 = inputImg(:,:,2);
%% Increase contrast
% Further increasing the contrast of the images. This preprocessing step
% was suggest by several papers
% imadjust(I) maps the intensity values in grayscale image I to new values
% in J. By default, imadjust saturates the bottom 1% and the top 1% of all
% pixel values.
image1Con = imadjust(image1);
% ADAPTHISTEQ enhances the contrast of images by transforming the
% values in the intensity image I.  Unlike HISTEQ, it operates on small
% data regions (tiles), rather than the entire image. Each tile's contrast 
% is enhanced, so that the histogram of the output region approximately 
% matches the histogram specified by the 'Distribution' value. The default
% 'Distribution' value is a flat histogram. Then it performs bilinear
% interpolation to eliminate boundries between tiles.
image1Con = adapthisteq(image1Con);
%% Threshold
% Only pixels having high intesnity are retained. The optical disk is
% high generally in intensity
img1 = zeros(size(image1));
img1(image1Con > 250) = 1;
%imagesc(img1);
%% Erode
% Remove unwanted noise and smaller objects
% SE = STREL('disk',R,N) creates a flat disk-shaped structuring element
% with the specified radius, R.
se = strel('disk', 7);
% IM2 = IMERODE(IM,SE) erodes the binary image IM, returning the eroded 
% image, IM2.
img1 = imerode(img1, se);
%% Dialate
% IM2 = IMDILATE(IM,SE) dilates the binary image IM, returning the dilated
% image, IM2.
img2 = imdilate(img1, se);
%% Convert to logical
img2 = logical(img2);
%% Vessel Extraction
% Extract the vessels from the retina image. The optical disk is present
% near areas of high blood vessel presence. By identifying the this area we
% can find out where the optical disc is most likely to be present.
%% Median Fil
% Median filter the image and subtact the original from this image.
image2 = medfilt2(image1Con, [26, 26]);
%% Subtract images
image3 = image2 - image1Con;
%% Threshold
image4 = zeros(size(image3));
image4(image3 >= 20) = 1;
%% Strength
% This is used to make the vessels more prominent. If more than 5 pixels
% are present within the window, it is strengthened.
% Y = FILTER2(B,X) filters the data in X with the 2-D FIR
% filter in the matrix B.  The result, Y, is computed 
% using 2-D correlation and is the same size as X.
image5 = filter2(ones(3,3), image4); 
image5 = image5 >= 5;
%% Vessel extraction %%
% The largest connected component is the blood vessel.
% BW2 = BWAREAOPEN(BW,P) removes from a binary image all connected
% components (objects) that have fewer than P pixels, producing another
% binary image BW2. It uses bwconncomp to find the connected regions and
% keeps only the regions that fits the area given.
% CC = BWCONNCOMP(BW) returns the connected components CC found in BW. It
% first finds an unlabeled pixel "A" and then uses the flood fill algotithm to
% label all pixels connected to this pixel "A".
image6 = bwareaopen(image5,1000);
%% Get properties
% Filtering out compnents that do not satisfy the properties of a retina
% STATS = REGIONPROPS(BW,PROPERTIES) measures a set of properties for
% each connected component (object) in the binary image. It uses bwconncomp
% to get the different connected components and then does mathematical
% operations to get the various properties of the image.
stats = regionprops('table',img2, 'Centroid', 'Eccentricity', 'MajorAxisLength','MinorAxisLength');
stats( stats.MajorAxisLength < 22 , : ) = [];
stats( stats.MinorAxisLength < 22 , : ) = [];
stats( stats.Eccentricity > 0.85 , : ) = [];
numEle = size(stats);
maxVal = 10;
best = 0;
% If nothing found then return blank image
if (numEle(1) == 0)
    opticDiscImg = zeros(size(img1));
    return;
end
% Here we find which components have the highest blood vessel presence
% close to them. The one with the highest is the most likely to be the
% optical disc
for i = 1:numEle
    yC = round(stats.Centroid(i,1));
    xC = round(stats.Centroid(i,2));
    Hl = min(50, xC-1);
    Hr = min(50, size(image1,1)-xC-1);
    Vl = min(50, yC-1);
    Vr = min(50, size(image1,2)-yC-1);
    numPix = sum(sum(image6(xC-Hl:xC+Hr,yC-Vl:yC+Vr)));
    if (numPix>=maxVal)
        maxVal = numPix;
        best = i;
    end
end
% If none is suitable then return a blank image
if (best == 0)
    opticDiscImg = zeros(size(img1));
    return;
end
center = round(stats.Centroid(best,:));
%% Dialate center image
% Get approximate location of optical disc
imageCen = zeros(size(inputImg));
imageCen(center(2),center(1)) = 1;
se = strel('disk', 80);
imageCen = imdilate(imageCen, se);
%imagesc(imageCen);
%% Masked Img
% Perform reconstruction and then subract it from the original image.
imageMsk = image1;
imageMsk(imageCen == 1) = 0;
% IM = IMRECONSTRUCT(MARKER,MASK) performs morphological reconstruction
% of the image MARKER under the image MASK. Morphological reconstruction 
% can be thought of conceptually as repeated dilations of an image, 
% called the marker image, until the contour of the marker image fits 
% under a second image, called the mask image. imreconstruct uses the fast
% hybrid grayscale reconstruction algorithm. 
imageRecon = imreconstruct(imageMsk, image1);
%imagesc(imageRecon);
%colormap(gray);
%% Sub Images
% This gives a better location of the optical disk
imageOD = image1 - imageRecon;
%% Binarnize
imageOD(imageOD > 0) = 1;
%% Median Filter
% Remove noise
imageOD = medfilt2(imageOD);
%imagesc(imageOD);
%% Dilation
% Dilate to get the approximate optical disc
se = strel('disk', 10);
imageOD = imdilate(imageOD, se);
opticDiscImg = imageOD;