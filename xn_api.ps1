#XN API Cmdlets for Powershell

function XN-Login{
<#
.SYNOPSIS 
Log into an XN API Endpoint.

.DESCRIPTION
This Cmdlet will log you in and create a token for use during your session. This is stored in $env:XN_TOKEN

.PARAMETER base_url
Full URL to the XN Instance. e.g. http://applianceserver.lightmesh.com
    
.PARAMETER username
Username/Email with which to log in.

.PARAMETER password
Password

.INPUTS
None. You cannot pipe objects to the script.

.OUTPUTS
None. 

.EXAMPLE
C:\PS> XN-Login -base_url http://applianceserver.lightmesh.com -username "someuser@mydomain.com" -password "SecretSquirrel"
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$base_url,

        [Parameter(Mandatory=$true)]
        [string]$username,

        [Parameter(Mandatory=$true)]
        [string]$password

    )
    $user=New-Object PSObject -Property @{
        "email"=$username
        "password"=$password
    }
    $post_data=New-Object PSObject -Property @{
        "user"=$user
    }
    $post_json=ConvertTo-Json $post_data

    $token = Invoke-RestMethod -Uri $base_url"/sessions.json" -Method Post -ContentType "application/json" -Body $post_json
    
    If($token){
        Write-Host "Logged Into $base_url as $username. XN_URL and XN_TOKEN have been exported to the environment"
    }
    $env:XN_URL=$base_url
    $env:XN_TOKEN=$token.token
    return $null
}

function XN-Logout{
<#
.SYNOPSIS 
Log out of XN

.DESCRIPTION
This Cmdlet will log you out and clear the environment variables for XN_URL and XN_TOKEN

.INPUTS
None. You cannot pipe objects to the script.

.OUTPUTS
None. 

.EXAMPLE
C:\PS> XN-Logout
#>
    If (($env:XN_URL) -and ($env:XN_TOKEN)){
        XN Delete "/account" -Silent
    }
    $env:XN_URL=$null
    $env:XN_TOKEN=$null
    Write-Host "Successfully Logged Out"
    return $null

}

function XN{
<#
.SYNOPSIS 
Perform REST Actions against an XN Server

.DESCRIPTION
This Cmdlet allows you to perform GET, POST PATCH, PUT, DELETE Requests against an XN Endpoint

.PARAMETER method
Can be one of GET, POST PATCH, PUT, DELETE
    
.PARAMETER path
URL Endpoint. e.g. "/is/subnet"

.PARAMETER body
Optional. This should be a JSON-formatted string.

.PARAMETER Silent
Optional. If this flag is set the JSON object is not printed out to screen. 

.INPUTS
None. You cannot pipe objects to the script.

.OUTPUTS
Powershell Object matching the JSON returned from XN. 

.EXAMPLE
PS C:\> $subnet=XN GET '/is/subnet/first'

.EXAMPLE
PS C:\> (XN GET '/is/subnet/first' -Silent).meta.xnid
/model/subnet/id/550

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("Get","Post","Patch","Put","Delete")]
        [string]$method,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$path,

        [Parameter(Position=3)]
        [string]$body,

        [Parameter()]
        [switch]$Silent
    )
    $xn_version="/v1"
    If(($env:XN_URL) -and ($env:XN_TOKEN)){
        $headers=@{"AUTHORIZATION"=$env:XN_TOKEN; "accept"="application/json, text/javascript"}
        $action_method=$method.ToString().ToUpper()
        switch ($action_method){
            "GET"{$output=Invoke-RestMethod -Uri $env:XN_URL$xn_version$path -Method Get -ContentType "application/json" -Headers $headers}
            "POST"{$output=Invoke-RestMethod -Uri $env:XN_URL$xn_version$path -Method Post -ContentType "application/json" -Headers $headers -Body $body}
            "PATCH"{$output=Invoke-RestMethod -Uri $env:XN_URL$xn_version$path -Method Patch -ContentType "application/json" -Headers $headers -Body $body}
            "PUT"{$output=Invoke-RestMethod -Uri $env:XN_URL$xn_version$path -Method Put -ContentType "application/json" -Headers $headers -Body $body}
            "DELETE"{$output=Invoke-RestMethod -Uri $env:XN_URL$xn_version$path -Method Delete -ContentType "application/json" -Headers $headers}
        }
        
        If(-Not($silent)){
            $json_output=$output | ConvertTo-Json -Depth 100
            Write-Host $json_output
        }
        return $output
    }else{
        throw "XN_URL and XN_TOKEN not found in environment. Please use XN-Login to log in."
    }

}