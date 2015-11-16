LightMesh - Powershell Tools
========================================
[DHCP Import](#dhcp)

[DNS Import](#dns)

DHCP
========================================

Purpose
-------

A set of PowerShell Cmdlets exist to interact with the LightMesh framework.

The LM-DHCP-Import Cmdlet leverages a version of the XN Powershell Client tools.

This cmdlet currently exports all DHCP Scopes along with their reservations and leases and uploads the data to LightMesh.

 

Usage
-----

### Requirements

This script currently supports Windows 2012 or later.

Place the dhcp_import.ps1 and xn_api.ps1 scripts into a folder on the  DHCP server.

Scripts need to be executed as Admin

 

### Example

These commands are executed within a powershell prompt.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PS C:\lm_ms_dhcp_import> XN-Login -base_url http://appliance.lightmesh.com -username "user@domain.com" -password "SecretSquirrel"
Logged Into http://appliance.lightmesh.com as user@domain.com. XN_URL and XN_TOKEN have been exported to the environment
PS C:\lm_ms_dhcp_import> LM-DHCP-Import -LMImport

Proceeding with Import
Existing DHCP Server found at /model/dhcp_server/id/8602


meta         : @{xnid=/model/job_result/id/8943; model_name=job_result; rendered=System.Object[]; format=partial;
               rel_limit=50}
id           : 8943
name         :
model_name   : job_result
description  :
created_at   : 2015-08-19T19:36:35Z
status       : complete
messages     :
request_url  :
source_url   : /model/dhcp_server/id/8602
action_type  : action
action_name  : update_all_scopes
action_args  : @{dhcp_scopes=System.Object[]}
part_name    : dhcp_server
value        : @{removed=0; updated=21; created=0}
display_name : update_all_scopes



PS C:\lm_ms_dhcp_import> XN-Logout
Successfully Logged Out
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DNS
========================================
Purpose
-------

The LM-DNS-Import Cmdlet leverages a version of the XN Powershell Client tools.

The Cmdlet works by uploading Zonefiles to Lightmesh for processing.


Example
--------
```
PS C:\ms_dns_import> . .\xn_api.ps1
PS C:\ms_dns_import> XN-Login -username "dns_user@lightmesh.com" -password "SomethingComplex" -base_url "https://app001.lightmesh.com/"
PS C:\ms_dns_import> dnscmd . /ZoneExport lightmesh.local lightmesh.local.txt
DNS Server . exported zone
  lightmesh.local to file C:\Windows\system32\dns\lightmesh.local.txt
Command completed successfully.
PS C:\ms_dns_import> Move-Item C:\Windows\system32\dns\lightmesh.local.txt $env:TEMP
PS C:\ms_dns_import>  . .\dns_import.ps1; $ss=LM-DNS-Import -import_file $env:TEMP\lightmesh.local.txt -zone_name lightmesh.local -lm_import
[2015-11-15T15:38:11Z] Imported Zone file at C:\Users\ADMINI~1\AppData\Local\Temp\lightmesh.local.dnsimport.0 Created/Updated:  4 . Job ID:  /model/job_result/id/90439
```

Options
---------

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
