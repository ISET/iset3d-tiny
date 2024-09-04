function subdirName = piSceneDeposit(sceneName)
% Return the subdiretory of the SDR deposit for this sceneName
%
% Synopsis
%  subdirName = piSceneDeposit(sceneName)
%
% The scenes are all in the 'ISET 3d scenes' deposit. Within that
% deposit, they are in subdirectories. This is the subdirectory name,
% and we use this as part of ieWebGet().
%
% This should match the case statements in piRecipeDefault
%
% See also
%   piSceneWebTest, ieWebGet

% Find the scene on the Stanford Digital Repository
switch sceneName
    case {'bathroom','bathroom2','bedroom','classroom',...
            'cornell-box','glass-of-water','lamp',...
            'living-room-1','living-room-2','living-room-3',...
            'staircase','staircase2','teapot-full',...
            'veach-ajar','veach-bidir','veach-mis'}
        subdirName = 'bitterli';

    case {'barcelona-pavilion-day','barcelona-pavilion-night',...
            'bistro', ...
            'bunny-cloud','bunny-fur',...
            'bmw-m6',...
            'clouds','contemporary-bathroom','crown',...
            'dambreak',...
            'disney-cloud','ganesha','hair','head-pbrtv4',...
            'killeroos', 'kitchen','landscape',...
            'lte-orb','pbrt-book','sanmiguel',...            
            'smoke-plume','sportscar',...
            'sssdragon','transparent-machines',...
            'zero-day'
            }
        subdirName = 'pbrtv4';

    case {'arealight','bunny','car','characters','checkerboard',...
            'chessset','coordinate','cornell_box','cornell-box-iset3d',...
            'cornellboxreference','flashcards',...
            'flatsurface','flatsurfacewhitetexture',...
            'head', ...
            'lettersatdepth','low-poly-tax','macbethchecker','macbethchart',...
            'materialball','materialball_cloth','simplescene',...
            'slantededge','snellenatdepth','sphere',...
            'stepfunction','teapot-set','testplane'}
        subdirName = 'iset3d-scenes';

    otherwise
        error('Scene not local and not on SDR: %s\n',sceneName);
end

end