<#
.DESCRIPTION

Reads in line by line the IP or DNS Address from an given file, looping through each verifying the printer is pingable then validates the model is either a Xerox WorkCentre 3615 or 6605.
If verification and validation steps succeed then calls the child script on each IP/DNS Address processing the return value into user friendly messages.

AUTHOR
Michael Stasiw

.NOTES

Measure of Speed/Performance made based on an instance when executed on dev/lab server (dcant10096ca) which hosts the scripts, input, and output files. Input file contained 443 FQDNs.

Start: 6/29/2022 6:37:56 PM, End: 6/29/2022 7:04:39 PM

: Duration :
Minutes           : 26
Seconds           : 43
Milliseconds      : 0
Ticks             : 16030000000
TotalDays         : 0.0185532407407407
TotalHours        : 0.445277777777778
TotalMinutes      : 26.7166666666667
TotalSeconds      : 1603
TotalMilliseconds : 1603000
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
            #$model = $model.Trim() #areas redundant
            if (-not ($model -like "Xerox WorkCentre 3615*" -or $model -like "Xerox WorkCentre 6605*")) {
                $stdout = "$address`: Not a Xerox WorkCentre 3615 or 6605. Skipping..."
                Write-Warning -Message $stdout
                if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
                continue
            } else {
                <#
                # Child Scripts
                #>
                if (-not (Test-Path -Path '.\WC 3615 & 6605_Set SMTP Server & Disable Encryption.ps1' -PathType Leaf)) {
                    Write-Error -Message "FATAL ERROR: '.\WC 3615 & 6605_Set SMTP Server & Disable Encryption.ps1' COULD NOT BE FOUND! CANNOT CONTINE" -Category OpenError
                    return $false
                }
                $resultReturned = & '.\WC 3615 & 6605_Set SMTP Server & Disable Encryption.ps1' -IPorDNS $address
                #$resultReturned = Invoke-Command -ScriptBlock { & '.\WC 3615 & 6605_Set SMTP Server & Disable Encryption.ps1' -IPorDNS $address }
                
                Write-Debug -Message "`$resultReturned = $resultReturned"
                if ($resultReturned -eq $true) {
                    $stdout = "$address`: All settings updated successfully."
                    if ($VerbosePreference) { $stdout += "`t $(Get-Date -Format G)" }
                }elseif ($resultReturned -eq $false) {
                    $stdout = "$address`: All settings update FAILED."
                    if ($VerbosePreference) { $stdout += "`t $(Get-Date -Format G)" }
                }else{
                    #Write-Warning "$address`: settings update FAILED. Errorcode: $resultReturned."
                    $stdout = "$address`: One or more settings update FAILED. Errorcode $resultReturned."
                    if ($VerbosePreference) { $stdout += "`t $(Get-Date -Format G)" }
                }
                Write-Output $stdout
                if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
            }
        }else{
            $stdout = "$address`: Offline or Unreachable."
            if ($VerbosePreference) { $stdout += "`t $(Get-Date -Format G)" }
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