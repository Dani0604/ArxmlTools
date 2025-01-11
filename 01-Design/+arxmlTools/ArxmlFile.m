classdef ArxmlFile 
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        FilePath (:,1) string % Can be non-scalar, if merged
        Data (:,1) struct
    end
    
    methods (Access = public)
        function obj = ArxmlFile(filePath)
            arguments (Input)
                filePath (1,1) string {mustBeFile}
            end

            obj.FilePath = filePath;
            obj.Data = readstruct(obj.FilePath);

        end
        
        function compare(obj1, obj2)
            
        end
    end
end

