Set-StrictMode -Version Latest

InModuleScope VSTeam {
   [VSTeamVersions]::Account = 'https://dev.azure.com/test'

   Describe 'workitems' {
      # Mock the call to Get-Projects by the dynamic parameter for ProjectName
      Mock Invoke-RestMethod { return @() } -ParameterFilter {
         $Uri -like "*_apis/projects*"
      }

      . "$PSScriptRoot\mocks\mockProjectNameDynamicParamNoPSet.ps1"

      $obj = @{
         id  = 47
         rev = 1
         url = "https://dev.azure.com/test/_apis/wit/workItems/47"
      }

      $collection = @{
         count = 1
         value = @($obj)
      }

      Context 'Add-WorkItem' {
         Mock Invoke-RestMethod {
            # If this test fails uncomment the line below to see how the mock was called.
            # Write-Host $args

            return $obj
         }

         It 'Without Default Project should add work item' {
            $Global:PSDefaultParameterValues.Remove("*:projectName")
            Add-VSTeamWorkItem -ProjectName test -WorkItemType Task -Title Test

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Post' -and
               $Body -like '`[*' -and # Make sure the body is an array
               $Body -like '*`]' -and # Make sure the body is an array
               $ContentType -eq 'application/json-patch+json' -and
               $Uri -eq "https://dev.azure.com/test/test/_apis/wit/workitems/`$Task?api-version=$([VSTeamVersions]::Core)"
            }
         }

         It 'With Default Project should add work item' {
            $Global:PSDefaultParameterValues["*:projectName"] = 'test'
            Add-VSTeamWorkItem -ProjectName test -WorkItemType Task -Title Test1 -Description Testing

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Post' -and
               $Body -like '`[*' -and # Make sure the body is an array
               $Body -like '*Test1*' -and
               $Body -like '*Testing*' -and
               $Body -like '*/fields/System.Title*' -and
               $Body -like '*/fields/System.Description*' -and
               $Body -like '*`]' -and # Make sure the body is an array
               $ContentType -eq 'application/json-patch+json' -and
               $Uri -eq "https://dev.azure.com/test/test/_apis/wit/workitems/`$Task?api-version=$([VSTeamVersions]::Core)"
            }
         }

         It 'With Default Project should add work item with parent' {
            $Global:PSDefaultParameterValues["*:projectName"] = 'test'
            Add-VSTeamWorkItem -ProjectName test -WorkItemType Task -Title Test1 -Description Testing -ParentId 25

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Post' -and
               $Body -like '`[*' -and # Make sure the body is an array
               $Body -like '*Test1*' -and
               $Body -like '*Testing*' -and
               $Body -like '*/fields/System.Title*' -and
               $Body -like '*/fields/System.Description*' -and
               $Body -like '*/relations/-*' -and
               $Body -like '*_apis/wit/workitems/25*' -and
               $Body -like '*System.LinkTypes.Hierarchy-Reverse*' -and
               $Body -like '*`]' -and # Make sure the body is an array
               $ContentType -eq 'application/json-patch+json' -and
               $Uri -eq "https://dev.azure.com/test/test/_apis/wit/workitems/`$Task?api-version=$([VSTeamVersions]::Core)"
            }
         }
      }

      Context 'Update-WorkItem' {
         Mock Invoke-RestMethod {
            # If this test fails uncomment the line below to see how the mock was called.
            # Write-Host $args

            return $obj
         }
         # have to mock the call to Get-VsTeamWorkItem for Update-VSTeamWorkItem unit tests
         # This is because Get-VsTeamWorkItem is called in Update-VsTeamWorkItem in order to
         # get already existing tags, so we don't blow them away when we PATCH.
         Mock Get-VsTeamWorkItem {
            return @{
               Tags = @('MockedTag')
            }
         }

         It 'Without Default Project should update work item' {
            $Global:PSDefaultParameterValues.Remove("*:projectName")
            Update-VSTeamWorkItem -Id 1 -Title Test -Tag TestTag1 -Force

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Patch' -and
               $Body -like '`[*' -and # Make sure the body is an array
               $Body -like '*`]' -and # Make sure the body is an array
               $ContentType -eq 'application/json-patch+json' -and
               $Uri -eq "https://dev.azure.com/test/_apis/wit/workitems/1?api-version=$([VSTeamVersions]::Core)"
            }
         }

         It 'With Default Project should update work item' {
            $Global:PSDefaultParameterValues["*:projectName"] = 'test'
            Update-VSTeamWorkItem -Id 1 -Title Test1 -Description Testing -Tag TestTag1 -Force

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Patch' -and
               $Body -like '`[*' -and # Make sure the body is an array
               $Body -like '*Test1*' -and
               $Body -like '*Testing*' -and
               $Body -like '*/fields/System.Title*' -and
               $Body -like '*/fields/System.Description*' -and
               $Body -like '*TestTag1*' -and
               $Body -like '*/fields/System.Tags*' -and
               $Body -like '*`]' -and # Make sure the body is an array
               $ContentType -eq 'application/json-patch+json' -and
               $Uri -eq "https://dev.azure.com/test/_apis/wit/workitems/1?api-version=$([VSTeamVersions]::Core)"
            }
         }
      }

      Context 'Show-VSTeamWorkItem' {
         Mock Show-Browser { }

         it 'should return url for mine' {
            Show-VSTeamWorkItem -projectName project -Id 15

            Assert-MockCalled Show-Browser -Exactly -Scope It -Times 1 -ParameterFilter { $url -eq 'https://dev.azure.com/test/project/_workitems/edit/15' }
         }
      }

      Context 'Get-WorkItem' {

         It 'Without Default Project should add work item' {
            Mock Invoke-RestMethod {
               # If this test fails uncomment the line below to see how the mock was called.
               # Write-Host $args

               return $collection
            }

            Get-VSTeamWorkItem -Ids 47, 48

            # With PowerShell core the order of the query string is not the
            # same from run to run!  So instead of testing the entire string
            # matches I have to search for the portions I expect but can't
            # assume the order.
            # The general string should look like this:
            # https://dev.azure.com/test/test/_apis/wit/workitems/?api-version=$([VSTeamVersions]::Core)&ids=47,48&`$Expand=None&errorPolicy=Fail
            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Uri -like "*https://dev.azure.com/test/_apis/wit/workitems/*" -and
               $Uri -like "*api-version=$([VSTeamVersions]::Core)*" -and
               $Uri -like "*ids=47,48*" -and
               $Uri -like "*`$Expand=None*" -and
               $Uri -like "*errorPolicy=Fail*"
            }
         }

         It 'With Default Project should add work item' {
            Mock Invoke-RestMethod {
               # If this test fails uncomment the line below to see how the mock was called.
               # Write-Host $args
               return $obj
            }

            Get-VSTeamWorkItem -Id 47

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Uri -eq "https://dev.azure.com/test/_apis/wit/workitems/47?api-version=$([VSTeamVersions]::Core)&`$Expand=None"
            }
         }
      }
   }
}