function exudateImg = exudateDetectionMSNC(inputImg)
%% Exudate detection using Mean-shift
%% Contrast
% imadjust(I) maps the intensity values in grayscale image I to new values
% in J. By default, imadjust saturates the bottom 1% and the top 1% of all
% pixel values.
imagex = imadjust(inputImg,[.2 .3 0; .6 .7 1],[]);
greenC = imagex(:,:,2);
% If the intensity of the images is too low then change imadjust to
% increase contrast
if (max(greenC(:))>=100 && max(greenC(:))<=150)
    imagex = imadjust(inputImg,[.2 .3 0; .6 .4 1],[]);
end
greenC = imagex(:,:,2);
test = zeros(size(greenC));
test(greenC>=200) = 1;
% BW2 = BWPROPFILT(BW,P) filters the images using the inputs, producing
% another binary image BW2. It uses regionprops which uses bwconncomp to
% find the connected regions and computes its properties and then
% keeps only the regions that fits the properties given.
% CC = BWCONNCOMP(BW) returns the connected components CC found in BW. It
% first finds an unlabeled pixel "A" and then uses the flood fill algotithm 
% to label all pixels connected to this pixel "A".
sizeTest = bwpropfilt(logical(test),'Area',[7000 100000]);
% If the size of the high intesity area is too large then lower the
% contrast
if (max(sizeTest(:)) ~= 0)
    imagex = imadjust(inputImg,[.2 .3 0; .6 1 1],[]);
end
%imagesc(imagex);
%% Mean-shift
% Use the mean shift code provided in class with the medium speed up to
% segment the exudates based on color
eps = 0.05;
I = im2double(imagex);
% Change from three channels into one channel that contains all the color
% information
X = reshape(I,size(I,1)*size(I,2),3);
radius = 0.4;
stop_criterion = .05;  % Largest distance allowed between 2
                       % iterations without stopping
marker = zeros(size(X));
count = 0;
seg_feat1 = zeros(size(X));
% Loop through each voxel
for i = 1:size(X,1)
    for j = 1:size(X,2)
        if (marker(i,j)~=0)
            count = count + 1;
            continue;
        end
        small_loop = zeros(size(X));
        cur_feat1 = X(i,j);
        cur_criterion = 10;
        % Find the convergence point for the single voxel
        while cur_criterion>stop_criterion
        % compute distance for all points vs first
            dist_loop = abs(cur_feat1(end) - X);
            keep_loop = dist_loop<radius;
            small_loop = small_loop + (dist_loop<(radius*eps));
            mean_loop_feat1 = mean(X(keep_loop==1));
            cur_criterion = abs(cur_feat1(end) - mean_loop_feat1);
            cur_feat1 = [cur_feat1; mean_loop_feat1];
        end
        seg_feat1(i,j) = cur_feat1(end); 
        seg_feat1(small_loop~=0) = cur_feat1(end);
        marker = marker + small_loop;
    end
end
%% Get results
unique_vals = unique(round(seg_feat1*10));
seg_vec = zeros(size(X));
seg_vec(round(seg_feat1*10) == unique_vals(size(unique_vals,1))) = 4;

seg_img = seg_vec;
% Get image back from the color information image
exudateImg = reshape(seg_img==4,size(I,1),size(I,2),3);
%exudateImg = medfilt2(exudateImg);
exudateImg = exudateImg(:,:,2);
%figure;
%imshowpair(inputImg,exudateImg);
