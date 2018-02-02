
Import-Module -Force $PSScriptRoot\..\PSSSH\PSSSH.psm1

Describe 'Invoke-SSHCommand' {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should find the plink executable' {
            Test-Path $PSScriptRoot\..\PSSSH\bin\plink.exe | Should be $true
        }
    }
}