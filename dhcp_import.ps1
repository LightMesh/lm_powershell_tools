<#
.SYNOPSIS 
Extracts DHCP Server information into JSON Format and optionally sends it to LightMesh

.DESCRIPTION
The script works by reading through the DHCP server objects for Scopes, Reservations, and Leases.
The information is stored in custom objects which are then serialized to JSON.
Optionally the JSON Output can be sent to directly to the LightMesh host for processing.
    
.PARAMETER LMImport
Switch defining whether to send the data to LightMesh

.PARAMETER LMHost
Specifies the hostname or ip of the LightMesh appliance.

.PARAMETER LMPort
Specifies the port to use for connecting to the LightMesh appliance.

.PARAMETER LMSecure
Specifies whether the connection is performed over SSL. If using HTTPS, the certificate should be trusted.

.PARAMETER LMToken
Specifies the application token to use when connecting to LightMesh. Should be in the format of "application_id token"

.INPUTS
None. You cannot pipe objects to the script.

.OUTPUTS
None. 

.EXAMPLE
C:\PS> .dhc
#>

[CmdletBinding()]
Param(
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
            $lease_expiry=[Math]::Floor([decimal](Get-Date($lease.LeaseExpiryTime).ToUniversalTime()-uformat "%s"))
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
Add-Member -InputObject $dhcp_server_object -MemberType NoteProperty -Name scopes -Value $dhcp_scopes


$dhcp_json_object = $dhcp_server_object | ConvertTo-Json -Depth 5


Write-Verbose $dhcp_json_object