LightMesh - Microsoft DHCP Server Import
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
