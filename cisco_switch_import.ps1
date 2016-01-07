function LM-CISCO-PRIME-SWITCH-Import{
<#
.SYNOPSIS 
Pulls data regarding switches from the cisco prime api and imports them into LightMesh.

.DESCRIPTION
This Cmdlet is used to import cisco prime switch data into Lightmesh.
The import creates or updates the following record types and creates valid relationships.
TODO: Add records and rels that get updated here

.INPUTS
None. You cannot pipe objects to the script.

.PARAMETER cisco_prime_server
Full URL to the Cisco Prime Server

.OUTPUTS
None. 

.EXAMPLE
TODO: add example here
#>

function Cisco-Import{
<#
ADD DOCS
#>

$path='/ciscoprime/uri/here'
$server='ciscoprimeserverhere'
#add any headers for ciscoprime request here
#$headers=@{"AUTHORIZATION"=$env:XN_TOKEN; "accept"="application/json, text/javascript"}
$data=Invoke-RestMethod -Uri $cisco_prime_server$path -Method Get -ContentType "application/json" -Headers $headers}

XN POST '/model/switch/job/import_cisco_prime' $data
}
