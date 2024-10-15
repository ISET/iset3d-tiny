classdef isetdb < handle
    % Initialize an ISET database object.  
    % 
    properties
        dbServer    = "localhost"
        dbPort      = 27017
        dbName      = "iset"
        dbImage     = "mongodb"
        dbUsername  = "demo"
        dbPassword  = "demopass"
        connection
    end

    methods
        function obj = isetdb(options)
            % The values can be overwritten in the call to isetdb in the
            % form isetdb("dbProp", "dbPropValue", etc).  If they are not,
            % they are overwritten by the "db" pref field, if not we
            % provide generic values
            arguments
                options.dbServer
                options.dbPort
                options.dbName
                options.dbImage
                options.dbUsername
                options.dbPassword
                options.noconnect = false; %usually we want to connect at creation
            end

            props = properties(obj);
            for ii=1:numel(props)
                if strcmp(props{ii},"connection")
                    % obj.connection should only be set by calling mongoc()
                    continue;
                end
                if isfield(options, props{ii})
                    obj.(props{ii}) = options.(props{ii});
                else
                    obj.(props{ii}) = getpref("db",props{ii},obj.(props{ii}));
                end
            end
            if ~options.noconnect
                obj.connection = mongoc(obj.dbServer, obj.dbPort, obj.dbName, ...
                UserName=obj.dbUsername, Password=obj.dbPassword);
            end
        end

        function connect(obj)
        % default is a local Docker container, but we also want
        % to support storing remotely to a running instance
           
            %DB Connect to db instance
            %   or start it if needed

            switch obj.dbServer
                case 'localhost'
                    % If you are on the machine that might have the
                    % Mongo database running (at Stanford is mux or
                    % orange) then we see whether it's running
                    [~, result] = system('docker ps | grep mongodb');

                    % If it is not running, start it
                    if strlength(result) == 0
                        % NOTE: Could be a dead process, sigh.
                        runme = ['docker run --name mongodb -d -v' ...
                            obj.dbDataFolder, ':/data/db mongo'];                            
                        [status,result] = system(runme);
                        if status ~= 0
                            error("Unable to start database with error: %s",result);
                        end
                    end
            end

            % Open the connection to the mongo database
            % succeeds or throws an error.  We could do a 'try' and 'catch' if
            % we want to avoid blowing up entirely
            obj.connection = mongoc(obj.dbServer, obj.dbPort, obj.dbName, ...
                UserName=obj.dbUsername, Password=obj.dbPassword);
        end  

        % How we close the connection.
        % If we had an sftp, we should be using fclose()
        function close(obj)
            close(obj.connection);
        end

        % List the collection names
        function [outlist] = collectionList(obj,isprint)
            % ourDB = isetdb.ISETdb()
            % ourDB.colletionlist('collections')
            outlist = obj.connection.CollectionNames;
            if exist('isprint','var') && ~isprint, return;end
            indices = (1:length(outlist))';
            T = table(indices,outlist, 'VariableNames', {'Index', 'Collection Items'});
            disp(T);
        end

        function collectionCreate(obj,name)
            % name is a new collection that we are creating.  It will
            % not overwrite an existing collection.  To see the
            % current collections use isetdb.collectionList;
            %
            if ~ismember(name,obj.connection.CollectionNames)
                createCollection(obj.connection,name);
            else
                fprintf('[INFO]: Collection %s already exists.\n',name);
            end
        end

        % We need a collectionRemove
        function collectionDelete(obj,name)
            fprintf('collectionDelete is not yet implemented.\n');
        end

        % Content is within a collection
        function count = contentRemove(obj,collection, queryStruct)

            % This should be JSON-style Mongo Query.  
            % queryString = queryConstruct(queryStruct);
            queryString = jsonencode(queryStruct);
            try
                % count = remove(obj.connection, collection, Query = queryString);
                count = remove(obj.connection, collection, queryString);
            catch
                count = 0;
            end
        end

    end
    methods (Static = true)
        setDBUserPrefs();
    end
end

