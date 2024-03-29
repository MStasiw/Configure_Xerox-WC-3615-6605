﻿<#
# .MODELS WorkCentre 3615 & 6605
# .PURPOSE Set both the Kerberos and LDAP server address and port, then set Authentication System settings to Kerberos and LDAP respectively, and finally enable Network Authentication under Secure Settings.
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
 Kerberos Server
 # Properties > Secuirty > Kerberos Server
 # /setting/setkrb5.htm
 #
 # Set 'IP Address / Host Name & Port' field to "ca.wal-mart.com"
 # Set port field to "88"
 # Set 'Domain Name' field to "ca.wal-mart.com"
 #
 # But do not restart system.
 #>
$setKerberos_params = @{
    '102b07'='ca.wal-mart.com'
    '102b08'=88
    '102b06'='ca.wal-mart.com'
}

[string]$urlPath = '/setting/setkrb5.htm'
try {
    $WebRequest1 = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setKerberos_params -Headers $Request_headers

    switch ($WebRequest1.StatusCode) {
        200 { $FGColour = 'Green'; break }
        default { $FGColour = 'Red'; break }
    }
    $stdout = "$IPorDNS`tStatus: $($WebRequest1.StatusCode) $($WebRequest1.StatusDescription)"
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
 LDAP Directory
 # Properties > Protocols > LDAP Server
 # /setting/setldapsvr.htm
 #
 # Set 'IP Address / Host Name & Port' field to "ca.wal-mart.com"
 # Set port field to "3268"
 #
 # But do not restart system.
 #>
$setLDAP_params = @{
    '102c0c'='ca.wal-mart.com'
    '102c0d'=3268
}

[string]$urlPath = '/setting/setldapsvr.htm'
try {
    $WebRequest2 = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setLDAP_params -Headers $Request_headers

    switch ($WebRequest2.StatusCode) {
        200 { $FGColour = 'Green'; break }
        default { $FGColour = 'Red'; break }
    }
    $stdout = "$IPorDNS`tStatus: $($WebRequest2.StatusCode) $($WebRequest2.StatusDescription)"
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
    $result += 2
} catch {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch anything"
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Warning -Message "IP/DNS Address = $IPorDNS"
    Write-Warning -Message $stdout
    $result += 2
}

<#
 Authentication System
 # Properties > Security > Authentication System
 # /setting/setauthsys.htm
 #
 # 'Authentication Type (for User Authentication)'
 # Set 'Authentication System Settings' dropdown to "Kerberos (Windows)"
 #
 # 'Authentication Type (for Server Address/Phone Book)'
 # Set 'Authentication System Settings' dropdown to "LDAP"
 #
 # But do not restart system.
 #>
$setAuthSys_params = @{
    '102a03'=0
    '102a02'=3
}

[string]$urlPath = '/setting/setauthsys.htm'
try {
    $WebRequest3 = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setAuthSys_params -Headers $Request_headers

    switch ($WebRequest3.StatusCode) {
        200 { $FGColour = 'Green'; break }
        default { $FGColour = 'Red'; break }
    }
    $stdout = "$IPorDNS`tStatus: $($WebRequest3.StatusCode) $($WebRequest3.StatusDescription)"
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
    $result += 3
} catch {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch anything"
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Warning -Message "IP/DNS Address = $IPorDNS"
    Write-Warning -Message $stdout
    $result += 3
}

<#
 'Secure Settings' (LUI/Control Panel)
 # Properties > Security > Secure Settings
 # /printer/prtpanel.htm
 #
 # Network Authentication: Enable 'Network Authentication' - Check the 'On' checkbox
 # Service Lock: Set 'Email' dropdown to "Password Locked"
 # Service Lock: Set 'Scan to Network' dropdown to "Password Locked"
 #>
$setSecureSettings_params = @{
    'b03816'=1
    'b03809'=1
    'b03806'=1
}

[string]$urlPath = '/printer/prtpanel.htm'
try {
    $WebRequest4 = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setSecureSettings_params -Headers $Request_headers

    switch ($WebRequest4.StatusCode) {
        200 { $FGColour = 'Green'; break }
        default { $FGColour = 'Red'; break }
    }
    $stdout = "$IPorDNS`tStatus: $($WebRequest4.StatusCode) $($WebRequest4.StatusDescription)"
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
    $result += 4
} catch {
    #Write-Debug -Message "Entered $($MyInvocation.MyCommand) Catch anything"
    $stdout = $_.Exception.ToString()
    if ($DebugPreference) { Write-Host '' }
    Write-Warning -Message "IP/DNS Address = $IPorDNS"
    Write-Warning -Message $stdout
    $result += 4
}

$ReturnCode = if ($WebRequest1.StatusCode -eq 200 -and $WebRequest2.StatusCode -eq 200 -and $WebRequest3.StatusCode -eq 200 -and $WebRequest4 -eq 200) { $true } else { $result }
Write-Verbose -Message "`$ReturnCode = $ReturnCode"
if (!$NestedExecution) { return $ReturnCode | Out-Null }
return $ReturnCode

<#
1st fails				ReturnCode=1
2nd fails				ReturnCode=2
3rd fails				ReturnCode=3
1st & 2nd fails			ReturnCode=3
1st & 3rd fails			ReturnCode=4
2nd & 3rd fails			ReturnCode=5
1st, 2nd, & 3rd fail	ReturnCode=6
...
#>