#Invoke-sshcommand#################################
#Created By: Jon Mattivi
#Created Date: 20150717
#Modified Date: 20150717
#v1.0 Module for SSH Commands
############################################

function Invoke-sshcommand
{
    [CmdletBinding(DefaultParameterSetName = 'UsePasswordAuthentication')]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$hostname,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$username,
        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$sshcommand,
        [Parameter(Position = 3, Mandatory = $false)]
        [Switch]$autoacceptkey = $true,
        [Parameter(ParameterSetName = 'UsePasswordAuthentication', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$password,
        [Parameter(ParameterSetName = 'UseKeyAuthentication', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$keyfilepath
    )
    
    $rawoutput = @()
    $plink = "$PSScriptRoot\bin\plink.exe"
	
    If ($password)
    {
        If ($autoacceptkey -eq $true)
        {
            $cmd = @(
                "y"
            )
            #Run plink.exe - Auto Accept Host Key
            $acceptkeyoutput = $cmd | & $plink -v $hostname 2>&1
            If ($acceptkeyoutput -like "*Initialised AES-256 SDCTR server->client encryption*")
            {
                $rawoutput = & $plink -v -pw $password $username@$hostname -batch $sshcommand 2>&1
                If ($LastExitCode -ne 0)
                {
                    throw "Errors Encountered!!!! `n $($rawoutput)"
                }
            }
        }
        ElseIf ($autoacceptkey -eq $false)
        {
            #Run plink.exe - Do Not Auto Accept Host Key
            $rawoutput = & $plink -v -pw $password $username@$hostname -batch $sshcommand 2>&1
            If ($LastExitCode -ne 0)
            {
                throw "Errors Encountered!!!! `n $($rawoutput)"
            }
        }
    }
    ElseIf ($keyfilepath)
    {
        if (Test-Path $keyfilepath)
        {
            If ($autoacceptkey -eq $true)
            {
                $cmd = @(
                    "y"
                )
                #Run plink.exe - Auto Accept Host Key
                $acceptkeyoutput = $cmd | & $plink -v $hostname 2>&1
                If ($acceptkeyoutput -like "*Initialised AES-256 SDCTR server->client encryption*")
                {
                    $rawoutput = & $plink -v -i $keyfilepath $username@$hostname -batch $sshcommand 2>&1
                    If ($LastExitCode -ne 0)
                    {
                        throw "Errors Encountered!!!! `n $($rawoutput)"
                    }
                }
            }
            ElseIf ($autoacceptkey -eq $false)
            {
                #Run plink.exe - Do Not Auto Accept Host Key
                $rawoutput = & $plink -v -i $keyfilepath $username@$hostname -batch $sshcommand 2>&1
                If ($LastExitCode -ne 0)
                {
                    throw "Errors Encountered!!!! `n $($rawoutput)"
                }
            }
        }
        else
        {
            Throw "Key File not found"
        }
    }
	
    #Create Published Data
    $output = [system.string]::Join("`n", $rawoutput)
    $startindex = ($output.IndexOf("Started a shell/command"))
    $endindex = ($output.IndexOf("Server sent command exit status 0")) - $startindex
    $output = $output.Substring($startindex, $endindex)
    $output = $output.split("`n") | ? { ($_ -notlike "*Started a shell/command*") -and ($_ -ne "") }

    $pubdata = New-Object System.Management.Automation.PSObject -Property ([Ordered]@{
            hostname      = $hostname
            username      = $username
            sshcommand    = $sshcommand
            keyfilepath   = $keyfilepath
            autoacceptkey = $autoacceptkey
            output        = $output
        })
    
    Write-Verbose $pubdata
}