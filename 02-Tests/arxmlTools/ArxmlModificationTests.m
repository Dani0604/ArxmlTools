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
    
    %% Add new elements
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

        function ReceiverComSpecShallBeAdded(testCase)
            %% Setup
            arxml = arxmlTools.ArxmlFile(testCase.FilePath);
            comSpec = readstruct("receiverComspec.json");
            qualifiedPath = "/Components/Component1/InBus";
            %% Method
            arxml.add(qualifiedPath, "REQUIRED_COM_SPECS", "NONQUEUED_RECEIVER_COM_SPEC", comSpec);
            %% Assertion
            s = arxml.find(qualifiedPath);
            testCase.assertLength(s.REQUIRED_COM_SPECS.NONQUEUED_RECEIVER_COM_SPEC, 2);
            testCase.assertThat(s.REQUIRED_COM_SPECS.NONQUEUED_RECEIVER_COM_SPEC(2), ...
                matlab.unittest.constraints.IsEqualTo(comSpec));
            %% Teardown
        end

        function ShallSendErrorMsgIfPathCannotFind(testCase)
            %% Setup
            errorSent = false;
            arxml = arxmlTools.ArxmlFile(testCase.FilePath);
            comSpec = readstruct("receiverComspec.json");
            qualifiedPath = "/Components/Component1/InBusNotValid";
            
            s = arxml.Data;
            
            listener(arxml, "LogEvent", @(src, event) errorRaised(src, event));
            %% Method
            arxml.add(qualifiedPath, "REQUIRED_COM_SPECS", "NONQUEUED_RECEIVER_COM_SPEC", comSpec);
           
            %% Assertion
            testCase.assertTrue(errorSent);
            % Data shall remain unchanged
            testCase.assertThat(arxml.Data, ...
                matlab.unittest.constraints.IsEqualTo(s));

            function errorRaised(~, event)
                if event.Severity == logging.Severity.Error
                    errorSent = true;
                end
            end

            %% Teardown
        end
        
    end

    %% Modify elements
    methods (Test)
        
        function PropertyShallBeModified(testCase)
            %% Setup
            arxml = arxmlTools.ArxmlFile(testCase.FilePath);
            qualifiedPath = "/Components/Component1/InBus";
            port.REQUIRED_INTERFACE_TREF.DESTAttribute = "MODE-SWITCH-INTERFACE";
            port.REQUIRED_INTERFACE_TREF.Text = "/Interfaces/newInterface";
            %% Method
            arxml.modify(qualifiedPath, port);
            %% Assertion

            s = arxml.find(qualifiedPath);
            testCase.assertThat(s.REQUIRED_INTERFACE_TREF, ...
                matlab.unittest.constraints.IsEqualTo(port.REQUIRED_INTERFACE_TREF));
            %% Teardown
        end
    end
end

