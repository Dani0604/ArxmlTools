classdef ArxmlFindTests < matlab.unittest.TestCase

    methods (TestClassSetup)
        % Shared setup for the entire test class
        function classSetup(testCase)
            import matlab.unittest.constraints.IsEqualTo
        end
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)
        % Test methods

        function ShallFindFirstLevelArPackage(testCase)
            %% Setup
            arxml = arxmlTools.ArxmlFile(which("myArchitecture_datatype.arxml"));

            %% Method
            [outStruct, path] = arxml.find("/DataTypes");

            %% Assertion
            assertClass(testCase, outStruct, "struct");
            verifyThat(testCase, path, ...
                matlab.unittest.constraints.IsEqualTo({'AR_PACKAGES', 'AR_PACKAGE',  {1}}))
            %% Teardown
        end

        function ShallFindElementInVector(testCase)
            %% Setup
            arxml = arxmlTools.ArxmlFile(which("myArchitecture_datatype.arxml"));

            %% Method
            [outStruct, path] = arxml.find("/DataTypes/ApplDataTypes/Enum2");

            %% Assertion 
            assertClass(testCase, outStruct, "struct");
            verifyThat(testCase, path, ...
                matlab.unittest.constraints.IsEqualTo({'AR_PACKAGES', ...
                                                       'AR_PACKAGE', {1}, ...
                                                       'AR_PACKAGES', ...
                                                       'AR_PACKAGE', {1}, ...
                                                       'ELEMENTS', ...
                                                       'APPLICATION_PRIMITIVE_DATA_TYPE', {2}}));
            %% Teardown
        end

        function ShallGiveBackEmptyArray(testCase)
            %% Setup
            arxml = arxmlTools.ArxmlFile(which("myArchitecture_datatype.arxml"));

            %% Method
            [outStruct, path] = arxml.find("/DataTypes/ApplDataTypes/Enum5");

            %% Assertion 
            verifyEmpty(testCase, outStruct);
            verifyEmpty(testCase, path);
            %% Teardown
        end
    end
end