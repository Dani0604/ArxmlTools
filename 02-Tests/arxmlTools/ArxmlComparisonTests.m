classdef ArxmlComparisonTests < matlab.unittest.TestCase

    methods (TestClassSetup)
        % Shared setup for the entire test class
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)
        % Test methods

        function ComparisonShallPassForTheSameData(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype.arxml");
            rightArxml = which("myArchitecture_datatype_copy.arxml");

            %% Method + Assertion
            testCase.comparisonShallPass(leftArxml, rightArxml);
        end

        function AdditionalElementShallBeFound(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype.arxml");
            rightArxml = which("myArchitecture_datatype_missingelement.arxml");
            
            %% Method + Assertion  
            testCase.comparisonShallFail(leftArxml, rightArxml)
        end

        function MissingElementShallBeFound(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype.arxml");
            rightArxml = which("myArchitecture_datatype_additionalelement.arxml");

            %% Method + Assertion
            testCase.comparisonShallFail(leftArxml, rightArxml)
        end
   
        function ChangedDoubleShallBeFound(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype.arxml");
            rightArxml = which("myArchitecture_datatype_changedDouble.arxml");

            %% Method + Assertion
            testCase.comparisonShallFail(leftArxml, rightArxml)
        end

        function ChangedStringShallBeFound(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype.arxml");
            rightArxml = which("myArchitecture_datatype_changedString.arxml");

            %% Method + Assertion
            testCase.comparisonShallFail(leftArxml, rightArxml)
        end
      
        function ShallPassWithComplexLeafElements(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype_complexLeaf.arxml");
            rightArxml = which("myArchitecture_datatype_complexLeafCopy.arxml");
            
            %% Method + Assertion
            testCase.comparisonShallPass(leftArxml, rightArxml);
        end
   
        function ShallFailWithModifiedComplexLeafElements(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype_complexLeaf.arxml");
            rightArxml = which("myArchitecture_datatype_complexLeafModified.arxml");
            
            %% Method + Assertion
            testCase.comparisonShallFail(leftArxml, rightArxml);
        end

        function ShallFailWithAdditionalComplexLeafElements(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype_complexLeaf.arxml");
            rightArxml = which("myArchitecture_datatype_complexLeafMissingElement.arxml");
            
            %% Method + Assertion
            testCase.comparisonShallFail(leftArxml, rightArxml);
        end
        
        function ShallFailWithMissingComplexLeafElements(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype_complexLeaf.arxml");
            rightArxml = which("myArchitecture_datatype_complexLeafAdditionalElement.arxml");
            
            %% Method + Assertion
            testCase.comparisonShallFail(leftArxml, rightArxml);
        end

        function ShallWorkWithEmptyObjectsOnRightSide(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype.arxml");
            rightArxml = which("myArchitecture_datatype_wEmptyObject.arxml");
            
            %% Method + Assertion
            testCase.comparisonShallFail(leftArxml, rightArxml);
        end

        function ShallWorkWithEmptyObjectsOnLeftSide(testCase)
            %% Setup
            leftArxml = which("myArchitecture_datatype_wEmptyObject.arxml");
            rightArxml = which("myArchitecture_datatype.arxml");
            
            %% Method + Assertion
            testCase.comparisonShallFail(leftArxml, rightArxml);
        end
   end

   methods (Access=private)
       function comparisonShallPass(testCase, leftArxml, rightArxml)
           
       
            leftFile = arxmlTools.ArxmlFile(leftArxml);
            rightFile = arxmlTools.ArxmlFile(rightArxml);

            listener(leftFile, "LogEvent", @(src, event) shallNotBeCalled(src, event));

            %% Method
            equal = compare(leftFile, rightFile);

            %% Assertion
            testCase.verifyTrue(equal);

            function shallNotBeCalled(~, event)
                if event.Severity > logging.Severity.Info
                    testCase.verifyFail("LogEvent raised when the comparison shall pass.")
                end
            end

            %% Teardown

       end

        function comparisonShallFail(testCase, leftArxml, rightArxml)
           
            leftFile = arxmlTools.ArxmlFile(leftArxml);
            rightFile = arxmlTools.ArxmlFile(rightArxml);

            listener(leftFile, "LogEvent", @(src, event) shallBeCalled(src, event));
            isCalled = false;
            %% Method
            equal = compare(leftFile, rightFile);

            %% Assertion
            testCase.verifyFalse(equal);
            testCase.verifyTrue(isCalled);
            function shallBeCalled(~, event)
                if event.Severity > logging.Severity.Info
                    isCalled = true;
                end
            end

            %% Teardown

       end
   end
end