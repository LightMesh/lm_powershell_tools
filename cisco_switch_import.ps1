function LM-Cisco-Prime-Switch-Import{
<#
.SYNOPSIS 
Pulls data regarding switches from the cisco prime api and imports them into LightMesh.

.DESCRIPTION
This Cmdlet is used to import cisco prime switch data into Lightmesh.
The import creates or updates the following record types and creates valid relationships.
TODO: Add records and rels that get updated here

.PARAMETER cisco_prime_server
Full URL to the Cisco Prime Server

.PARAMETER cisco_url
URI for the cisco prime request 

.PARAMETER datafile
Optionally provide a datafile insteaf of pulling data directly from a cisco prime api

.INPUTS
None. You cannot pipe objects to the script.

.OUTPUTS
None. 

.EXAMPLE
. ./xn-api.ps1
XN-Login -username "USER" -password "yoursecurepassword"
. ./cisco_switch_import.ps1
LM-Cisco-Prime-Switch-Import -cisco_prime_server "1.1.1.1" -cisco_url "/v1/clientdetails"

<#
ADD DOCS
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$cisco_prime_server,

        [Parameter(Mandatory=$true)]
        [string]$cisco_prime_url,

        [Parameter(Mandatory=$false)]
        [string]$datafile

#$data=Invoke-RestMethod -Uri $cisco_prime_server$cisco_url -Method Get -ContentType "application/json"}

#TODO: see if multiple requests should be made to push the data in smaller segments

#TODO: add error checking to catch 400's from cisco prime as well as any from import job to LM

XN POST '/is/switch/job/import_cisco_prime' $data
}
