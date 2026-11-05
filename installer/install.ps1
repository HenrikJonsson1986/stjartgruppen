<#
Installs or updates the Stjartgruppen addon for WoW: Forever.

Double-click "Install Stjartgruppen.bat" instead of running this file directly.
All it does: find your World of Warcraft folder and copy the Stjartgruppen folder
into World of Warcraft\_forever_\Interface\AddOns (replacing an older copy).
Your addon settings live in the WTF folder and are not touched.

Options (for advanced use):
  -WowPath "D:\Games\World of Warcraft"   use this game folder instead of searching
  -DryRun                                  only show what would happen
  -NoPause                                 do not wait for Enter at the end
#>
param(
    [string]$WowPath,
    [switch]$DryRun,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$AddonName = 'Stjartgruppen'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $Here $AddonName

function Say([string]$msg, [string]$color = 'Gray') { Write-Host $msg -ForegroundColor $color }

# Returns the World of Warcraft root folder (the one that contains _forever_), or $null.
function Test-WowRoot([string]$path) {
    if (-not $path) { return $null }
    $p = $path.Trim().Trim('"').TrimEnd('\', '/')
    if (-not $p) { return $null }
    if (Test-Path -LiteralPath $p -PathType Leaf) { $p = Split-Path -Parent $p }      # e.g. ...\Wow.exe
    if ((Split-Path -Leaf $p) -match '^_\w+_$') { $p = Split-Path -Parent $p }       # e.g. ...\_retail_
    if (Test-Path -LiteralPath (Join-Path $p '_forever_') -PathType Container) { return $p }
    return $null
}

function Find-Wow {
    $candidates = New-Object System.Collections.Generic.List[string]
    $keys = @(
        'HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft',
        'HKLM:\SOFTWARE\Blizzard Entertainment\World of Warcraft',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\World of Warcraft',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\World of Warcraft'
    )
    foreach ($k in $keys) {
        try {
            $props = Get-ItemProperty -LiteralPath $k -ErrorAction Stop
            foreach ($name in 'InstallPath', 'InstallLocation', 'GamePath') {
                if ($props.$name) { $candidates.Add([string]$props.$name) }
            }
        } catch { }
    }
    $subs = @(
        'Program Files (x86)\World of Warcraft', 'Program Files\World of Warcraft',
        'World of Warcraft', 'Games\World of Warcraft', 'Blizzard\World of Warcraft',
        'Battle.net\World of Warcraft', 'Program Files (x86)\Battle.net\World of Warcraft'
    )
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        foreach ($sub in $subs) { $candidates.Add((Join-Path $drive.Root $sub)) }
    }
    foreach ($c in $candidates) {
        $ok = Test-WowRoot $c
        if ($ok) { return $ok }
    }
    return $null
}

function Select-WowFolder {
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Select your World of Warcraft folder (the one that contains the _forever_ folder)'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return Test-WowRoot $dlg.SelectedPath }
    return $null
}

function Test-Writable([string]$dir) {
    try {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $probe = Join-Path $dir ('.sg-write-test-' + [guid]::NewGuid().ToString('N'))
        [System.IO.File]::WriteAllText($probe, 'x')
        Remove-Item -LiteralPath $probe -Force
        return $true
    } catch {
        return $false
    }
}

$exitCode = 0
try {
    Say ''
    Say '  Stjartgruppen installer for WoW: Forever' 'Cyan'
    Say ''

    $toc = Join-Path $Source "$AddonName.toc"
    if (-not (Test-Path -LiteralPath $toc)) {
        throw "Can't find the $AddonName folder next to this installer. Unzip the whole download first, then run the installer from the unzipped folder."
    }
    $match = Select-String -LiteralPath $toc -Pattern '^## Version:\s*(.+)$' | Select-Object -First 1
    $version = if ($match) { $match.Matches[0].Groups[1].Value.Trim() } else { 'unknown' }

    if ($WowPath) {
        $root = Test-WowRoot $WowPath
        if (-not $root) { throw "'$WowPath' is not a World of Warcraft folder with WoW: Forever (no _forever_ folder inside)." }
    } else {
        Say 'Looking for World of Warcraft...'
        $root = Find-Wow
        if (-not $root) {
            Say "Couldn't find it automatically. A folder picker will open: choose your World of Warcraft folder." 'Yellow'
            $root = Select-WowFolder
        }
        if (-not $root) { throw 'No World of Warcraft folder with WoW: Forever (_forever_) was selected.' }
    }

    $addons = Join-Path $root '_forever_\Interface\AddOns'
    $dest = Join-Path $addons $AddonName
    $old = Join-Path $dest "$AddonName.toc"
    $oldVersion = $null
    if (Test-Path -LiteralPath $old) {
        $m = Select-String -LiteralPath $old -Pattern '^## Version:\s*(.+)$' | Select-Object -First 1
        if ($m) { $oldVersion = $m.Matches[0].Groups[1].Value.Trim() }
    }

    Say "Game folder:  $root"
    Say "Installing:   $AddonName $version"
    if ($oldVersion) { Say "Replacing:    version $oldVersion" }
    Say "Destination:  $dest"

    if ($DryRun) {
        Say ''
        Say 'Dry run: nothing was changed.' 'Yellow'
    } elseif (-not (Test-Writable $addons)) {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($isAdmin) { throw "No permission to write to $addons" }
        Say ''
        Say 'Windows needs administrator permission to write to the game folder. Click Yes on the next prompt.' 'Yellow'
        $elevArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-WowPath', "`"$root`"")
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $elevArgs -Wait
        Say 'The administrator window has finished.'
    } else {
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        Copy-Item -LiteralPath $Source -Destination $dest -Recurse
        Get-ChildItem -LiteralPath $dest -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
        Say ''
        Say "Done! $AddonName $version is installed." 'Green'
        Say 'If the game is running, quit it fully and start it again. Then type /sg in game.'
    }
} catch {
    Say ''
    Say ("Install failed: " + $_.Exception.Message) 'Red'
    $exitCode = 1
} finally {
    if (-not $NoPause) {
        Say ''
        Read-Host 'Press Enter to close' | Out-Null
    }
}
exit $exitCode
