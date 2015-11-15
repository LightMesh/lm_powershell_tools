function LM-DNS-Import{
<#
.SYNOPSIS 
Extracts DNS Zonefile information and sends to LightMesh.
Zonefile needs to be already created and accessible on disk.

.DESCRIPTION
This Cmdlet is used to import standard MS DNS or BIND Zonefiles into Lightmesh.
The import creates or updates the following record types and creates valid relationships.
DNS Server
DNS Zone
DNS Entry
IP Address

Large imports (25000+) should be done in stages. 
The first Zone import is usually the only time-consuming operation. Subsequent updates are much faster.

Export of file can be done with DNSCMD.
dnscmd . /ZoneExport lightmesh.local lightmesh.local.txt

.PARAMETER import_file
Path to DNS Zonefile to import. This must be in standard BIND or MS DNS Master Zone format. Slave zone files not accepted.
Must contain a valid SOA header.

.PARAMETER zone_name
FQDN of the Zone SOA. e.g. lightmesh.com

.PARAMETER dns_server_name
[Optional] Define the DNS Server object in LightMesh to create or update. Defaults to the local hostname.
    
.PARAMETER lm_import
[Optional] Switch defining whether to send the data to LightMesh

.PARAMETER temp_dir
[Optional] Path to temporary directory to store the split zone files. Defaults to $env:TEMP

.PARAMETER batch_size
[Optional] Number of records to import at once. Defaults to 100. Large numbers of records can cause Timeouts.

.PARAMETER continue_on_error
[Optional] Set to $false to exit script on any POST errors to LM. Defaults to $true


.INPUTS
None. You cannot pipe objects to the script.

.OUTPUTS
None. 

.EXAMPLE
PS C:\ms_dns_import> . .\xn_api.ps1
PS C:\ms_dns_import> XN-Login -username "dns_user@lightmesh.com" -password "SomethingComplex" -base_url "https://app001.lightmesh.com/"

PS C:\ms_dns_import> dnscmd . /ZoneExport lightmesh.local lightmesh.local.txt
DNS Server . exported zone
  lightmesh.local to file C:\Windows\system32\dns\lightmesh.local.txt
Command completed successfully.

PS C:\ms_dns_import> Move-Item C:\Windows\system32\dns\lightmesh.local.txt $env:TEMP

PS C:\ms_dns_import>  . .\dns_import.ps1; $ss=LM-DNS-Import -import_file $env:TEMP\lightmesh.local.txt -zone_name lightmesh.local -lm_import
[2015-11-15T15:38:11Z] Imported Zone file at C:\Users\ADMINI~1\AppData\Local\Temp\lightmesh.local.dnsimport.0 Created/Updated:  4 . Job ID:  /model/job_result/id/90439
#>

[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)]
   [string]$import_file,
[Parameter(Mandatory=$true)]
   [string]$zone_name,
   [string]$dns_server_name=$env:COMPUTERNAME,
   [switch]$lm_import,
   [string]$temp_dir=$env:TEMP,
   [int]$batch_size=100,
   [bool]$continue_on_error=$true
)
$content=Get-Content $import_file

#Find SOA Header contents. This is used to prepend to each batch.
#This expects the last line containing the SOA header to contain a ")" character and TTL
$i=0
foreach($line in $content){
    If($line -match "SOA"){
        $soa_start=$i
        $soa_start_found=$true
    }
    If($line -match "\)*TTL"){
        $soa_end=$i
        $soa_end_found=$true
    }
    If($soa_start_found -and $soa_end_found){
        break;
    }
    $i++
}
$soa_header=$content[$soa_start..$soa_end]

#Batch each zone into manageable chunks, but make sure that a file never starts with a blank line.
$zone_batch_array=@()
$j=0
$i=0
$batch_start=0
foreach($line in $content){
    $j++
    $i++
    if($i -eq $content.Length){
        $zone_batch_array += ,@($content[$batch_start..$i])
        break
    }
    if(($j -ge $batch_size) -and !($line -match "^\s")){
            $batch_end=$i-1
            $zone_batch_array += ,@($content[$batch_start..$batch_end])
            $batch_start=$i
            $j=0
    }    
}

#Create Temporary directory to store Batched Zone Files.
if(!(Test-Path -Path $temp_dir )){
    New-Item -ItemType directory -Path $temp_dir
}

$zone_group_index=0
foreach($zone_group in $zone_batch_array){
    $file_name=$temp_dir+"\"+$zone_name+".dnsimport.$zone_group_index"
    If(!($zone_group_index -eq 0)){
        $zone_group=$soa_header+$zone_group
    }
    $zone_group | Out-File $file_name -Encoding ascii
    #Create a custom object.
    $dns_zone_object=New-Object -TypeName PSObject
    $file_contents=Get-Content -Path $file_name -Encoding Byte
    $zone_base_64 = [System.Convert]::ToBase64String($file_contents)
    Add-Member -InputObject $dns_zone_object -MemberType NoteProperty -Name zone_name -Value $zone_name
    Add-Member -InputObject $dns_zone_object -MemberType NoteProperty -Name zonefile -Value $zone_base_64

    $dns_zone_object_json = $dns_zone_object | ConvertTo-Json -Depth 5
    If ($lm_import){
        try {
            $existing_dns_object=XN Get "/is/dns_server/filter/name?name=$dns_server_name" -Silent
            if($existing_dns_object){
                $dns_server_record=$existing_dns_object
            }else{
                Write-Host "No DNS Server record foound for $dns_server_name in LM. Creating record."
                $obj=New-Object PSObject -Property @{
                "name"=$dns_server_name
                }
                $dns_server_record = XN Put "/model/dns_server" ($obj | ConvertTo-Json) -Silent
                Write-Host "Created DNS Server record for $dns_server_name with XNID " $dns_server_record.meta.xnid 
            }
            $action_path=$dns_server_record.meta.xnid + "/action/import_zonefile"
            $result=XN POST $action_path $dns_zone_object_json -Silent
            $end_time=(Get-Date -format s) + "Z"
            Write-Host "[$end_time] Imported Zone file at $file_name Created/Updated: "$result.value.status.entries_updated_or_created ". Job ID: " $result.meta.xnid -BackgroundColor DarkGreen
        } catch {
            $end_time=(Get-Date -format s) + "Z"
            if($_.CategoryInfo.Activity -eq "Invoke-RestMethod"){
                $error_message=$_.ErrorDetails.Message -replace "`n",", " -replace "`r",", "
                Write-Host "[$end_time] Error during Import. Code:" $_.Exception.Response.StatusCode.value__ "Data: " $error_message -BackgroundColor Red
            }else{
                Write-Host "[$end_time] Error during Import. Unknown Error" $_   
            }
            if(!($continue_on_error)){
                return $_
            }
        }
    }
    $zone_group_index++
}
}