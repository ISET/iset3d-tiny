classdef isetdb < handle
    % Initialize an ISET database object.  
    % 
    % This object interacts with the MongoDB that we maintain with
    % scenes, assets and such. At Stanford these are stored on acorn.
    properties
        dbServer  = getpref('db','server','localhost');       
        % port to use and connect to.
        % The standard port is 27017.
        % But Synology at Stanford is set up with this one
        dbPort    = getpref('db','port',49153); 
        dbName = 'iset';
        dbImage = 'mongo';
        connection;
    end

    methods
        % default is a local Docker container, but we also want
        % to support storing remotely to a running instance
        function obj = isetdb(options)

            arguments
                options.dbServer = getpref('db','server','localhost');
                options.dbPort = getpref('db','port',27017);
            end
            obj.dbServer = options.dbServer;
            obj.dbPort = options.dbPort;

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
            obj.connection = mongoc(obj.dbServer, obj.dbPort, obj.dbName);
            if isopen(obj.connection), return;
            else, warning("Unable to connect to iset database");
            end
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
end

