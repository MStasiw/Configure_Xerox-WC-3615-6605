<#
# .MODELS WorkCentre 3615 & 6605
# .PURPOSE Set both the Kerberos and LDAP server address and port, then set Authentication System settings to Kerberos protocol.
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
    $result1 = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setKerberos_params -Headers $Request_headers

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
    $result2 = Invoke-WebRequest -Uri "http://$IPorDNS$urlPath" -Method POST -Body $setLDAP_params -Headers $Request_headers

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
