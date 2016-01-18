function varargout = bbGtStats( varargin )
%function CreateGTAnnotations(dataList,gtLabelDir,annotationDir,statsDir,doorLabel,windowLabel,numClasses)

prms = getPrmDflt(varargin,{'dataList','','gtLabelDir','','annotationDir','',...
       'statsDir','','clsLabels',[],'numClasses',1},1);

if ~exist(prms.annotationDir,'dir') mkdir(prms.annotationDir); end
if ~exist(prms.statsDir,'dir') mkdir(prms.statsDir); end

clsParams = {}; clsStats = {};
for i=1:length(prms.clsLabels)
    clsParams{i} = [];
end

for i=1:length(prms.dataList)    
    %[a,img_name,c] = fileparts(dataList{i});
		img_name = prms.dataList{i};
		fprintf(1,'%d. %s\n',i,img_name);
    %Load segmentation labels for the image
    labels = load([prms.gtLabelDir '/' img_name '.txt']);    
    numObjects = 0; objTypes = []; objParams = [];
    for j=1:length(prms.clsLabels)
        bwImage = labels == j;
        params = GetParams(bwImage);
        for t=1:size(params,1)
           objParams = [objParams; params(t,:)];
           numObjects = numObjects + 1;
           objTypes{numObjects} = prms.clsLabels(j);
           clsParams{j} = [clsParams{j}; params(t,1:4)];
					 % maybe add 'other' class
        end
    end
    objs = bbGt('create',[numObjects]);
    for k=1:numObjects
        objs(k).lbl = objTypes{k};
        objs(k).bb = objParams(k,1:4);
        %objs(k).occ = objParams(k,5:8);
        %objs(k). bbv = objParams(k,9);
        %objs(k).ign = objParams(k,10);
        %objs(k).ang = objParams(k,11);
    end
    fName = [prms.annotationDir '/' img_name '.txt'];
    objs = bbGt('bbSave', objs, fName);
end

for j=1:length(prms.clsLabels)
    stats = {}; params = clsParams{j};
    stats.xRange = [max(0,min(params(:,1))-100) max(params(:,1))+100];
    stats.yRange = [max(0,min(params(:,2))-100) max(params(:,2))+100];
    stats.hRange = [max(0,min(params(:,4))-20) max(params(:,4))+20];
    stats.wRange = [max(0,min(params(:,3))-10) max(params(:,3))+10];
    stats.modelDs = [mean(params(:,4))-10 mean(params(:,3))-10];
    stats.modelDsPad = [stats.hRange(2)-10 stats.wRange(2)];
		clsStats{j} = stats;
end
save([prms.statsDir '/stats.mat'],'clsStats');

end

function params = GetParams(bwImage)

params = [];
bwImage = bwareaopen(bwImage, 200);
CC = bwconncomp(bwImage);
nObjects = CC.NumObjects;
imgL = bwlabel(bwImage);
for i=1:1:nObjects
    [indX,indY]=find(imgL==i);
    obj_l=min(indY);obj_t=min(indX);
    obj_w=max(indY)-min(indY);
    obj_h=max(indX)-min(indX);
    params = [params; obj_l obj_t obj_w obj_h 0 0 0 0 0 0 0];
end

end
