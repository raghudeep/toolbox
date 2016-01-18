function varargout = runDetect( varargin )
%function DoDetections(trainDataFiles,testDataFiles,imgDir,annotationDir,statsDir,modelDir,outputDir,doorLabel,windowLabel,numClasses)

prms = getPrmDflt(varargin,{'trainDataFiles','','testDataFiles','','annotationDir','',...
       'imgDir','','statsDir','','modelDir','','clsLabels',[],'numClasses',1,'outputDir',''},1);
opts = acfTrain();
opts.pPyramid.smooth=.5; opts.pPyramid.pChns.pColor.smooth=0;
opts.stride = 1;
opts.pNms.overlap = 0.99999;
opts.nWeak=[32 128 512 2048];
opts.pJitter=struct('flip',1);
opts.pBoost.pTree.fracFtrs=1/16;
opts.posGtDir= prms.annotationDir;
stats = load([prms.statsDir '/stats.mat']);
tempImgDir = tempname; mkdir(tempImgDir);
for i=1:length(prms.trainDataFiles)
    copyfile([prms.imgDir '/' prms.trainDataFiles{i} '.png'], tempImgDir);
end
opts.posImgDir=tempImgDir;

for j=1:numClasses 
	  if ismember(j-1,prms.clsLabels)
        opts.name=[prms.modelDir '/' num2str(prms.clsLabels(j))];
        opts.modelDs=stats.clsStats{j}.modelDs; opts.modelDsPad=stats.clsStats{j}.modelDsPad;
        pLoad={'lbls',{'door'},'ilbls',{'doors'}}; %% check
        opts.pLoad = [pLoad 'yRng',stats.clsStats(j).yRange, 'xRng',stats.clsStats(j).xRange,...
				              'hRng',stats.clsStats(j).hRange, 'wRng',stats.clsStats(j).wRange ];
        detector = acfTrain(opts);
        detector = acfModify(detector,'cascThr',-1,'cascCal',0.1,'stride',1);%% check
        for t=1:length(testDataFiles)
            I = imread([prms.imgDir testDataFiles{t} '.png']);
            bbs = acfDetect(I,detector); bbs_final = [];
            for s=1:size(bbs,1)
                if (bbs(s,1) > leftRange(1)) && (bbs(s,1) < leftRange(2))
                    if (bbs(s,2) > topRange(1) && bbs(s,2) < topRange(2))
                        if (bbs(s,3) > widthRange(1) && bbs(s,3) < widthRange(2))
                            if (bbs(s,4) > heightRange(1) && bbs(s,4) < heightRange(2))
                                bbs_final = [bbs_final ; bbs(s,:)];
                            end
                        end
                    end
                end
						end
            imgSize = [size(I,1),size(I,2)]; featureImage = zeros(imgSize);
            for k =1:size(bbs_final,1)
                if bbs_final(k,5) > 0
                    featureImage = featureImage + GetDetectionMask(imgSize,bbs_final(k,:),bbs_final(k,5));
                end
            end
            featureImage = featureImage';
            features = featureImage(:);
            %dlmwrite(strcat(outputDir,'/',img_name,'.doorfeatures.txt'),doorFeatures,'delimiter',' ');
            fid=fopen([prms.outputDir '/' testDataFiles{t} '.' num2str(j-1) '.bin'],'wb');
            fwrite(fid,doorFeatures,'float32'); fclose(fid);
        end
		end
end

end

function mask = GetDetectionMask(imgSize,bbs,score);
mask = zeros(imgSize(1),imgSize(2));
bbs = floor(bbs);
mask(max(bbs(2),1):min(bbs(2)+bbs(4),imgSize(1)),...
    max(bbs(1),1):min(bbs(1)+bbs(3),imgSize(2))) = score;

end
