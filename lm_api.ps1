function LM-Add-Note{
#BETA
Param (
        [Parameter(Mandatory=$true, Position=1)]
        [int]$id,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$text
    )
$note = New-Object -TypeName PSObject
$has_notes = New-Object -TypeName PSObject
$has_notes | Add-Member -MemberType NoteProperty -Name set $id
$note | Add-Member -MemberType NoteProperty -Name has_notes $has_notes
$json=$note  | ConvertTo-Json
Write-Host $json
 XN PUT "/model/note?format=full,properties" $json
}