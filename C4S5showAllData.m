clc;
clear;
close all;

%此脚本主要用于手动划分训练集和测试集合, 并对数据进行训练测试, 最后展示结果

%-------->1 为数据分配标签
sets = {"空载", 1; "水流", 2; "溢流结冰", 3; "非溢流结冰",  4};
DM = DataManagement(sets);
%载入数据
DM.readFile(pwd + "\实验数据");

%-------->2 划分数据集合
%首先获取所有数据编号信息
snum = size(sets, 1);
dataSet = cell(snum, 2);
for i = 1: snum
    numbers = DM.getNumberBYLabel(i);
    dataSet(i, :) = {sets{i, 1}, numbers};
end
%训练集合包含的数据编号索引, 其余数据将作为测试集数据
trainSet = {
    "空载",       [2, 3, 4, 5]; %1-5
    "水流",       [1, 2, 3]; %1-3
    "溢流结冰",    [2, 3, 4, 5]; %1-5
    "非溢流结冰",  [1, 2, 3, 5, 6, 7, 8]}; %1-8

testSet = {
    "空载",       []; %1-5
    "水流",       []; %1-3
    "溢流结冰",    [17]; %1-5
    "非溢流结冰",  []}; %1-8

%获得划分后的训练集和测试集数据
[trainData, trainLabel, testData, testLabel] = DM.generateData(trainSet, testSet);

%数据处理
DP = DataProc();

%1、首先构造用于冰型识别的特征
[trainClassData, testClassData] = DP.classifierProc(trainData, testData, 5);

CG = ColorGenerator();
[colorTable, lambdaStr] = CG.generate(zeros(1, 4));
%作图展示数据分布
figure(1);
for i = 1: snum
    idx = find(trainLabel == i);
    data = trainClassData(idx, :);
    plot3(data(:, 1), data(:, 2), data(:, 3), 'Color', colorTable(i, :), ...
        "Marker", "*", "LineStyle", "none"); hold on;
end
legend(sets{:, 1});
ylabel("第一主成分");
xlabel("第二主成分");
zlabel("第三主成分");
grid on;

%训练分类器，并获得测试集的标签输出
[classifier, ~] = trainClassifier(trainClassData, trainLabel);
[trainLabelPre, ~] = classifier.predictFcn(trainClassData);
[testLabelPre, ~] = classifier.predictFcn(testClassData);

%展示分类情况
figure;
plot(testData(:, 1)); hold on;
% plot(testData(:, 2)); hold on;
% plot(testData(:, 3)); hold on;
% plot(testData(:, 4)); hold on;
plot(testLabelPre);
% plot(testLabel);
% legend("电压", "预测标签");
xlabel("时间(s)");

t = (1: 1: size(testData, 1))';

% save 分类测试结果2.mat t testData testLabelPre;


