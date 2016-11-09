# SquarifiedTreemap
Code to generate a squarified treemap UI for data visualization

### Now with Customizable Label and Passthru support!
```PowerShell
#region Stopping a high memory process
$Tooltip = {
@"
Process Name <PID>:   $($This.LabelProperty) <$($This.ObjectData.Id)>     
WorkingSet Memory(MB): $([math]::Round(($This.DataProperty/1MB),2))
"@
}
Get-Process | Sort-Object -prop WS -Descending | Select -First 8 | 
Out-SquarifiedTreeMap -Tooltip $Tooltip -LabelProperty ProcessName -DataProperty WS -HeatmapProperty WS -Width 800 -Height 600 `
-PassThru -ShowLabel {"$($This.LabelProperty) <$($This.ObjectData.ID)>"} | 
Stop-Process -WhatIf
#endregion Stopping a high memory process
```
![alt tag](https://github.com/proxb/SquarifiedTreemap/blob/master/Images/SqTreeMap.png)

```PowerShell
#region Example using randomized data
1..8 | ForEach{
    [pscustomobject]@{
        Label = "Label$($_)"
        Count = (Get-Random -InputObject (1..50))
        Data = (Get-Random -InputObject (1..100))
    }
} | Out-SquarifiedTreeMap -Width 600 -Height 200 -DataProperty Count -HeatmapProperty Data -LabelProperty Label
#endregion Example using randomized data
```

![alt tag](https://github.com/proxb/SquarifiedTreemap/blob/master/Images/sqtreemap1.png)

```PowerShell
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
Out-SquarifiedTreeMap -Width 600 -Height 200 -LabelProperty Fullname -DataProperty Count -HeatmapProperty Size -ToolTip $Tooltip
#endregion Create a custom tooltip
```

![alt tag](https://github.com/proxb/SquarifiedTreemap/blob/master/Images/sqtreemap2.png)
