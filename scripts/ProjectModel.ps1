Set-StrictMode -Version Latest

function Get-MayhemProjectModel {
    param([Parameter(Mandatory=$true)][string]$ProjectRoot)
    $projectRootFull = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
    $config = Get-Content -Raw -LiteralPath (Join-Path $projectRootFull 'default.project.json') | ConvertFrom-Json
    $entries = [Collections.Generic.List[object]]::new()
    $sourcePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    function Add-MayhemXml {
        param($Item, [string]$Name, [string]$Parent, [string]$LogicalParent)
        $logical = if ($LogicalParent) { "$LogicalParent.$Name" } else { $Name }
        $referent = 'RBX' + ($entries.Count + 1)
        $entries.Add([pscustomobject]@{Name=$Name; Class=$Item.GetAttribute('class'); Parent=$Parent; Referent=$referent; LogicalPath=$logical; Source=$null; Properties=$null; XmlProperties=$Item.Properties})
        foreach ($child in $Item.SelectNodes('Item')) {
            $childName = $child.SelectSingleNode('Properties/string[@name="Name"]').InnerText
            Add-MayhemXml -Item $child -Name $childName -Parent $referent -LogicalParent $logical
        }
    }

    function Add-MayhemNode {
        param([string]$Name, $Node, [string]$Parent, [string]$LogicalParent)
        $source = $null
        $directory = $null
        $pathProperty = $Node.PSObject.Properties['$path']
        if ($pathProperty) {
            $rawPath = [string]$pathProperty.Value
            $resolved = [IO.Path]::GetFullPath($(if ([IO.Path]::IsPathRooted($rawPath)) { $rawPath } else { Join-Path $projectRootFull $rawPath }))
            if (-not $resolved.StartsWith($projectRootFull + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Source path escapes project: $resolved" }
            if (-not (Test-Path -LiteralPath $resolved)) { throw "Missing project path: $resolved" }
            if (Test-Path -LiteralPath $resolved -PathType Container) { $directory = $resolved }
            else {
                if ([IO.Path]::GetExtension($resolved) -eq '.rbxmx') {
                    $document = [xml][IO.File]::ReadAllText($resolved)
                    Add-MayhemXml -Item $document.roblox.Item -Name $Name -Parent $Parent -LogicalParent $LogicalParent
                    return
                }
                if ([IO.Path]::GetExtension($resolved) -ne '.luau') { throw "Offline builder only supports Luau source files: $resolved" }
                $source = $resolved
                [void]$sourcePaths.Add($source)
            }
        }
        $classProperty = $Node.PSObject.Properties['$className']
        $class = if ($classProperty) { $classProperty.Value } elseif ($source -match '\.server\.luau$') { 'Script' } elseif ($source -match '\.client\.luau$') { 'LocalScript' } elseif ($source) { 'ModuleScript' } else { 'Folder' }
        $properties = $Node.PSObject.Properties['$properties']
        $logical = if ($LogicalParent) { "$LogicalParent.$Name" } else { $Name }
        $referent = 'RBX' + ($entries.Count + 1)
        $entries.Add([pscustomobject]@{
            Name=$Name; Class=$class; Parent=$Parent; Referent=$referent; LogicalPath=$logical;
            Source=$source; Properties=$(if ($properties) { $properties.Value } else { $null }); XmlProperties=$null
        })
        if ($directory) {
            foreach ($child in Get-ChildItem -LiteralPath $directory | Sort-Object Name) {
                if ($child.PSIsContainer) { $childNode = [pscustomobject]@{ '$path'=$child.FullName }; $childName=$child.Name }
                elseif ($child.Extension -in @('.luau','.rbxmx')) {
                    $childNode = [pscustomobject]@{ '$path'=$child.FullName }
                    $childName = $child.Name -replace '(\.server|\.client)?\.luau$|\.rbxmx$',''
                } else { throw "Unsupported file under mapped source directory: $($child.FullName)" }
                Add-MayhemNode -Name $childName -Node $childNode -Parent $referent -LogicalParent $logical
            }
        }
        foreach ($property in $Node.PSObject.Properties) {
            if (-not $property.Name.StartsWith('$')) { Add-MayhemNode -Name $property.Name -Node $property.Value -Parent $referent -LogicalParent $logical }
        }
    }

    if ($config.tree.'$className' -ne 'DataModel') { throw 'The project root must be a DataModel' }
    foreach ($property in $config.tree.PSObject.Properties) {
        if (-not $property.Name.StartsWith('$')) { Add-MayhemNode -Name $property.Name -Node $property.Value -Parent '' -LogicalParent '' }
    }
    return [pscustomobject]@{ Config=$config; Entries=$entries; SourcePaths=$sourcePaths }
}
