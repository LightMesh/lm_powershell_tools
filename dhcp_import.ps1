function LM-DHCP-Import{
<#
.SYNOPSIS 
Extracts DHCP Server information into JSON Format and optionally sends it to LightMesh

.DESCRIPTION
The script works by reading through the DHCP server objects for Scopes, Reservations, and Leases.
The information is stored in custom objects which are then serialized to JSON.
Optionally the JSON Output can be sent to directly to the LightMesh host for processing.

.PARAMETER ExportFile
Optional path to a file where to write the JSON output. (e.g. C:\lm_dhcp_scopes.json)
    
.PARAMETER LMImport
Switch defining whether to send the data to LightMesh

.INPUTS
None. You cannot pipe objects to the script.

.OUTPUTS
None. 

.EXAMPLE
C:\PS> LM-DHCP-Import
#>

[CmdletBinding()]
Param(
   [string]$ExportFile,
   [switch]$LMImport,
   [string]$LMHost,
   [int]$LMPort,
   [switch]$LMSecure
)

#Create a custom object. This will allow us to control the serialization to JSON
$dhcp_server_object=New-Object -TypeName PSObject

$hostname=Hostname
$scopes=Get-DhcpServerv4Scope

[System.Collections.ArrayList]$dhcp_scopes=@()

foreach($scope in $scopes){
    $scope_object=New-Object -TypeName PSObject
    Add-Member -InputObject $scope_object -MemberType NoteProperty -Name name -Value $scope.Name
    Add-Member -InputObject $scope_object -MemberType NoteProperty -Name scope_id -Value $scope.ScopeId.IPAddressToString
    Add-Member -InputObject $scope_object -MemberType NoteProperty -Name start_ip -Value $scope.StartRange.IPAddressToString
    Add-Member -InputObject $scope_object -MemberType NoteProperty -Name end_ip -Value $scope.EndRange.IPAddressToString    
    Add-Member -InputObject $scope_object -MemberType NoteProperty -Name subnet_mask -Value $scope.SubnetMask.IPAddressToString
    
    #Get and parse reservations into valid format.
    [System.Collections.ArrayList]$reservations_array=@()
    $reservations=Get-DhcpServerv4Reservation -ScopeId $scope.ScopeId
    foreach($reservation in $reservations){
        $reservation_object=New-Object -TypeName PSObject     
        Add-Member -InputObject $reservation_object -MemberType NoteProperty -Name name -Value $reservation.Name
        Add-Member -InputObject $reservation_object -MemberType NoteProperty -Name mac -Value $reservation.ClientId
        Add-Member -InputObject $reservation_object -MemberType NoteProperty -Name ip -Value $reservation.IPAddress.IPAddressToString
        Add-Member -InputObject $reservation_object -MemberType NoteProperty -Name description -Value $reservation.Description 
        [void]$reservations_array.Add($reservation_object)
    }
    Add-Member -InputObject $scope_object -MemberType NoteProperty -Name reservations -Value $reservations_array
    
    #Get and parse leases into valid format.
    [System.Collections.ArrayList]$leases_array=@()
    $leases=Get-DhcpServerv4Lease -ScopeId $scope.ScopeId
    foreach($lease in $leases){
        $lease_object=New-Object -TypeName PSObject
        Add-Member -InputObject $lease_object -MemberType NoteProperty -Name mac -Value $lease.ClientId
        Add-Member -InputObject $lease_object -MemberType NoteProperty -Name ip -Value $lease.IpAddress.IPAddressToString
        Add-Member -InputObject $lease_object -MemberType NoteProperty -Name hostname -Value $lease.IpAddress.HostName
        if($lease.LeaseExpiryTime){
            $lease_expiry=(Get-Date(Get-Date($lease.LeaseExpiryTime).ToUniversalTime()) -format s) + "Z"
        }else{
            $lease_expiry=$null
        }
        Add-Member -InputObject $lease_object -MemberType NoteProperty -Name expiry -Value $lease_expiry
        [void]$leases_array.Add($lease_object)

    }
    Add-Member -InputObject $scope_object -MemberType NoteProperty -Name leases -Value $leases_array

    [void]$dhcp_scopes.Add($scope_object)
}

Add-Member -InputObject $dhcp_server_object -MemberType NoteProperty -Name hostname -Value $hostname
Add-Member -InputObject $dhcp_server_object -MemberType NoteProperty -Name dhcp_scopes -Value $dhcp_scopes


$dhcp_json_object = $dhcp_server_object | ConvertTo-Json -Depth 5

If ($ExportFile){
    $dhcp_json_object | Out-File -FilePath $ExportFile
}
If ($LMImport){
    Write-Host "Proceeding with Import"
    $existing_dhcp_object=XN Get "/is/dhcp_server/filter/name?name=$hostname" -Silent
    if($existing_dhcp_object){
        Write-Host "Existing DHCP Server found at" $existing_dhcp_object.meta.xnid
        $dhcp_server_record=$existing_dhcp_object
    }else{
        Write-Host "No DHCP Server record foound for $hostname in LM. Creating record."
        $obj=New-Object PSObject -Property @{
        "name"=$hostname
        }
        $dhcp_server_record = XN Put "/model/dhcp_server" ($obj | ConvertTo-Json) -Silent
        Write-Host "Created DHCP Server record for $hostname with XNID " $dhcp_server_record.meta.xnid 
    }
    $action_path=$dhcp_server_record.meta.xnid + "/action/update_all_scopes"
    $result=XN POST $action_path $dhcp_json_object -Silent
    return $result
}
}