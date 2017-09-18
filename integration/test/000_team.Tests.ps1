Set-StrictMode -Version Latest

Get-Module team | Remove-Module -Force
Import-Module $PSScriptRoot\..\..\src\team.psm1 -Force

Describe 'Team' {
   Context 'Get-TeamInfo' {
      It 'should return account and default project' {
         $env:TEAM_ACCT = "mydemos"
         $Global:PSDefaultParameterValues['*:projectName'] = 'MyProject'

         $info = Get-TeamInfo

         $info.Account | Should Be "mydemos"
         $info.DefaultProject | Should Be "MyProject"
      }
   }

   Context 'Add-TeamAccount vsts' {
      It 'should set env at process level' {
         $pat = $env:PAT
         $acct = $env:ACCT
         Add-TeamAccount -a $acct -pe $pat

         $info = Get-TeamInfo
         
         $info.DefaultProject | Should Be $null
         $info.Account | Should Be "https://$acct.visualstudio.com"
      }
   }

   Context 'Remove-TeamAccount run as normal user' {
      It 'should clear env at process level' {
         # Act
         Remove-TeamAccount

         # Assert
         $info = Get-TeamInfo
         
         $info.Account | Should Be $null
         $info.DefaultProject | Should Be $null
      }
   }

   Context 'Set-DefaultProject' {
      It 'should set default project' {
         Set-DefaultProject 'MyProject'

         $Global:PSDefaultParameterValues['*:projectName'] | Should be 'MyProject'
      }

      It 'should update default project' {
         $Global:PSDefaultParameterValues['*:projectName'] = 'MyProject'

         Set-DefaultProject -Project 'NextProject'

         $Global:PSDefaultParameterValues['*:projectName'] | Should be 'NextProject'
      }
   }

   Context 'Clear-DefaultProject' {
      It 'should clear default project' {
         $Global:PSDefaultParameterValues['*:projectName'] = 'MyProject'

         Clear-DefaultProject

         $Global:PSDefaultParameterValues['*:projectName'] | Should BeNullOrEmpty
      }
   }
}