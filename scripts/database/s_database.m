%%
ieInit; clear ISETdb;
piDockerConfig;
% set up connection to the database, it's 49153 if we are in Stanford
% Network. 
% Question: 
%   1. How to figure out the port number if we are not.
%   2. What if the data is not on acorn?
% 
setpref('db','port',49153);
ourDB = idb.ISETdb();
remoteHost = 'orange.stanford.edu';
remoteUser = 'zhenyiliu';
remoteServer = sftp('orange.stanford.edu','zhenyiliu');
if ~isopen(ourDB.connection),error('No connection to database.');end
collectionName = 'PBRTResources'; % ourDB.collectionCreate(colName);

% docker for rendering scenes 
isetDocker = idocker();

%% Render local scene with remote PBRT
% Make sure you have configured your computer according to this:
%       https://github.com/ISET/iset3d/wiki/Remote-Rendering-with-PBRT-v4
% See /iset3d/tutorials/remote/s_remoteSet.m for remote server
% configuration

% getpref('ISETDocker') % set up by idocker.setUserPrefs()

localFolder = '/Users/zhenyi/git_repo/dev/iset3d/data/scenes/ChessSet';

pbrtFile = fullfile(localFolder, 'ChessSet.pbrt');
thisR = piRead(pbrtFile);
thisR.set('spatial resolution',[100,100]);
piWrite(thisR,'remoterender', getpref('ISET3d','remoteRender'));

scene = piRender(thisR,'docker',isetDocker);
sceneWindow(scene);

%% Add a scene to the database, and render it remotely

thisR.useDB = 1;
remoteDBDir     = '/acorn/data/iset/PBRTResources/scene/ChessSet';
remoteSceneFile = fullfile(remoteDBDir,'ChessSet.pbrt');
recipeMATFile   = fullfile(localFolder,'ChessSet.mat');
sceneName       = 'ChessSet';
save(recipeMATFile,'thisR');

% add info to the database.

ourDB.contentCreate('collection Name',collectionName, ...
    'type','scene', ...
    'filepath',remoteDBDir,...
    'name',sceneName,...
    'category','indoor',...
    'mainfile',[sceneName, '.pbrt'],...
    'source','iset3d',...
    'tags','',...
    'size',piDirSizeGet(localFolder)/1024^2,... % MB
    'format','pbrt');

% upload files to the remote server
isetDocker.upload(localFolder,remoteDBDir);
% remove the mat file from local folder
delete(recipeMATFile);

% render the scene from data base
% Find it
thisScene = ourDB.contentFind(collectionName, 'name',sceneName, 'show',true);
% Get recipe mat
recipeDB = piRead(thisScene,'docker',isetDocker);
% 
recipeDB.set('spatial resolution',[100,100]);
%
piWrite(recipeDB,'remoterender', getpref('ISET3d','remoteRender') );
%
scene = piRender(recipeDB,'docker',isetDocker);
sceneWindow(scene);




