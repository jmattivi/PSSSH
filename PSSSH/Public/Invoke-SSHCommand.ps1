function Invoke-SSHCommand
{
    <#
    .NOTES
    	AUTHOR: 	Jon Mattivi
    	COMPANY: 
    	CREATED DATE: 2018-01-31

    .SYNOPSIS
        Uses Putty plink.exe to execute ssh commands on remote hosts
        
    .DESCRIPTION
        Uses Putty plink.exe to execute ssh commands on remote hosts

    .PARAMETER hostname
        Name of remote host to run commands on

    .PARAMETER username
        Username to connect to remote host

    .PARAMETER sshcommand
        Command to run on remote host

    .PARAMETER autoacceptkey
        Automatically accept the key for the remote host - Default value is True

    .PARAMETER password
        Password specified for user when key authentication is not used

    .PARAMETER keyfilepath
        Path to key file when using key authentication
    	    
    .EXAMPLE
        $password = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential ("username", $password)
        Invoke-SSHCommand -hostname ServerX -username svcaccount -credential $Cred -sshcommand "ls /usr/svcaccount/"
        
    .EXAMPLE
        Invoke-SSHCommand -hostname ServerX -username svcaccount -keyfilepath C:\sshkeys\ServerX.key -sshcommand "ls /usr/svcaccount/"

    #>
    
    [CmdletBinding(DefaultParameterSetName = 'UsePasswordAuthentication')]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$hostname,
        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$sshcommand,
        [Parameter(Position = 3, Mandatory = $false)]
        [Switch]$autoacceptkey = $true,
        [Parameter(ParameterSetName = 'UsePasswordAuthentication', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $credential,
        [Parameter(ParameterSetName = 'UseKeyAuthentication', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$username,
        [Parameter(ParameterSetName = 'UseKeyAuthentication', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$keyfilepath
    )
    
    $rawoutput = @()
    $plink = "$PSScriptRoot\..\bin\plink.exe"
	
    If ($credential)
    {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password

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
        })
    
    Write-Verbose $pubdata
    Write-Output $output
}