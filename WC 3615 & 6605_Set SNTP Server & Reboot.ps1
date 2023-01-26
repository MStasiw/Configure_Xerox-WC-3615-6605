<#
# .MODELS WorkCentre 3615 & 6605
# .PURPOSE Set SNTP server address and duration values of two associated settings (Connection Timeout, and Time Synchronization Interval).
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

[int]$result = 0

<#
 SNTP
 # Properties > Protocols > SNTP
 # /setting/setsntp.htm
 #
 # Check 'Enable SNTP' checkbox
 # Set 'IP Address / Host Name' field to "ntp-2.wal-mart.com"
 # Set 'Connection Timeout' field to "60"
 # Set 'Time Synchronization Interval' field to "168"
 #>
$setSNTP_params = @{
    '103016'=1
    '104601'='ntp-2.wal-mart.com'
    '104602'=60
    '104603'=168
}

[string]$urlPath = '/setting/setsntp.htm'
try {
    $SNTP_WebRequest = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setSNTP_params -Headers $Request_headers

    switch ($SNTP_WebRequest.StatusCode) {
        200 { $FGColour = 'Green'; break }
        default { $FGColour = 'Red'; break }
    }
    $stdout = "$IPorDNS`tStatus: $($SNTP_WebRequest.StatusCode) $($SNTP_WebRequest.StatusDescription)"
    if (!$NestedExecution -and !$DebugPreference) { Write-Host $stdout -ForegroundColor $FGColour }
    Write-Debug -Message $stdout
} catch [System.Security.Authentication.AuthenticationException] {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch [System.Security.Authentication.AuthenticationException]"
    $stdout = "$IPorDNS`tException: $($_.Exception.Message)`tInnerException: $($_.Exception.InnerException.Message)"
    if (!$NestedExecution -and !$DebugPreference) { Write-Warning -Message $stdout }
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Debug -Message "IP/DNS Address = $IPorDNS"
    Write-Debug -Message $stdout
    $result += 1
} catch {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch anything"
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Warning -Message "IP/DNS Address = $IPorDNS"
    Write-Warning -Message $stdout
    $result += 1
}

<#
 Restart System using Web App/EWS/CWIS interface
 # Prompted with below message and [Restart] button on same form POST HTML page as above
 # "Settings have been changed.
 #  Restart system for new settings to take effect."
 # 		Payload={'820002'='Restart'}
 #
 # but to generalize it for future use, using the dedicated 'Resets' page
 # Properties > General Setup > Resets
 # /setting/setinit.htm
 #
 # Submit value corresponding to the clicking of [Power Off/On Printer] button to right of 'Power Off/On the Printer'
 #
 # Then display of below message
 # "Restarting...
 #  Refresh your browser window after printer restart is complete."
 #>
$setReboot_params = @{
    '820001'='Power+Off/On+Printer'
}

[string]$urlPath = '/setting/setinit.htm'
try {
    $Restart_WebRequest = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setReboot_params -Headers $Request_headers

    switch ($Restart_WebRequest.StatusCode) {
        200 { $FGColour = 'Green'; break }
        default { $FGColour = 'Red'; break }
    }
    $stdout = "$IPorDNS`tStatus: $($Restart_WebRequest.StatusCode) $($Restart_WebRequest.StatusDescription)"
    if (!$NestedExecution -and !$DebugPreference) { Write-Host $stdout -ForegroundColor $FGColour }
    Write-Debug -Message $stdout
    $result += -300
} catch [System.Security.Authentication.AuthenticationException] {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch [System.Security.Authentication.AuthenticationException]"
    $stdout = "$IPorDNS`tException: $($_.Exception.Message)`tInnerException: $($_.Exception.InnerException.Message)"
    if (!$NestedExecution -and !$DebugPreference) { Write-Warning -Message $stdout }
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Debug -Message "IP/DNS Address = $IPorDNS"
    Write-Debug -Message $stdout
    $result += 300
} catch {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch anything"
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Warning -Message "IP/DNS Address = $IPorDNS"
    Write-Warning -Message $stdout
    $result += 300
}

$ReturnCode = $result
Write-Verbose -Message "`$ReturnCode = $ReturnCode"
if (!$NestedExecution) { return $ReturnCode | Out-Null }
return $ReturnCode

<#
1st fails						ReturnCode=1
1st succeeds & Restart fails	ReturnCode=300
1st & Restart succeed			ReturnCode=-300
1st fails & Restart succeed 	ReturnCode=-299
#>