function [status, result, containerCommand] = render(obj, thisR, commandonly)
p = inputParser();

p.KeepUnmatched = true;

verbose = 1; % 0, 1, 2
if ~exist('commandonly','var')
    commandonly = false;
end
%% Build up the render command
pbrtFile     = thisR.outputFile;
outputFolder = fileparts(thisR.outputFile);
[sceneFolder,currName,~] = fileparts(pbrtFile);
strparts     = strsplit(sceneFolder,filesep);
sceneFolder  = strparts{end};
iDockerPrefs = getpref('ISETDocker');

% Check that the container is running remotely.  If not, start.
if isfield(iDockerPrefs,'PBRTContainer')
    % Test that the container is running remotely
    result = obj.dockercmd('psfind','string',iDockerPrefs.PBRTContainer);

    % Couldn't find it.  Restart.
    if isempty(result), obj.startPBRT; end
else
    % No PBRTContainer specified, so restart.
    obj.startPBRT();
end

ourContainer = getpref('ISETDocker','PBRTContainer');

if ispc,     flags = '-i ';
else,        flags = '-it ';
end

[~, sceneDir, ~] = fileparts(outputFolder);

if isempty(getpref('ISETDocker','remoteHost'))
    contextFlag = ' --context default ';
else
    contextFlag = [' --context ' getpref('ISETDocker','renderContext')];
end

if strcmpi(obj.device,'gpu')
    device = ' --gpu ';
else
    device = '';
end

% Running remotely.
if ~isempty(getpref('ISETDocker','remoteHost'))
    if ispc
        remoteSceneDir = [getpref('ISETDocker','workDir') '/' sceneFolder];
    else
        remoteSceneDir = fullfile(getpref('ISETDocker','workDir'),sceneFolder);
    end
    % sync files from local folder to remote
    % obj.upload(localDIR, remoteDIR, {'excludes','cellarray'}})
    obj.upload(outputFolder, remoteSceneDir,{'renderings',[currName,'.mat']});

    outF = fullfile(remoteSceneDir,'renderings',[currName,'.exr']);
    
    % check if there is renderings folder
    sceneFolder = dir(obj.sftpSession,fullfile(remoteSceneDir));
    renderingsDir = true;
    for ii = 1:numel(sceneFolder)
        if sceneFolder(ii).isdir && strcmp(sceneFolder(ii).name,'renderings')
            renderingsDir = false;
        end
    end
    if renderingsDir
        mkdir(obj.sftpSession,fullfile(remoteSceneDir,'renderings'));
    end

    renderCommand = sprintf('pbrt %s --outfile %s %s', device, outF, ...
        fullfile(getpref('ISETDocker','workDir'),sceneDir,[currName, '.pbrt']));

    containerCommand = sprintf('docker %s exec %s %s sh -c " %s "',...
        contextFlag, flags, ourContainer, renderCommand);

    if verbose > 0
        fprintf('[INFO]: USE Docker: %s\n', containerCommand);
    end
    if ~commandonly
        renderStart = tic;
        if verbose > 1
            [status, result] = system(containerCommand, '-echo');
            fprintf('[INFO]: Rendered remotely in: %4.2f sec\n', toc(renderStart))
            fprintf('[INFO]: Returned parameter result is\n***\n%s', result);
        elseif verbose == 1

            [status, result] = system(containerCommand);
            if status == 0
                fprintf('[INFO]: Rendered remotely in: %4.2f sec\n', toc(renderStart))
            else
                cprintf('red','[ERROR]: Docker Command: %s\n', containerCommand);
                error('Error Rendering: %s', result);
            end

        else
            [status, result] = system(containerCommand);
        end

        if status == 0
            if ~isempty(getpref('ISETDocker','remoteHost'))

                obj.download(fullfile(remoteSceneDir,'renderings'), fullfile(outputFolder,'renderings'));
            end
        end
    end
else
    % Running locally. -- TODO
    % SceneDir = [getpref('ISETDocker','workDir') '/' sceneFolder]; % this should be local folder
    % outF = fullfile(SceneDir,'renderings',[currName,'.exr']);
    if ~exist(fullfile(outputFolder,'renderings'),'dir'),mkdir(fullfile(outputFolder,'renderings'));end
    outF = fullfile(outputFolder,'renderings',[currName,'.exr']);
    
    % Add support for 'remoteResources' even in local case
    renderCommand = sprintf('pbrt %s --outfile %s %s', device, outF, pbrtFile);

    containerCommand = sprintf('docker %s exec %s %s sh -c " %s "',...
        contextFlag, flags, ourContainer, renderCommand);

    renderStart = tic;
    [status, result] = system(containerCommand);
    if verbose > 0
        if status == 0
            fprintf('[INFO]: Rendered remotely in: %4.2f sec\n', toc(renderStart))
        else
            cprintf('red','[ERROR]: Docker Command: %s\n', containerCommand);
            error('Error Rendering: %s', result);
        end
    end
end

end





