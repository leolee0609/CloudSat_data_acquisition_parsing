function [A2dDataSet, A3dDataSet] = readABatchOfHdfSwathData(folderPath, fieldNames, footprintPks)
% the function reads all the hdf-eos data in folderPath and returns the
% 2 datasets: The first one with 2d geolocation as the primary key,
% recording the 2d attributes without the vertical dimension; Whereas the
% second dataset records 3d georeferenced attributes
% NOTE: You MUST specify x, y, z geolocation fields in A3dGeoFieldNames,
% which would be used as the primary keys

% first, find all hdf files under folderPath
filePaths = findHDFFiles(folderPath);
disp('List of file paths:');
disp(filePaths);

A2dFieldNames = []; % attributes georeferenced in 2d
A3dFieldNames = []; % attributes georeferenced in 3d

sampleS = hdfinfo(filePaths{1}, "eos");

recordsCt = 0;
% split the fieldNames into 2d georeferenced and 3d georeferenced
for fieldNo = 1: numel(fieldNames)
    fieldName = fieldNames(fieldNo);
    sampleData = hdfread(sampleS.Swath, "Fields", fieldName);
    fieldShape = size(sampleData);
    fieldVerticalBinsCt = fieldShape(1);
    recordsCt = fieldShape(2);
    if fieldVerticalBinsCt == 1
        A2dFieldNames = [A2dFieldNames, fieldName];
    else
        A3dFieldNames = [A3dFieldNames, fieldName];
    end
end

% parse the files and gather datasets
errmsg = sprintf("Start parsing a batch of data under %s, overall %d hdf files.", folderPath, numel(filePaths));
fprintf(2, errmsg);
A2dDataSet = zeros(1 + numel(filePaths) * recordsCt * 2, numel(footprintPks) + numel(A2dFieldNames));
A3dDataSet = zeros(1 + numel(filePaths) * recordsCt * 125 * 2, numel(footprintPks) + 1 + numel(A3dFieldNames));
A2dDatasetHeader = [footprintPks, A2dFieldNames];
A3dDatasetHeader = [footprintPks, "bin_number", A3dFieldNames];
A2dDataSet(1, :) = A2dDatasetHeader;
A3dDataSet(1, :) = A3dDatasetHeader;
for fileNo = 1: numel(filePaths)
    filePath = filePaths{fileNo};
    A2dDataSubSet = A2dDatasetParsing(filePath, A2dFieldNames, footprintPks);
    A3dDataSubSet = A3dDatasetParsing(filePath, A3dFieldNames, footprintPks);
    recordsCt = size(A2dDataSubSet, 1);

    A2dsubDatasetStartLineNo = (fileNo - 1) * recordsCt + 1;
    A2dsubDatasetEndLineNo = A2dsubDatasetStartLineNo + recordsCt - 1;
    A2dDataSet(A2dsubDatasetStartLineNo: A2dsubDatasetEndLineNo, :) = A2dDataSubSet;

    A3dsubDatasetStartLineNo = 125 * (fileNo - 1) * recordsCt + 1;
    A3dsubDatasetEndLineNo = A3dsubDatasetStartLineNo + recordsCt * 125 - 1;
    A3dDataSet(A3dsubDatasetStartLineNo: A3dsubDatasetEndLineNo, :) = A3dDataSubSet;

    errmsg = sprintf("%d/%d hdf files completed...", fileNo, numel(filePaths));
    fprintf(2, errmsg);
    
end

% remove the zero rows
idx = find(~all(A3dDataSet == 0, 2), 1, 'last');
A3dDataSet = A3dDataSet(1:idx, :);

idx = find(~all(A2dDataSet == 0, 2), 1, 'last');
A2dDataSet = A2dDataSet(1:idx, :);

end
