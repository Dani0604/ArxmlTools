classdef ArxmlModificationTests < matlab.unittest.TestCase
    %ARXMLMODIFICATIONTESTS
    properties
        Folder
        FilePath
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.Folder = testCase.createTemporaryFolder();
            copyfile(which("ModificationTests.arxml"), testCase.Folder)
            testCase.FilePath = fullfile(testCase.Folder, "ModificationTests.arxml");
        end
    end
    
    methods (Test)

        function EmptyARPackageShallBeAdded(testCase)
            %% Setup
            arxml = arxmlTools.ArxmlFile(testCase.FilePath);
            ARPackage.ELEMENTS = [];
            ARPackage.SHORT_NAME = "MyPackage";
            %% Method
            arxml.add("/Components", "AR_PACKAGES", "AR_PACKAGE", ARPackage);
            %% Assertion
            testCase.assertTrue(isfield(arxml.Data.AR_PACKAGES.AR_PACKAGE, "AR_PACKAGES"));
            testCase.assertTrue(isfield(arxml.Data.AR_PACKAGES.AR_PACKAGE.AR_PACKAGES, "AR_PACKAGE"))
            testCase.assertThat(arxml.Data.AR_PACKAGES.AR_PACKAGE.AR_PACKAGES.AR_PACKAGE, ...
                matlab.unittest.constraints.IsEqualTo(ARPackage));
            %% Teardown
            
        end
    end
end

