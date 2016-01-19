function varargout = bbGtStats( varargin )
%function CreateGTAnnotations(dataList,gtLabelDir,annotationDir,statsDir,doorLabel,windowLabel,numClasses)

prms = getPrmDflt(varargin,{'dataList','','lblDir','','annotationDir','',...
       'statsDir','','clsLabels',[],'numClasses',1},0);

if ~exist(prms.annotationDir,'dir') mkdir(prms.annotationDir); end
if ~exist(prms.statsDir,'dir') mkdir(prms.statsDir); end

clsParams = {}; clsStats = {};
for i=1:prms.numClasses clsParams{i} = []; end
for i=1:length(prms.dataList)    
		fprintf(1,'%d. %s\n',i,prms.dataList{i});
    labels = load([prms.lblDir '/' prms.dataList{i} '.txt']);    
    numObjects = 0; objTypes = []; objParams = [];
    for j=1:prms.numClasses 
			  if ismember(j-1,prms.clsLabels)
            bwImage = labels == j-1; params = GetParams(bwImage);
            for t=1:size(params,1)
               objParams = [objParams; params(t,:)]; numObjects = numObjects + 1;
               objTypes{numObjects} = num2str(j-1); clsParams{j} = [clsParams{j}; params(t,1:4)];
    					 % maybe add 'other' class
            end
				end
    end
    objs = bbGt('create',[numObjects]);
    for k=1:numObjects
        objs(k).lbl = objTypes{k}; objs(k).bb = objParams(k,1:4);
        %objs(k).occ = objParams(k,5:8); %objs(k). bbv = objParams(k,9);
				%objs(k).ign = objParams(k,10); %objs(k).ang = objParams(k,11);
    end
    fName = [prms.annotationDir '/' prms.dataList{i} '.txt'];
    objs = bbGt('bbSave', objs, fName);
end

for j=1:prms.numClasses 
    stats = {}; params = clsParams{j};
		if size(params,1)>0
        stats.xRange = [max(0,min(params(:,1))-100) max(params(:,1))+200];
        stats.yRange = [max(0,min(params(:,2))-100) max(params(:,2))+200];
        stats.hRange = [max(0,min(params(:,4))-20) max(params(:,4))+20];
        stats.wRange = [max(0,min(params(:,3))-10) max(params(:,3))+10];
        stats.modelDs = [mean(params(:,4))-10 mean(params(:,3))-10];
        stats.modelDsPad = [stats.hRange(2)-10 stats.wRange(2)];
        clsStats{j} = stats;
		end
end
save([prms.statsDir '/stats.mat'],'clsStats'); 
stats.clsStats=clsStats; varargout{1}=stats;

end

function params = GetParams(bwImage)

params = [];
bwImage = bwareaopen(bwImage, 200); CC = bwconncomp(bwImage);
nObjects = CC.NumObjects; imgL = bwlabel(bwImage);
for i=1:1:nObjects
    [indX,indY]=find(imgL==i); obj_l=min(indY);obj_t=min(indX);
    obj_w=max(indY)-min(indY); obj_h=max(indX)-min(indX);
    params = [params; obj_l obj_t obj_w obj_h 0 0 0 0 0 0 0];
end

end
