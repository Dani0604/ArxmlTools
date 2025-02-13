classdef ArxmlFile  < logging.ILoggable
% ArxmlFile Class for handling ARXML files
    % This class provides functionalities for importing, comparing, modifying,
    % exporting ARXML files, and finding ARXML elements based on fully qualified paths.
    %
    % Main Functionalities:
    % - Importing ARXML files
    % - Comparing ARXML files
    % - Modifying ARXML files
    % - Exporting ARXML files
    % - Finding ARXML elements based on fully qualified paths
    %
    % Planned Functionalities:
    % - ARXML file merging
    %
    % Properties:
    % - FilePath: Path to the ARXML file
    % - Data: Content of the ARXML file, stored in a MATLAB struct format
    %
    % Examples:
    %   arxml = ArxmlFile("path/to/file.arxml");
    %   arxml.compare(otherArxmlFile);
    %   arxml.modify("/path/to/element", struct('Field', 'Value'));
    %   arxml.export("path/to/exported/file.arxml");
    %
    % See also: logging.ILoggable, readstruct, writestruct

    properties (SetAccess = private)
        FilePath (:,1) string % Arxml file path, can be non-scalar, if merged (TBD)
        Data (1,1) struct % Arxml file content, stored in a MATLAB struct format
    end

    properties (Access = private)
        logger (:,1) logging.ILogger = logging.CommandWindowLogger.empty % Logger classes
    end

    % Public interfaces
    methods (Access = public)
        function obj = ArxmlFile(filePath, opts)
            % ArxmlFile Constructor
            % Creates an instance of the ArxmlFile class.
            %
            % Syntax:
            %   obj = ArxmlFile(filePath, opts)
            %
            % Inputs:
            %   filePath - (string) Path to the ARXML file
            %   opts - (struct) Options for logging
            %       opts.CWLogging - (logical) Enable command window logging (default: true)
            %       opts.FileLogging - (logical) Enable file logging (default: false)
            %       opts.Severity - (logging.Severity) Logging severity level (default: logging.Severity.Info)
            %
            % Outputs:
            %   obj - Instance of the ArxmlFile class
            arguments (Input)
                filePath (1,1) string {mustBeFile} % 
                opts.CWLogging (1,1) logical = true
                opts.FileLogging (1,1) logical = false
                opts.Severity (1,1) logging.Severity = logging.Severity.Info
            end

            obj.FilePath = filePath;
            obj.Data = readstruct(obj.FilePath, "FileType", "xml");

            if opts.CWLogging
                obj.logger(1) = logging.CommandWindowLogger;
                obj.logger(1).subscribe(obj, opts.Severity);
            end
            if opts.FileLogging
                obj.logger(end+1) = logging.FileLogger("LogFile", "./arxmlComparisonLogs.txt");
                obj.logger(end).subscribe(obj, opts.Severity);
            end
            obj.info(sprintf("ArxmlFile object created: %s", obj.FilePath));
        end

        function equal = compare(objLeft, objRight)
            % compare Compares two ARXML files
            % 
            % Syntax:
            %   equal = compare(arxmlFileLeft, arxmlFileRight)
            %
            % Inputs:
            %   objLeft - (ArxmlFile) Left ARXML file object
            %   objRight - (ArxmlFile) Right ARXML file object
            %
            % Outputs:
            %   equal - (logical) True if the files are equal, false otherwise
            %   Logs the results of the comparison with the Logger object
            %   configured in the constructor
            arguments (Input)
                objLeft (1,1) arxmlTools.ArxmlFile
                objRight (1,1) arxmlTools.ArxmlFile
            end
            objLeft.info(sprintf("-------------- Comparison for files %s and %s started --------------\n\n", objLeft.FilePath, objRight.FilePath));
            equal = compareStruct(objLeft, objLeft.Data, objRight.Data, "/");
            objLeft.info(sprintf("\n-------------- Comparison for files %s and %s finished --------------\n\n", objLeft.FilePath, objRight.FilePath));
        end

        function open(obj)
            % open Opens the ARXML file in the MATLAB editor
            %
            % Syntax:
            %   obj.open
            %
            % Inputs:
            %   obj - (ArxmlFile) ARXML file object
            arguments (Input)
                obj (1,1) arxmlTools.ArxmlFile
            end
            edit(obj.FilePath);
        end

        function export(obj, path)
            % export Exports the ARXMLFile object as an Arxml file to a specified path
            %
            % Syntax:
            %   obj.export(path)
            %
            % Inputs:
            %   obj - (ArxmlFile) ARXML file object
            %   path - (string) Path to export the ARXML file (default: obj.FilePath)
            arguments (Input)
                obj (1,1) arxmlTools.ArxmlFile
                path (1,1) string = obj.FilePath
            end
            warning('off', 'MATLAB:io:xml:common:StartsWithXMLElementName');
            writestruct(obj.Data, path, "FileType", "xml","StructNodeName", "AUTOSAR");
            warning('on', 'MATLAB:io:xml:common:StartsWithXMLElementName');

            lines = readlines(path);

            % Correct Texts fields
            idx = find(contains(lines, "<Text>"));
            texts = extractBetween(lines(idx), "<Text>", "</Text>");
            lines(idx-1) = lines(idx-1) + texts + erase(lines(idx+1), " ");
            lines([idx;idx+1]) = [];

            % Correct property names: '_'->'-'
            xmlPropsCell = regexp(lines,"<(/?\w+)[^>]*>", "tokens");
            for ii = 1:length(xmlPropsCell)
                xmlProps =  [xmlPropsCell{ii}{:}];
                if ~isempty(xmlProps)
                    lines(ii) = replace(lines(ii), xmlProps(1), replace(xmlProps(1), "_", "-"));
                end
            end

            % Correct xsi attributes
            idx = startsWith(lines, "<AUTOSAR");
            lines(idx) = replace(lines(idx), "xmlns_xsi", "xmlns:xsi");
            lines(idx) = replace(lines(idx), "xsi_schemaLocation", "xsi:schemaLocation");

            writelines(lines, path)
        end

        function add(obj, qualifiedPath, field, type, element)
            % add Adds an element to the ARXML file
            %
            % Syntax:
            %   obj.add(qualifiedPath, field, type, element)
            %
            % Inputs:
            %   obj - (ArxmlFile) ARXML file object
            %   qualifiedPath - (string) Fully qualified path to the element
            %   field - (string) Field name
            %   type - (string) Type of the element
            %   element - (struct) Element to add
            arguments (Input)
                obj (1,1) arxmlTools.ArxmlFile
                qualifiedPath (1,1) string
                field (1,1) string
                type (1,1) string
                element (:,1) struct
            end

            [~, path] = obj.find(qualifiedPath);

            if ~isempty(path)
                s = getfield(obj.Data, path{:});
                if isfield(s, field) && isfield(s.(field), type)
                    s.(field).(type) = [s.(field).(type); element];
                else
                    s.(field).(type) = element;
                end

                obj.Data = setfield(obj.Data, path{:}, s);

            else
                obj.error(sprintf("Couldn't find object with qualifiedPath: '%s'", qualifiedPath));
            end
        end

        function modify(obj, qualifiedPath, sIn, keys)
            % modify Modifies an element in the ARXML file
            %
            % Syntax:
            %   obj.modify(qualifiedPath, sIn, keys)
            %
            % Inputs:
            %   obj - (ArxmlFile) ARXML file object
            %   qualifiedPath - (string) Fully qualified path to the element
            %   sIn - (struct) Structure with new values
            %   keys - (string) Keys to identify an element in an array
            %   (default: "SHORT-NAME") (Not used yet)
            arguments (Input)
                obj (1,1) arxmlTools.ArxmlFile
                qualifiedPath (1,1)
                sIn (:,1) struct
                keys (:,1) string = "SHORT-NAME" % Keys to identify an element in an array
            end

            [~, path] = obj.find(qualifiedPath);
            if ~isempty(path)
                s = getfield(obj.Data, path{:});
                fieldNames = string(fieldnames(sIn));
                newFields = [];
                for field = fieldNames'
                    if ~isfield(s, field)
                        newFields = [newFields field];
                    end
                    s.(field) = sIn.(field);
                end
                % Need to add the new fields to struct arrays
                if ~isempty(newFields) && ~isa(path{end}, 'char')
                    sVector = getfield(obj.Data, path{1:end-1});
                    for newField = newFields
                        [sVector.(newField)] = deal([]);
                    end
                    sVector(path{end}{:}) = s;
                    obj.Data = setfield(obj.Data, path{1:end-1}, sVector);
                else
                    obj.Data = setfield(obj.Data, path{:}, s);
                end
            else
                obj.error(sprintf("Couldn't find object with qualifiedPath: '%s'", qualifiedPath));
            end
        end

        function [outStruct, path] = find(obj, qualifiedPath)
            % find Finds an element in the ARXML file based on the fully qualified path
            %
            % Syntax:
            %   [outStruct, path] = find(obj, qualifiedPath)
            %   
            %   Usage of the path output:
            %   outStruct = obj.Data(path{:});
            %
            % Inputs:
            %   obj - (ArxmlFile) ARXML file object
            %   qualifiedPath - (string) Fully qualified path to the element
            %
            % Outputs:
            %   outStruct - (struct) The found element
            %   path - (cell) Path to the found element within the ARXML structure
            arguments (Input)
                obj (1,1) arxmlTools.ArxmlFile
                qualifiedPath (1,1) string
            end
            [success, path] = obj.findInStruct(obj.Data, split(strip(qualifiedPath,"left", "/"), "/"));
            if success
                outStruct = getfield(obj.Data, path{:});
            else
                outStruct = [];
            end
        end
    end

    %% Modification
    methods (Access = private)
        function [success, subStruct] = addElementToStruct(obj, s, qualifiedPath, type, element)
            arguments (Input)
                obj (1,1)
                s (1,1) struct
                qualifiedPath (1,1) string
                type (1,1) string
                element (1,1) struct
            end

            fieldNames = string(fieldnames(s));
            fieldTypes = arrayfun(@(field) string(class(s.(field))), fieldNames);
            if ~isempty(qualifiedPath)
                path = split(strip(qualifiedPath,"left", "/"), "/");
            end
        end
    end

    %% Comparison
    methods (Access = private)

        function equal = compareStruct(obj, structLeft, structRight, qualifiedPath)
            arguments (Input)
                obj (1,1) arxmlTools.ArxmlFile
                structLeft (1,1) struct
                structRight (1,1) struct
                qualifiedPath (1,1) string
            end
            equal = true;


            leftFieldNames = string(fieldnames(structLeft));
            rightFieldNames = string(fieldnames(structRight));
            % Filter out missing fields
            leftFieldNames = leftFieldNames(arrayfun(@(v) ~any(ismissing(structLeft.(v))), leftFieldNames));
            rightFieldNames = rightFieldNames(arrayfun(@(v) ~any(ismissing(structRight.(v))), rightFieldNames));


            % Update qualifiedPath
            if isfield(structLeft, "SHORT_NAME")
                qualifiedPath = qualifiedPath + structLeft.SHORT_NAME + "/";
            end

            % Check additional fields
            additionalFields = setdiff(leftFieldNames, rightFieldNames);
            if ~isempty(additionalFields)
                arrayfun(@(fieldName) obj.warning(sprintf("Additional ARXML object detected! " + ...
                    "Path: '%s', ObjectName '%s'", qualifiedPath, fieldName)), additionalFields);
                equal = false;
            end

            % Check missing fields
            missingFields = setdiff(rightFieldNames, leftFieldNames);
            if ~isempty(missingFields )
                arrayfun(@(fieldName) obj.warning(sprintf("Missing ARXML object detected! " + ...
                    "Path: '%s', ObjectName '%s'", qualifiedPath, fieldName)), missingFields );
                equal = false;
            end

            %% Check common fields
            commonFields = intersect(leftFieldNames, rightFieldNames);

            for ii = 1:length(commonFields)
                leftValue = structLeft.(commonFields(ii));
                rightValue = structRight.(commonFields(ii));

                % Compare string
                if isa(leftValue, "string") && isa(rightValue, "string")
                    if ~strcmp(leftValue, rightValue) && ~strcmp(commonFields(ii), "UUIDAttribute")
                        obj.warning(sprintf("Incorrect value found! Path: " + ...
                            "'%s', Property: '%s', LeftValue: '%s', RightValue: '%s'", ...
                            qualifiedPath, commonFields(ii), leftValue, rightValue));
                        equal = false;
                    end

                    % Compare double
                elseif isa(leftValue, "double") && isa(rightValue, "double")
                    if leftValue ~= rightValue
                        obj.warning(sprintf("Incorrect value found! Path: " + ...
                            "'%s', Property: '%s', LeftValue: '%d', RightValue: '%d'", ...
                            qualifiedPath, commonFields(ii), leftValue, rightValue));
                        equal = false;
                    end

                    % Compare struct
                elseif isa(leftValue, "struct") && isa(rightValue, "struct")
                    if ~isfield(leftValue, "SHORT_NAME")
                        if isscalar(leftValue) && isscalar(rightValue)
                            equal = equal & obj.compareStruct(leftValue, rightValue, qualifiedPath);
                        elseif obj.isLeaf(leftValue)
                            equal = equal & obj.compareLeafStructVectors(leftValue, rightValue, qualifiedPath, commonFields(ii));
                        else
                            % If there is no short name, and the value is
                            % not scalar, then we cannot identify the
                            % matching pairs.
                            obj.warning(sprintf("Cannot compare property '%s' as it is not scalar, and doesn't have as SHORT-NAME! " + ...
                                "Path: '%s'", commonFields(ii), qualifiedPath));
                        end
                    else
                        equal = equal & obj.compareStructVectors(leftValue, rightValue, qualifiedPath);
                    end
                elseif isa(leftValue, "struct") && rightValue==""
                    obj.warning(sprintf("Additional ARXML element detected! " + ...
                        "Path: '%s', PropertyName '%s', Element: \n%s", qualifiedPath, commonFields(ii), jsonencode(leftValue, "PrettyPrint", true)));
                    equal = false;
                elseif leftValue=="" && isa(rightValue, "struct")
                    obj.warning(sprintf("Missing ARXML element detected! " + ...
                        "Path: '%s', PropertyName '%s', Element: \n%s", qualifiedPath, commonFields(ii), jsonencode(rightValue, "PrettyPrint", true)))
                    equal = false;
                else
                    obj.error(sprintf("Data type for property: '%s' shall be struct, string or double! " + ...
                        "Path: '%s', Data type: %s", commonFields(ii), qualifiedPath, class(leftValue)));
                    equal = false;
                end
            end
        end

        function equal = compareStructVectors(obj, structLeft, structRight, qualifiedPath)
            arguments (Input)
                obj (1,1) arxmlTools.ArxmlFile
                structLeft (:,1) struct
                structRight (:,1) struct
                qualifiedPath (1,1) string
            end
            equal = true;

            leftShortNames = [structLeft.SHORT_NAME];
            rightShortNames = [structRight.SHORT_NAME];

            % Check additional elements
            additionalElements = setdiff(leftShortNames, rightShortNames);
            if ~isempty(additionalElements)
                cellfun(@(elementName) obj.warning(sprintf("Additional ARXML element detected! " + ...
                    "Path: '%s', ElementName '%s'", qualifiedPath, elementName)), additionalElements);
                equal = false;
            end

            % Check missing fields
            missingElements = setdiff(rightShortNames, leftShortNames);
            if ~isempty(missingElements)
                cellfun(@(elementName) obj.warning(sprintf("Missing ARXML element detected! " + ...
                    "Path: '%s', ElementName '%s'", qualifiedPath, elementName)), missingElements );
                equal = false;
            end

            commonShortNames = intersect(leftShortNames, rightShortNames);
            for shortName = commonShortNames
                equal = equal & obj.compareStruct(structLeft([structLeft.SHORT_NAME] == shortName), ...
                    structRight([structRight.SHORT_NAME] == shortName), ...
                    qualifiedPath);
            end
        end

        function equal = compareLeafStructVectors(obj, structLeft, structRight, qualifiedPath, propertyName)
            equal = true;
            %             if strcmp(propertyName, "NONQUEUED_SENDER_COM_SPEC") || strcmp(propertyName, "NONQUEUED_RECEIVER_COM_SPEC")
            %                 return;
            %             end
            idx = zeros(length(structLeft), length(structRight));
            for ii = 1:length(structLeft)
                for jj = 1:length(structRight)
                    idx(ii,jj) = isequal(structLeft(ii), structRight(jj));
                end
            end

            additionalElementIdx = ~any(idx,2);
            additionalElements = structLeft(additionalElementIdx);
            if ~isempty(additionalElements)
                arrayfun(@(elem) obj.warning(sprintf("Additional ARXML element detected in complex leaf object! " + ...
                    "Path: '%s', PropertyName '%s', Element: \n%s", qualifiedPath, propertyName, jsonencode(elem, "PrettyPrint", true))), additionalElements)
                equal = false;
            end

            missingElementIdx = ~any(idx,1);
            missingElements = structRight(missingElementIdx);
            if ~isempty(missingElements)
                arrayfun(@(elem) obj.warning(sprintf("Missing ARXML element detected in complex leaf object! " + ...
                    "Path: '%s', PropertyName '%s', Element: \n%s", qualifiedPath, propertyName, jsonencode(elem, "PrettyPrint", true))), missingElements)
                equal = false;
            end
        end

        function isLeaf = isLeaf(obj, s)
            isLeaf = true;
            fieldNames = fieldnames(s);
            if any(strcmp(fieldNames,"SHORT_NAME"))
                isLeaf = false;
                return;
            end

            for ii = 1:length(fieldNames)
                if isstruct(s(1).(fieldNames{ii}))
                    isLeaf = isLeaf & obj.isLeaf(s(1).(fieldNames{ii}));
                end
            end
        end

    end

    %% Merge
    methods (Access = private)

    end

    %% Find
    methods (Access = private)
        function [success, path] = findInStruct(obj, s, qualifiedPath)
            arguments (Input)
                obj (1,1) arxmlTools.ArxmlFile
                s (1,1) struct
                qualifiedPath (:,1) string
            end
            arguments (Output)
                success (1,1) logical
                path cell
            end
            success = false;
            path = {};

            if isfield(s, "SHORT_NAME")
                if ~strcmp(s.SHORT_NAME, qualifiedPath(1))
                    return;
                elseif strcmp(s.SHORT_NAME, qualifiedPath(1)) && isscalar(qualifiedPath)
                    success = true;
                    return;
                else
                    qualifiedPath = qualifiedPath(2:end);
                end
            end

            fieldNames = fieldnames(s);
            fieldTypes = cellfun(@(field) string(class(s.(field))), fieldNames);

            fieldNames = fieldNames(fieldTypes == "struct");

            for ii = 1:length(fieldNames)
                fieldName = fieldNames{ii};
                for jj = 1:length(s.(fieldName))
                    [success, p] = obj.findInStruct(getfield(s, fieldName, {jj}), qualifiedPath);
                    if success
                        if length(s.(fieldName)) > 1
                            path = [fieldName {{jj}} p];
                        else
                            path = [fieldName p];
                        end
                        return;
                    end
                end
            end
        end
    end
    %% Abstract method implementtions
    methods (Access = public)
        % Abstract method which gives back an identifier of the logger
        % object (e.g., its name)
        function identifier = getQualifiedName(obj)
            [~, identifier, ~] = fileparts(obj.FilePath(1));
        end

        % Abstract method which gives back the list of children.
        % The children shall be created as a subclass of the ILoggable class.
        function children = getChildren(obj)
            children = [];
        end
    end

end

