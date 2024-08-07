%%
ieInit; clear ISETdb
% set up connection to the database, it's 49153 if we are in Stanford
% Network. 
% Question: 
%   1. How to figure out the port number if we are not.
%   2. What if the data is not on acorn?
% 
setpref('db','port',49153);
ourDB = isetdb();
%% Database description
% assets: Contains reusable components like models, textures, or animations
%         that can be used across various scenes or projects.
%
% scenes: Contains individual scene files which may include all
%         the necessary data (like assets, lighting, and camera information) 
%         to render a complete environment or image. 

% bsdfs: Stands for Bidirectional Scattering Distribution Functions; likely
%        contains data or scripts related to the way light interacts with 
%        surfaces within a scene. 
% 
% lens: Could contain data related to camera lens
%       configurations or simulations, affecting how scenes are viewed or
%       rendered. 
% 
% lights: Likely holds information or configurations for various
%         lighting setups, which are essential in 3D rendering for realism 
%         and atmosphere. 
% 
% skymaps: Usually refers to
%          panoramic textures representing the sky, often used in rendering 
%          to create backgrounds or to simulate environmental lighting.

% we might want to decide, wheather we would like to add this scene to our
% database.
% Create a new collection for test
collectionName = 'PBRTResources';

remoteHost = 'orange.stanford.edu';
remoteUser = 'zhenyiliu';
remoteServer = sftp('orange.stanford.edu','zhenyiliu');
remoteDir = '/acorn/data/iset/PBRTResources';

folders = dir(remoteServer, remoteDir);

ResourcesTypes = {'asset','scene','bsdf','skymap','spd','lens','texture'};

%% assets
assetDir = fullfile(remoteDir,'asset');
categories = dir(remoteServer, assetDir);

for ii = 1:numel(categories) % first one is '@eaDir'
    if strcmp(categories(ii).name, '@eaDir')
        continue
    end

    thisCat = fullfile(categories(ii).folder, categories(ii).name);

    assets = dir(remoteServer, thisCat);
    for jj = 1:numel(assets)
        if strcmp(assets(jj).name, '@eaDir') || strcmp(assets(jj).name,'textures')
            continue
        end
        thisAsset = fullfile(assets(jj).folder, assets(jj).name);
        if assets(jj).isdir
            ourDB.contentCreate('collection Name',collectionName, ...
                'type','asset', ...
                'filepath',thisAsset,...
                'name',assets(jj).name,...
                'category',categories(ii).name,...
                'mainfile',[assets(jj).name, '.pbrt'],...
                'source','blender',...
                'tags','auto',...
                'size',piDirSizeGet(thisAsset,remoteServer)/1024^2,... % MB
                'format','pbrt');
        end
    end
    fprintf('[INFO]: %s is added.\n',categories(ii).name);
end

%% find all bus
assets = ourDB.contentFind(collectionName, 'category','bus','type','asset', 'show',true);

%% scenes
% upload the file to remote server
filesSyncRemote(remoteServer, localFolder, remoteDir);

% add this scene to our database

[thisID, contentStruct] = ourDB.contentCreate('collection Name',collectionName, ...
    'type','scene', ...
    'filepath',remoteDir,...
    'name','low-poly-taxi',...
    'category','iset3d',...
    'mainfile','low-poly-taxi.pbrt',...
    'source','blender',...
    'tags','test',...
    'sizeInMB',piDirSizeGet(sceneFolder,remoteServer)/1024^2,... % MB
    'format','pbrt'); 

queryStruct.hash = thisID;
thisScene = ourDB.contentFind(collectionName, queryStruct);

%% textures
assetDir = fullfile(remoteDir,'skymap');
skymaps = dir(remoteServer, assetDir);

for ii = 1:numel(skymaps) % first one is '@eaDir'
    if strcmp(skymaps(ii).name, '@eaDir')
        continue
    end

    thisSkymap = fullfile(skymaps(ii).folder, skymaps(ii).name);

    ourDB.contentCreate('collection Name','PBRTResources', ...
        'type','skymap', ...
        'filepath',thisSkymap,...
        'name',skymaps(ii).name,...
        'category','outdoor',... % indoor or outdoor
        'mainfile',thisSkymap,...
        'source','real',... % real or synthetic
        'tags','',... % time of day
        'sizeInMB',piDirSizeGet(thisSkymap,remoteServer)/1024^2,... % MB
        'description','min: 0; mean: 0.291; max: 1',...
        'format','exr');
    fprintf('[INFO]: %s is added.\n', skymaps(ii).name);

end
remoteSkymaps = ourDB.contentFind('PBRTResources','type','skymap', 'show',true);




