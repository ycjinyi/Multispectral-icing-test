function [testLabels, testPreLabels] = crossValidation(DM, r)
%此函数负责留一法循环验证, r代表循环的轮数, 目前需要假设每一种状态都有3组数据
    testLabels = zeros(1, 1);
    testPreLabels = zeros(1, 1);
    %初始索引
    idx = 1;
    %数据处理对象
    DP = DataProc();
    %-------->1 划分数据集合
    keySet = keys(DM.label2Name);
    snum = size(keySet, 2);
    testSet = zeros(snum, r * 3);
    %首先产生数据编号
    for i = 1: snum
        for j = 1: r
            randIdx = randperm(3); 
            testSet(i, (j - 1) * 3 + 1: j * 3) = randIdx;
        end
    end
    %包含的数据编号索引
    test = {
        "结冰",       {3}; 
        "积水",       {3}; 
        "冰水混合",   {3}; 
        "干雪",       {3}; 
        "湿雪",       {3}; 
        "空载",       {3};
        "机油",       {3};
        "防冻液",     {3};
        "沙土",       {3};};
    %根据数据编号分别构建测试集进行测试
    for i = 1: size(testSet, 2)
        %根据上述选择方式重新调整test
        for j = 1: snum
            test{j, 2} = testSet(j, i);
        end
        %获得划分后的训练集和测试集数据
        [testData, testLabel, trainData, trainLabel] = DM.generateData(test);
        %数据处理+特征选取
        [trainData, testData] = DP.dataProc(trainData, testData, 7);
        %进行模型的训练和预测
        [classifier, ~] = trainClassifier(trainData, trainLabel);
        [testPreLabel, ~] = classifier.predictFcn(testData);
        %装载数据
        r = size(testLabel, 1);
        testLabels(idx: idx + r - 1, 1) = testLabel;
        testPreLabels(idx: idx + r - 1, 1) = testPreLabel;
        idx = idx + r;
        %输出进度
        fprintf("---->%0.1f%%<-----\n", floor((1000 * i / size(testSet, 2))) / 10);
    end
end