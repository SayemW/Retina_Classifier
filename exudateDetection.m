function exudateImg = exudateDetection(inputImg)
% Based on: Exudates and optic disk detection in retinal images
% of diabetic patients - Zeljkovich et al.
%% Improve Contrast
% Improve the contrast of the images
imageTest = inputImg(:,:,2);
% imadjust(I) maps the intensity values in grayscale image I to new values
% in J. By default, imadjust saturates the bottom 1% and the top 1% of all
% pixel values.
image1 = imadjust(imageTest);
% ADAPTHISTEQ enhances the contrast of images by transforming the
% values in the intensity image I.  Unlike HISTEQ, it operates on small
% data regions (tiles), rather than the entire image. Each tile's contrast 
% is enhanced, so that the histogram of the output region approximately 
% matches the histogram specified by the 'Distribution' value. The default
% 'Distribution' value is a flat histogram. Then it performs bilinear
% interpolation to eliminate boundries between tiles.
image2 = adapthisteq(image1);
image2 = double(image2);
%% Logrithmic operation
% Use the lorithmic operator to emphasize the exudates
for i = 1:size(image2,1);
    for j = 1:size(image2,2);
        intensity = image2(i,j);
        if (intensity >= 0 && intensity <= 50)
            image2(i,j) = log(1+intensity)/log(5);
        elseif (intensity > 50 && intensity <= 100)
            image2(i,j) = log(1+intensity)/log(4);
        elseif (intensity > 100 && intensity <= 150)
            image2(i,j) = log(1+intensity)/log(3);
        elseif (intensity > 150 && intensity <= 200)
            image2(i,j) = log(1+intensity)/log(2);
        else
            image2(i,j) = log(1+intensity)/log(1.5);
        end
    end
end
%imagesc(image2);
%colormap(gray);
%% Threshold to get exudates
maxInt = max(image2(:));
exudateImg = zeros(size(image1));
exudateImg(image2 == maxInt) = 1;
exudateImg = medfilt2(exudateImg);