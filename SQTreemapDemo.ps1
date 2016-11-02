#region Example using Filesystem against my current drive
$FileInfo = Get-ChildItem -Directory|ForEach {
    $Files = Get-ChildItem $_.fullname -Recurse -File|measure-object -Sum -Property length
    [pscustomobject]@{
        Name = $_.name
        Fullname = $_.fullname
        Count = [int64]$Files.Count
        Size = [int64]$Files.Sum
    }
}
#endregion Example using Filesystem against my current drive

#region Create a custom tooltip
$Tooltip = {
@"
Fullname = $($This.LabelProperty)
FileCount = $($This.Dataproperty)
Size = $([math]::round(($This.HeatmapProperty/1MB),2)) MB
"@
}

#Create the UI
$FileInfo | 
Out-SquarifiedTreeMap -Width 800 -Height 600 -LabelProperty Name `
-DataProperty Count -HeatmapProperty Size -ToolTip $Tooltip -ShowLabel LabelProperty -PassThru    
#endregion Create a custom tooltip

#region Stopping a high memory process
$Tooltip = {
@"
Process Name <PID>:   $($This.LabelProperty) <$($This.ObjectData.Id)>     
WorkingSet Memory(MB): $([math]::Round(($This.DataProperty/1MB),2))
"@
}
Get-Process | Sort-Object -prop WS -Descending | Select -First 8 | 
Out-SquarifiedTreeMap -Tooltip $Tooltip -LabelProperty ProcessName -DataProperty WS -HeatmapProperty WS -Width 600 -Height 400 `
-PassThru -ShowLabel LabelProperty | 
Stop-Process -WhatIf
#endregion Stopping a high memory process

#region Example using Process WorkingSet Memory
Get-Process | 
Out-SquarifiedTreeMap -LabelProperty ProcessName -DataProperty WS -HeatmapProperty WS -Width 600 -Height 400
#endregion Example using Process WorkingSet Memory

#region Example using just data and no object and specifying a heatmap threshold
1..8 | Out-SquarifiedTreeMap -Width 600 -Height 200 -MaxHeatMapSize 15
#endregion Example using just data and no object and specifying a heatmap threshold

#region Example using randomized data
1..8 | ForEach{
    [pscustomobject]@{
        Label = "Label$($_)"
        Count = (Get-Random -InputObject (1..50))
        Data = (Get-Random -InputObject (1..100))
    }
} | Out-SquarifiedTreeMap -Width 600 -Height 200 -DataProperty Count -HeatmapProperty Data -LabelProperty Label -ShowLabel LabelProperty
#endregion Example using randomized data

#region Not using a HeatMap
1..8 | Out-SquarifiedTreeMap -Width 600 -Height 200
#endregion Not using a HeatMap

#region Real World Demo
Function Get-Server {
    [cmdletbinding(DefaultParameterSetName='All')]
    Param (
        [parameter(ParameterSetName='DomainController')]
        [switch]$DomainController,
        [parameter(ParameterSetName='MemberServer')]
        [switch]$MemberServer
    )
    Write-Verbose "Parameter Set: $($PSCmdlet.ParameterSetName)"
    Switch ($PSCmdlet.ParameterSetName) {
        'All' {
            $ldapFilter = "(&(objectCategory=computer)(OperatingSystem=Windows*Server*))"
        }
        'DomainController' {
            $ldapFilter = "(&(objectCategory=computer)(OperatingSystem=Windows*Server*)(userAccountControl:1.2.840.113556.1.4.803:=8192))"
        }
        'MemberServer' {
            $ldapFilter = "(&(objectCategory=computer)(OperatingSystem=Windows*Server*)(!(userAccountControl:1.2.840.113556.1.4.803:=8192)))"
        }
    }
    $searcher = [adsisearcher]""
    $Searcher.Filter = $ldapFilter
    $Searcher.pagesize = 10
    $searcher.sizelimit = 5000
    $searcher.PropertiesToLoad.Add("name") | Out-Null
    $Searcher.sort.propertyname='name'
    $searcher.Sort.Direction = 'Ascending'
    $Searcher.FindAll() | ForEach {
        $_.Properties.name
    }
}
function Get-DriveSpace {
    Param (
        ## Remove to show ValueFromPipeline
        [parameter(ValueFromPipeline)]
        [string[]]$Computername
    )
    Begin {
        $WMIParams = @{
            Filter = "DriveType='3' AND (Not Name LIKE '\\\\?\\%')" 
            Class = "Win32_Volume"
            ErrorAction = "Stop"
            Property = "Name","Label","Capacity","FreeSpace"
        }
    }
    Process {  
        ForEach ($Computer in $Computername) { 
            Try {       
                $WMIParams.Computername = $Computer
                Get-WmiObject @WMIParams | ForEach {
                    $UsedSpace = $_.Capacity - $_.FreeSpace
                    [pscustomobject]@{
                        Computername = $Computer
                        Name = $_.Name
                        Label = $_.Label
                        CapacityGB = [decimal]("{0:N2}" -f ($_.Capacity /1GB))
                        FreeSpaceGB = [decimal]("{0:N2}" -f ($_.FreeSpace /1GB))
                        UsedSpaceGB = [decimal]("{0:N2}" -f ($UsedSpace / 1GB))
                        PercentFree = [decimal]("{0:N4}" -f ($_.FreeSpace / $_.Capacity))
                        PercentFull = [decimal]("{0:N4}" -f ($UsedSpace / $_.Capacity))
                    }
                }
            } Catch {}
        }
    }
}

#Create a custom tooltip
$Tooltip = {
@"
Computername: $($This.ObjectData.Computername)
Drive: $($This.ObjectData.Name)
Label: $($This.ObjectData.Label)
TotalSize: $($This.Dataproperty) GB
PercentFull: $([math]::Round(($This.HeatmapProperty * 100),2)) %
"@
}

Get-DriveSpace -Computername $env:COMPUTERNAME -ErrorAction SilentlyContinue | 
Out-SquarifiedTreeMap -LabelProperty AltLabel -DataProperty CapacityGB -HeatmapProperty PercentFull -ToolTip $Tooltip -MaxHeatMapSize 1
#endregion Real World Demo