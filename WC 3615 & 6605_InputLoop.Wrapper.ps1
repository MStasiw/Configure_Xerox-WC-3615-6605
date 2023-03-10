<#
.DESCRIPTION

Reads in line by line the IP or DNS Address from an given file, looping through each verifying the printer is pingable then validates the model is either a Xerox WorkCentre 3615 or 6605.
If verification and validation steps succeed then calls the child script on each IP/DNS Address processing the return value into user friendly messages.

AUTHOR
Michael Stasiw

.NOTES

#>


[CmdletBinding()]
param (
    [Parameter(Position=0,Mandatory=$true,
    ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,
    HelpMessage="Filepath to input file to read IP and/or DNS addresses from")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    [string]$InputFile,
    [Parameter(Position=1,Mandatory=$false,
    ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$true,
    HelpMessage="Filepath and name of text file to log output to")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf -IsValid })]
    [Alias('output', 'log')]
    [string]$LogFile #= "$(Split-Path -Path $PSCommandPath -Leaf).log"
)

# If want compatibility with older versions, insert this shim (top-level for script name to be returned, or inside a function for function name to be returned):
if ($PSCommandPath -eq $null) { function Get-PSCommandPath() { return $MyInvocation.PSCommandPath; } $PSCommandPath = Get-PSCommandPath; }

function SNMP-Get {
    [CmdletBinding()]
    param (
        [Parameter(Position=0,Mandatory=$true,
        ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,
        HelpMessage="IP Address or Hostname/DNS name")]
        [ValidateScript({[Bool]($_ -as [IPAddress]) -or $_ -match '(?=.{2,240}$)^(([a-z\d]|[a-z\d][a-z\d\-]*[a-z\d])\.)*([a-z\d]|[a-z\d][a-z\d\-]*[a-z\d])$' })]
        [Alias('IP','IPAddress','HostName','FQDN','DNSName', 'DNSAddress')]
        [string]$IPorDNS,
        [Parameter(Position=1,mandatory=$true,
        ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidatePattern("^\.[1-3](\.[0-9]{1,3})+$")]
        [string]$OID,
        [Parameter(Position=2,Mandatory=$false,
        ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('private','pl0pf1zz','public')]
        [string]$GetCommunityName = 'public'
    )

    try {
        $SNMP = new-object -ComObject olePrn.OleSNMP
    }
    catch {
        # "SNMP object could not be created, therefore SNMP functions are not available"
        Write-Warning "Full Exception ID = $($_.Exception.GetType().Fullname)"

        Write-Error -Message 'SNMP object could not be created, therefore SNMP functions are not available!' -Category ObjectNotFound -TargetObject $SNMP
        Write-Output ''
        Write-Warning "Full Exception ID = $($_.Exception.GetType().Fullname)"
        return $false | Out-Null
    }

    try {
         $SNMP.open($IPorDNS,$GetCommunityName,1,6000)
         [string]$value = $SNMP.get($OID)
         $value = $value.Trim()

         if ($value -eq $null -or $value.Length -le 0) { $value = "No value" }

         $SNMP.close()
         return $value
    }
    catch [System.Runtime.InteropServices.COMException] {
        Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch [System.Runtime.InteropServices.COMException]"
        Write-Warning "$IPorDNS`: SNMP connection refused."
        Write-Debug $_.Exception.ToString()
        Write-Output ''
        return $false | Out-Null
    }
    catch {
        Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch anything"
        Write-Error -Message $_.Exception.ToString() -Category NotSpecified -ErrorId 'SNMP Unknown Error' -TargetObject $SNMP
        Write-Output ''
        Write-Warning "Full Exception ID = $($_.Exception.GetType().Fullname)"
        Write-Warning "At IP/DNS Name: $IPorDNS"
        Write-Output ''
        return 'error'
    }
}

function Ping {
    [CmdletBinding()]
    param (
        [Parameter(Position=0,Mandatory=$true,
        ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,
        HelpMessage="IP Address or Hostname/DNS name")]
        [ValidateScript({[Bool]($_ -as [IPAddress]) -or $_ -match '(?=.{2,240}$)^(([a-z\d]|[a-z\d][a-z\d\-]*[a-z\d])\.)*([a-z\d]|[a-z\d][a-z\d\-]*[a-z\d])$' })]
        [Alias('IP','IPAddress','HostName','FQDN','DNSName', 'DNSAddress')]
        [string]$IPorDNS
    )

    if (Test-Connection $IPorDNS -Count 3 -Quiet) {
        return $true
    }
    else {
        #Write-Warning "$IPorDNS is Offline or Inaccessible."
        return $false
    }
}

function Invoke-ChildScripts {
    $PSScriptName = Split-Path -Path $PSCommandPath -Leaf
    Write-Debug -Message "`$PSScriptName = $PSScriptName"
    $SubScriptPrefix = $PSScriptName.Substring(0, $PSScriptName.LastIndexOf('_')+1)
    
    $SubScripts = Get-ChildItem -Path ".`\$($SubScriptPrefix)*.ps1" -File -Name | Where-Object { $_ -inotcontains $PSScriptName }
    $SubScripts | ForEach-Object {
        Write-Debug -Message "`$PSItem = $PSItem"

        # If at this instance the file no longer exists, throw error
        if (-not (Test-Path -Path ".\$PSItem" -PathType Leaf)) {
            Write-Error -Message "FATAL ERROR: .\$PSItem COULD NOT BE FOUND! CANNOT CONTINE" -Category OpenError
            continue
        }
        $resultReturned = & ".\$PSItem" -IPorDNS $address
        #$resultReturned = Invoke-Command -ScriptBlock { & '.\<Script File Name>' -IPorDNS $address }
                
        Write-Debug -Message "`$resultReturned = $resultReturned"
        if ($resultReturned -eq $true -or $resultReturned -eq 0) {
            $stdout = "$address`: $PSItem`: All settings updated successfully. Errorcode $resultReturned."
            if ($VerbosePreference) { $stdout += "`: $(Get-Date -Format G)" }
        }elseif ($resultReturned -eq 1) {
            $stdout = "$address`: $PSItem`: One setting failed to update. Errorcode $resultReturned."
            if ($VerbosePreference) { $stdout += "`: $(Get-Date -Format G)" }
        }elseif ($resultReturned -gt 1) {
            $stdout = "$address`: $PSItem`: One or more settings failed to update. Errorcode $resultReturned."
            if ($VerbosePreference) { $stdout += "`: $(Get-Date -Format G)" }
        }elseif ($resultReturned -eq 300) {
            $stdout = "$address`: $PSItem`: All settings updated successfully but Restart failed to initiate. Therefore Manual Intervention required to Reboot. Errorcode $resultReturned."
            if ($VerbosePreference) { $stdout += "`: $(Get-Date -Format G)" }
        }elseif ($resultReturned -eq -300) {
            $stdout = "$address`: $PSItem`: All settings updated successfully and Restart initiated. Errorcode $resultReturned."
            if ($VerbosePreference) { $stdout += "`: $(Get-Date -Format G)" }
        }elseif ($resultReturned -gt -300 -and $resultReturned -lt 0) {
            $stdout = "$address`: $PSItem`: One of more settings failed to update but Restart initiated. Errorcode $resultReturned."
            if ($VerbosePreference) { $stdout += "`: $(Get-Date -Format G)" }
        }else{
            # Possibly redundant, but acts as failsafe responce that is still correct either way
            $stdout = "$address`: $PSItem`: One or more settings failed to update. Errorcode $resultReturned."
            if ($VerbosePreference) { $stdout += "`: $(Get-Date -Format G)" }
        }
        Write-Output $stdout
        if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
    }
}

<#
.MAIN
#>
$ErrorActionPreference = 'SilentlyContinue' # Default is 'Continue'
$Error.Clear()

$SourceFile = (Resolve-Path -Path $InputFile).Path

try {
    $reader = [System.IO.File]::OpenText($SourceFile)
    while ($null -ne ($line = $reader.ReadLine())) {
        [string]$address = [string]$line.Trim()
        if (Ping -IPorDNS $address) {
            # HOST-RESOURCES-MIB::hrDeviceDescr.1
            [string]$model = SNMP-Get -IPorDNS $address -OID '.1.3.6.1.2.1.25.3.2.1.3.1'
            if (-not ($model -like "Xerox WorkCentre 3615*" -or $model -like "Xerox WorkCentre 6605*")) {
                $stdout = "$address`: Not a Xerox WorkCentre 3615 or 6605. Skipping..."
                Write-Warning -Message $stdout
                if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
                continue
            } else {
                Invoke-ChildScripts
            }
        }else{ # Not reachable
            $stdout = "$address`: Offline or Unreachable."
            if ($VerbosePreference) { $stdout += "`: $(Get-Date -Format G)" }
            Write-Warning -Message $stdout
            if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
            continue
        }
            
    }
    #$reader.close()
} catch {
    Write-Error -Message $_.Exception.ToString() -Exception $($_.Exception) -Category ReadError
    Write-Output ''
    Write-Warning "Full Exception ID = $($_.Exception.GetType().Fullname)"
    return 'error'
} finally {
    $reader.Close()
}