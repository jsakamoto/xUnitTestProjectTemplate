# move current folder to where contains this .ps1 script file.
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
pushd $scriptDir
[System.Reflection.Assembly]::LoadFile((Convert-Path "Ionic.Zip.dll")) > $null

# Compress project template contents into .zip file.
$projectTemplateDir = Join-Path $scriptDir "ProjectTemplates\CSharp\Test"
if ((Test-Path $projectTemplateDir) -eq $false){
    mkdir $projectTemplateDir > $null
}
$zip = new-object Ionic.Zip.ZipFile
$zip.AddDirectory((Convert-Path 'Project Template Source'), "") > $null
$zip.Save((Join-Path $projectTemplateDir "xUnitTestProject.zip"))
$zip.Dispose()

# Get version infomation from reading manifest file.
$manifest = [xml](cat .\extension.vsixmanifest -Raw)
$ver = $manifest.PackageManifest.Metadata.Identity.Version

# Create .vsix a package with embedding version information.
$zip = new-object Ionic.Zip.ZipFile
$zip.AddFile((Convert-Path '.\`[Content_Types`].xml'), "") > $null
$zip.AddFile((Convert-Path .\extension.vsixmanifest), "") > $null
#$zip.AddFile((Convert-Path .\release-notes.txt), "") > $null
$zip.AddDirectory((Convert-Path .\ProjectTemplates), "ProjectTemplates") > $null
$zip.Save((Join-Path $scriptDir "xUnitTestProjectTemplate.$ver.vsix"))
#DEBUG: $zip.Save((Join-Path $scriptDir "xUnitTestProjectTemplate.zip"))
$zip.Dispose()

# Clean up working files.
del .\ProjectTemplates -Recurse -Force
