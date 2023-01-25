<#
# .MODELS WorkCentre 3615 & 6605
# .PURPOSE Set SMTP server address and port, and disable SMTP Communication Encryption
#>
param (
    [Parameter(Position=0,Mandatory=$true,
    ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,
    HelpMessage="IP Address or DNS name")]
    [ValidateScript({[Bool]($_ -as [IPAddress]) -or ($_ -match '(?=.{2,240}$)^(([a-z\d]|[a-z\d][a-z\d\-]*[a-z\d])\.)*([a-z\d]|[a-z\d][a-z\d\-]*[a-z\d])$')})]
    [Alias('ip','ipaddress','hostname','dns','dnsname')]
    [string]$IPorDNS
)
# If want compatibility with older versions, insert this shim (top-level for script name to be returned, or inside a function for function name to be returned):
if ($PSCommandPath -eq $null) { function Get-PSCommandPath() { return $MyInvocation.PSCommandPath; } $PSCommandPath = Get-PSCommandPath; }

$Error.Clear()
#Write-Output "`n`$PSCommandPath = $PSCommandPath"
#Write-Output "`n`$MyInvocation.PSCommandPath = $($MyInvocation.PSCommandPath)" # filepath of invoker or calling script
$NestedExecution = $false
if ($MyInvocation.PSCommandPath) { $NestedExecution = $true } # value only set if nested execution.


<# Build the Basic Authentication type Header #>
$private:user = 'admin'
$private:pass = '1111'

$private:pair = "$($private:user):$($private:pass)"

$private:encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($private:pair))

$basicAuthValue = "Basic $private:encodedCreds"

$Request_headers = @{
    Authorization = $basicAuthValue
}

<#
 Email Settings
 # Properties > Protocols > Email Settings
 # /setting/setemail.htm
 #
 # Set 'SMTP Server (IP Address or DNS Name)' field to "smtp-gw1.wal-mart.com"
 # Set 'SMTP Port' field to "25"
 #>
$setEmail_params = @{
    '104002'='smtp-gw1.wal-mart.com'
    '104006'=25
}

[string]$urlPath = '/setting/setemail.htm'
try {
    $result1 = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setEmail_params -Headers $Request_headers

    switch ($result1.StatusCode) {
        200 { $FGColour = 'Green'; break }
        default { $FGColour = 'Red'; break }
    }
    $stdout = "$IPorDNS`tStatus: $($result1.StatusCode) $($result1.StatusDescription)"
    if (!$NestedExecution -and !$DebugPreference) { Write-Host $stdout -ForegroundColor $FGColour }
    #if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
    Write-Debug -Message $stdout
} catch [System.Security.Authentication.AuthenticationException] {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch [System.Security.Authentication.AuthenticationException]"
    $stdout = "$IPorDNS`tException: $($_.Exception.Message)`tInnerException: $($_.Exception.InnerException.Message)"
    if (!$NestedExecution -and !$DebugPreference) { Write-Warning -Message $stdout }
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Debug -Message "IP/DNS Address = $IPorDNS"
    Write-Debug -Message $stdout
    $result = 1
} catch {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch anything"
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Warning -Message "IP/DNS Address = $IPorDNS"
    Write-Warning -Message $stdout
    #if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
    $result = 1
}

<#
 SSL
 # Properties > Security > SSL
 # /setting/setssltlscomm.htm
 #
 # Set 'SMTP - SSL/TLS Communication' field to "Disabled"
 #>
$setSSL_params = @{ '102507'=0 }

[string]$urlPath = '/setting/setssltlscomm.htm'
try {
    $result2 = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setSSL_params -Headers $Request_headers

    switch ($result2.StatusCode) {
        200 { $FGColour = 'Green'; break }
        default { $FGColour = 'Red'; break }
    }
    $stdout = "$IPorDNS`tStatus: $($result2.StatusCode) $($result2.StatusDescription)"
    if (!$NestedExecution -and !$DebugPreference) { Write-Host $stdout -ForegroundColor $FGColour }
    #if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
    Write-Debug -Message $stdout
} catch [System.Security.Authentication.AuthenticationException] {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch [System.Security.Authentication.AuthenticationException]"
    $stdout = "$IPorDNS`tException: $($_.Exception.Message)`tInnerException: $($_.Exception.InnerException.Message)"
    if (!$NestedExecution -and !$DebugPreference) { Write-Warning -Message $stdout }
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Debug -Message "IP/DNS Address = $IPorDNS"
    Write-Debug -Message $stdout
    $result = 2
} catch {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch anything"
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Warning -Message "IP/DNS Address = $IPorDNS"
    Write-Warning -Message $stdout
    #if ($LogFile) { $stdout | Out-File -FilePath $LogFile -Append -Force }
    $result = 2
}



$ReturnCode = if ($result1.StatusCode -eq 200 -and $result2.StatusCode -eq 200) { $true } else { $result }
#Write-Debug -Message "`$ReturnCode = $ReturnCode"
if (!$NestedExecution) { return $ReturnCode | Out-Null }
return $ReturnCode