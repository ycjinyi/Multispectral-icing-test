classdef DataProc < DataAttribute
%此类用于专门同时处理训练集和测试集的数据

    properties
        %训练集每列的均值
        trainMean;
        %训练集每列的标准差
        trainVar;
        %训练集的特征向量
        trainV;
    end

    methods
        function obj = DataProc()
            obj = obj@DataAttribute();
        end
        
        %构造特征, 注意行为一条数据, 列为特征
        function data = strucFeature(obj, data)
            cIdx = size(data, 2) + 1;
            %将不同接收管的相同波段的比值作为特征 
            for i = 1: obj.rNum - 1
                idx1 = (i - 1) * obj.pNum;
                idx2 = i * obj.pNum;
                for j = 1: obj.pNum
                     data(:, cIdx) = data(:, idx1 + j) ./ (1 + data(:, idx2 + j));
                     data(:, cIdx + 1) = data(:, idx1 + j) + data(:, idx2 + j);
                     cIdx = cIdx + 2; 
                end
            end
            %将相同接收管的不同波段的比值、和值作为特征
            for i = 1: obj.rNum
                idx = (i - 1) * obj.pNum;
                for j = 1: obj.pNum - 2
                    data(:, cIdx) = data(:, idx + j) ./ (1 + data(:, idx + j + 1));
                    data(:, cIdx + 1) = data(:, idx + j) + data(:, idx + j + 1);
                    cIdx = cIdx + 2;
                end
            end
        end

        %标准化数据, 注意行为一条数据, 列为特征
        function [trainData, testData] = zScore(obj, trainData, testData)
            obj.trainMean = mean(trainData, 1);
            obj.trainVar = std(trainData, [], 1);
            trainData = (trainData - obj.trainMean) ./ obj.trainVar;
            testData = (testData - obj.trainMean) ./ obj.trainVar;
        end

        %PCA对数据进行降维
        function [trainData, testData] = PCA(obj, trainData, testData, number)
            %计算协方差矩阵  
            covMatrix = cov(trainData);  
            %计算特征值和特征向量  
            [V, D] = eig(covMatrix);  
            %对特征值进行排序，并获取对应的特征向量  
            [D, sortIdx] = sort(diag(D), 'descend');  
            V = V(:, sortIdx);  
            if number >= 1
                obj.trainV = V(:, 1: number);
            else 
                %选择主成分以保留ratio的方差解释  
                cumVariance = cumsum(D) / sum(D);  
                numComponents = find(cumVariance >= number, 1, 'first');  
                %提取选定的主成分对应的特征向量  
                obj.trainV = V(:, 1: numComponents);  
            end 
            %转换数据到新的低维空间  
            trainData = trainData * obj.trainV;
            testData = testData * obj.trainV;
        end

        %分类器的特征构造函数
        function [trainData, testData] = classifierProc(obj, trainData, testData, number)
            %构造特征
            trainData = obj.strucFeature(trainData);
            testData = obj.strucFeature(testData);
            %标准化数据
            [trainData, testData] = obj.zScore(trainData, testData);
            %PCA降维
            [trainData, testData] = obj.PCA(trainData, testData, number);
        end

        %计算R^2
        function [R2] = computeR2(~, real, predict) 
            % 计算实际值的均值  
            realMean = mean(real);   
            % 残差平方和(RSE) 
            RSE = sum((predict - real) .* (predict - real));
            % 总平方误差和(TSE) 
            TSE = sum((real - realMean) .* (real - realMean));
            % 计算R方值  
            R2 = 1 - (RSE / TSE);  
        end

        %计算RMSE
        function [RMSE] = computeRMSE(~, real, preditct)
            count = size(real, 1);
            s = 0;
            %计算RMSE
            for i = 1: count
                s = s + power(real(i, 1) - preditct(i, 1), 2);
            end
            RMSE = sqrt(s / count);
        end

        %计算创建颜色映射
        function [color] = colorMap(~, data, value)
            %数据的均值
            dataMean = mean(data);
            %首先减去均值
            data = data - dataMean;
            %数据的最大值
            dataMax = max(data);
            %数据的最小值
            dataMin = min(data);
            %然后找到最大的变化范围
            range = max(dataMax, abs(dataMin));
            %计算系数
            coff = 1 / range;
            %乘以系数
            data = abs(data) * coff;
            %颜色映射
            color = round(data * value);  
        end

    end
end