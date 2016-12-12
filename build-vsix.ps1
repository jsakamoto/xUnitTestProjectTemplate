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

# Create "manifest.json".
$baseDir = (pwd).Path
$srcFiles = @(ls (Join-Path $baseDir "ProjectTemplates") -Recurse -File | % { $_.FullName })
$srcFiles += @("icon.png", "extension.vsixmanifest") | % { ls (Join-Path $baseDir $_) } | % { $_.FullName }
$files = $srcFiles | % {
  @{
    sha256 = (Get-FileHash $_ -Algorithm SHA256).Hash;
    fileName = $_.Substring($baseDir.Length).Replace("\","/");
  }
}

$manifestJson = @{
    id = "xUnitProjectTemplate";
    version = $ver;
    type =  "Vsix";
    language = "en-us";
    vsixId = "xUnitProjectTemplate";
    extensionDir = "[installdir]\Common7\IDE\Extensions\nx3pocv5.jy3";
    files = $files;
    dependencies = @{
        "Microsoft.VisualStudio.Component.CoreEditor" = "[11.0,16.0)";
    }
}
$manifestJson | ConvertTo-Json -Compress | Out-File "manifest.json" -Encoding utf8

# Create .vsix a package with embedding version information.
$zip = new-object Ionic.Zip.ZipFile
$zip.AddFile((Convert-Path '.\`[Content_Types`].xml'), "") > $null
$zip.AddFile((Convert-Path .\extension.vsixmanifest), "") > $null
$zip.AddFile((Convert-Path .\manifest.json), "") > $null
$zip.AddFile((Convert-Path .\catalog.json), "") > $null
$zip.AddFile((Convert-Path .\icon.png), "") > $null
#$zip.AddFile((Convert-Path .\release-notes.txt), "") > $null
$zip.AddDirectory((Convert-Path .\ProjectTemplates), "ProjectTemplates") > $null
$zip.Save((Join-Path $scriptDir "xUnitTestProjectTemplate.$ver.vsix"))
#DEBUG: $zip.Save((Join-Path $scriptDir "xUnitTestProjectTemplate.zip"))
$zip.Dispose()

# Clean up working files.
del .\ProjectTemplates -Recurse -Force
