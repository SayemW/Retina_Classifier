function BW2 = redLesDetection(inputImg)
%% Contrast Enhance
image1 = inputImg;
% imadjust(I) maps the intensity values in grayscale image I to new values
% in J. By default, imadjust saturates the bottom 1% and the top 1% of all
% pixel values.
image1 = imadjust(image1(:,:,2));
% ADAPTHISTEQ enhances the contrast of images by transforming the
% values in the intensity image I.  Unlike HISTEQ, it operates on small
% data regions (tiles), rather than the entire image. Each tile's contrast 
% is enhanced, so that the histogram of the output region approximately 
% matches the histogram specified by the 'Distribution' value. The default
% 'Distribution' value is a flat histogram. Then it performs bilinear
% interpolation to eliminate boundries between tiles.
image1 = adapthisteq(image1);
%image1 = images{30}(:,:,2);
%% Median Fil
% The follwing process emphasizes the dark regions of the retina image
% incuding the red lesions and the blood vessels
image2 = medfilt2(image1, [26, 26]);
%% Subtract images
image3 = image2 - image1;
%% Threshold
image4 = zeros(size(image3));
image4(image3 >= 20) = 1;
%% Strength
image5 = filter2(ones(3,3), image4); 
image5 = image5 >= 5;
%% Vessel extraction %%
% The blood vessels are extracted using the same method as used in
% opticDiscCH() method
% The largest connected component is the blood vessel.
% BW2 = BWAREAOPEN(BW,P) removes from a binary image all connected
% components (objects) that have fewer than P pixels, producing another
% binary image BW2. It uses bwconncomp to find the connected regions and
% keeps only the regions that fits the area given.
% CC = BWCONNCOMP(BW) returns the connected components CC found in BW. It
% first finds an unlabeled pixel "A" and then uses the flood fill algotithm to
% label all pixels connected to this pixel "A".
image6 = bwareaopen(image5,1000);
%% Remove the blood vessels
image7 = image5-image6;
%% Filter compoents that do no fit the description of red lesions
% BW2 = BWPROPFILT(BW,P) removes from a binary image all connected
% components (objects) that do not satisfy the inputs, producing another
% binary image BW2. It uses bwconncomp and regionprops to find the 
% connected regions and keeps only the regions that fits the area given.
% CC = BWCONNCOMP(BW) returns the connected components CC found in BW. It
% first finds an unlabeled pixel "A" and then uses the flood fill algotithm to
% label all pixels connected to this pixel "A".
BW2 = bwpropfilt(logical(image7),'MajorAxisLength',[2 50]);
BW2 = bwpropfilt(logical(BW2),'MinorAxisLength',[2 50]);
BW2 = bwpropfilt(logical(BW2),'Eccentricity',[0 0.75]);
%% Erode to remove excess noise
se = strel('disk',3);
BW2 = imerode(BW2,se);