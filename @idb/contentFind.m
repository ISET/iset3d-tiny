function documents = contentFind(obj, collection, varargin)
varargin = ieParamFormat(varargin);
p = inputParser;
p.addParameter('collectionname', '',@ischar);
p.addParameter('type', '',@ischar);
p.addParameter('name', '',@ischar);
p.addParameter('filepath', '',@ischar);
p.addParameter('category', '',@ischar);
p.addParameter('sizeInMB', '',@isnumeric);
p.addParameter('createdat', '',@ischar);
p.addParameter('updatedat', '',@ischar);
p.addParameter('createdby', '',@ischar);
p.addParameter('updatedby', '',@ischar);
p.addParameter('author', '',@ischar);
p.addParameter('tags', '',@ischar);
p.addParameter('description', '',@ischar);
p.addParameter('format', '',@ischar);

% assets and scenes
p.addParameter('mainfile', '',@ischar);
p.addParameter('source','',@ischar);

p.addParameter('show',false,@islogical);

p.parse(varargin{:});
%% Generate SHA256 hash for the content
contentStruct = contentSet(p.Results);
fieldNames = fieldnames(contentStruct);

% Iterate over field names and remove fields with empty values
for i = 1:numel(fieldNames)
    fieldName = fieldNames{i};
    if isempty(contentStruct.(fieldName))
        contentStruct = rmfield(contentStruct, fieldName);
    end
end

queryString = queryConstruct(contentStruct);

try
    if isempty(contentStruct)
        documents = find(obj.connection, collection);
    else
        documents = find(obj.connection, collection, Query = queryString);
    end
catch
    documents = [];
end


if p.Results.show
   disp('---------------------------------------------------------------');
   if numel(documents)>50
        disp('[INFO]: Number of requested items is larger than 20, showing only the first 20 here.')
        disp(struct2table(documents(1:20)));
   else
        disp(struct2table(documents));
   end
   disp('---------------------------------------------------------------');
end

end
function s = contentSet(parameters)
s = struct(...
    'type', parameters.type, ...
    'category', parameters.category, ...
    'name', parameters.name, ...
    'sizeInMB', parameters.sizeInMB, ...
    'mainfile', parameters.mainfile, ...
    'filepath', parameters.filepath, ...
    'description', parameters.description, ...
    'format', parameters.format, ...
    'createdat', parameters.createdat, ...
    'updatedat', parameters.updatedat, ...
    'createdby', parameters.createdby, ...
    'updatedby', parameters.updatedby, ...
    'author', parameters.author, ...
    'tags', parameters.tags, ...
    'source', parameters.source ...
    );
end
