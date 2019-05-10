%% Read data
addpath('C:\Users\');
path = 'C:\Users\';
files = dir(sprintf('%s/img*.ppm',path));
num_files = length(files);
%% Read test images
% Change this path
test_path = 'C:\Users\';
test_files = dir(sprintf('%s/img*.ppm',test_path));
num_files_test = length(test_files);
%% Read Images
for n=1:num_files
  images{n} = imread(sprintf('%s/%s',path,files(n).name));
end
%% Read Test Images
for n=1:num_files_test
  test_images{n} = imread(sprintf('%s/%s',test_path,test_files(n).name));
end
% Input labels for test case 
test_labels = [zeros(18,1);ones(18,1)];
%% 2. Feature Extraction %%
[countExu, countRed] = getFeatures(images, num_files);
%% Plot Features
figure;
plot(1:36,countExu,'--gs',...
    'LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5]);
figure;
plot(1:36,countRed,'--gs',...
    'LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5]);
%% 3. Classifier %%
%% Prepare data
% Divide data into 6 batches having 3 healthy and 3 unhealthy
nums1 = randperm(18);
nums2 = randperm(18)+18;
group = [countExu(nums1);countRed(nums1)]';
group = [group;[countExu(nums2);countRed(nums2)]'];

%% Labels for data
% Zero - Healthy, One - Diseased
labels_overall = [zeros(18,1);ones(18,1)];
labels_train = [zeros(15,1);ones(15,1)];
pred = zeros(36,1);
pred2 = zeros(36,1);
%% Plot features together 
figure;
plot(countExu(labels_overall==0), countRed(labels_overall==0), 'g.', 'markersize', 20)
hold on
plot(countExu(labels_overall==1), countRed(labels_overall==1), 'r.', 'markersize', 20)
hold off
%% Train
for i = 1:6
    % Get test and train set
    train = group;
    test = [group(3*(i-1)+1:3*(i),:);group(18+3*(i-1)+1:18+3*(i),:)];
    train(18+3*(i-1)+1:18+3*(i),:) = [];
    train(3*(i-1)+1:3*(i),:) = [];   
    % Normalize
    meanTrain = mean(train);
    stdTrain = std(train);
    train1 = (train - meanTrain)./stdTrain;
    test1 = (test - meanTrain)./stdTrain;
    % Train models
    % LDA training using fitcdiscr. The default is the linear model.
    MdlLinear = fitcdiscr(train1,labels_train,'DiscrimType','quadratic');
    % KNN training using fitcknn.
    mdl = fitcknn(train1,labels_train,'NumNeighbors',5);
    % Predict using LDA
    pred_test = predict(MdlLinear, test1);
    % Predict using KNN
    pred_test2 = predict(mdl,test1);
    % Save predicted values
    pred(nums1(3*(i-1)+1:3*i)) = pred_test(1:3);
    pred(nums2(3*(i-1)+1:3*i)) = pred_test(4:6);
    pred2(nums1(3*(i-1)+1:3*i)) = pred_test2(1:3);
    pred2(nums2(3*(i-1)+1:3*i)) = pred_test2(4:6);
end
%% Accuracy
% Display LDA classification accuracy
match = labels_overall == pred;
specificity_LDA_CV = mean(match(labels_overall == 0))
sensitivity_LDA_CV = mean(match(labels_overall == 1))
Fscore_LDA_CV = 2*(specificity_LDA_CV*sensitivity_LDA_CV)/...
    (specificity_LDA_CV+sensitivity_LDA_CV)
% Display KNN classification accuracy
match2 = labels_overall == pred2;
specificity_KNN_CV = mean(match2(labels_overall == 0))
sensitivity_KNN_CV = mean(match2(labels_overall == 1))
Fscore_KNN_CV = 2*(specificity_KNN_CV*sensitivity_KNN_CV)/...
    (specificity_KNN_CV+sensitivity_KNN_CV)
%% 4. Left out set evaluation using KNN %%
train = [countExu; countRed]';
% Normalize training data
meanTrain = mean(train);
stdTrain = std(train);
train1 = (train - meanTrain)./stdTrain;
% Train
mdl = fitcdiscr(train1,labels_overall,'DiscrimType','quadratic');
%% Get features for second 
[countExu2, countRed2] = getFeatures(test_images, num_files_test);
%% Prepare data
test = [countExu2; countRed2]';
% Normalize
test1 = (test - meanTrain)./stdTrain;
%% Predict labels
pred_test2 = predict(mdl,test1);
%% Accuracy
match = test_labels == pred_test2;
specificity_LDA_test = mean(match(test_labels == 0))
sensitivity_KNN_test = mean(match(test_labels == 1))
Fscore = 2*(specificity_LDA_test*sensitivity_KNN_test)/...
    (specificity_LDA_test+sensitivity_KNN_test)
%% Plot Features
figure;
plot(1:36,countExu2,'--gs',...
    'LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5]);
figure;
plot(1:36,countRed2,'--gs',...
    'LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5]);
%% Plot
figure;
plot(countExu2(test_labels==0), countRed2(test_labels==0), 'g.', 'markersize', 20)
hold on
plot(countExu2(test_labels==1), countRed2(test_labels==1), 'r.', 'markersize', 20)
hold off

