# ansilust installer script
#
# Served from: https://ansilust.com/install.ps1
# Source: https://github.com/effect-native/ansilust/blob/main/scripts/install.ps1
#
# Usage: irm ansilust.com/install.ps1 | iex
#
# For security, you should review this script before running:
# irm ansilust.com/install.ps1 | more
#

param(
  [Switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# Configuration
$REPO = "effect-native/ansilust"
$INSTALL_DIR = "$env:LOCALAPPDATA\ansilust\bin"
$GITHUB_RELEASES = "https://github.com/$REPO/releases"
$TEMP_DIR = [System.IO.Path]::GetTempPath() + "ansilust-$(New-Guid)"

# Cleanup on exit
function Cleanup {
  if (Test-Path $TEMP_DIR) {
    Remove-Item -Path $TEMP_DIR -Recurse -Force | Out-Null
  }
}
trap { Cleanup }

# Color output helpers
function Write-Info {
  Write-Host "[ℹ] " -ForegroundColor Blue -NoNewline
  Write-Host $args
}

function Write-Success {
  Write-Host "[✓] " -ForegroundColor Green -NoNewline
  Write-Host $args
}

function Write-Error-Custom {
  Write-Host "[✗] " -ForegroundColor Red -NoNewline
  Write-Error $args
}

function Write-Warning-Custom {
  Write-Host "[⚠] " -ForegroundColor Yellow -NoNewline
  Write-Host $args
}

# Detect platform
function Detect-Platform {
  $arch = $env:PROCESSOR_ARCHITECTURE
  
  switch ($arch) {
    "AMD64" {
      $platform = "win32-x64"
    }
    "ARM64" {
      $platform = "win32-arm64"
    }
    default {
      Write-Error-Custom "Unsupported architecture: $arch"
      return $null
    }
  }
  
  return $platform
}

# Download binary with retry
function Download-Binary {
  param(
    [string]$Platform
  )
  
  $url = "$GITHUB_RELEASES/latest/download/ansilust-$Platform.zip"
  $output = Join-Path $TEMP_DIR "ansilust.zip"
  $maxRetries = 3
  $retry = 0
  
  Write-Info "Downloading ansilust for $Platform..."
  
  while ($retry -lt $maxRetries) {
    try {
      if ($WhatIf) {
        Write-Host "Would download from: $url" -ForegroundColor Yellow
        return $output
      }
      
      Invoke-WebRequest -Uri $url -OutFile $output -TimeoutSec 30 -ErrorAction Stop
      
      if (Test-Path $output) {
        Write-Success "Downloaded successfully"
        return $output
      }
    } catch {
      $retry += 1
      if ($retry -lt $maxRetries) {
        Write-Warning-Custom "Download failed, retrying... ($retry/$maxRetries)"
        Start-Sleep -Seconds 2
      }
    }
  }
  
  Write-Error-Custom "Failed to download after $maxRetries attempts"
  Write-Info "Please check:"
  Write-Host "  - Your internet connection"
  Write-Host "  - The platform '$Platform' is supported"
  Write-Host "  - Latest release exists at: $GITHUB_RELEASES"
  return $null
}

# Verify checksum
function Verify-Checksum {
  param(
    [string]$FilePath,
    [string]$Platform
  )
  
  $checksumsFile = Join-Path $TEMP_DIR "SHA256SUMS"
  
  Write-Info "Downloading checksums..."
  
  try {
    if ($WhatIf) {
      Write-Host "Would download checksums from: $GITHUB_RELEASES/latest/download/SHA256SUMS" -ForegroundColor Yellow
      return $true
    }
    
    Invoke-WebRequest -Uri "$GITHUB_RELEASES/latest/download/SHA256SUMS" -OutFile $checksumsFile -ErrorAction Stop
  } catch {
    Write-Warning-Custom "Could not download checksums, skipping verification"
    return $true
  }
  
  Write-Info "Verifying checksum..."
  
  $checksumContent = Get-Content $checksumsFile | Select-String "ansilust-$Platform.zip"
  
  if (-not $checksumContent) {
    Write-Warning-Custom "Checksum for platform '$Platform' not found, skipping verification"
    return $true
  }
  
  $expectedHash = ($checksumContent -split '\s+')[0]
  $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()
  
  if ($expectedHash -eq $actualHash) {
    Write-Success "Checksum verified"
    return $true
  } else {
    Write-Error-Custom "Checksum mismatch!"
    Write-Error-Custom "  Expected: $expectedHash"
    Write-Error-Custom "  Got:      $actualHash"
    return $false
  }
}

# Install binary
function Install-Binary {
  param(
    [string]$ZipFile,
    [string]$Platform
  )
  
  Write-Info "Extracting binary..."
  
  $extractDir = Join-Path $TEMP_DIR "extract"
  New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
  
  if ($WhatIf) {
    Write-Host "Would extract from: $ZipFile to: $extractDir" -ForegroundColor Yellow
    Write-Host "Would install to: $INSTALL_DIR\ansilust.exe" -ForegroundColor Yellow
    return $true
  }
  
  try {
    Expand-Archive -Path $ZipFile -DestinationPath $extractDir -Force
  } catch {
    Write-Error-Custom "Failed to extract zip file"
    return $false
  }
  
  # Find the binary
  $binary = Get-ChildItem -Path $extractDir -Name "ansilust.exe" -Recurse | Select-Object -First 1
  
  if (-not $binary) {
    Write-Error-Custom "Could not find 'ansilust.exe' in zip file"
    return $false
  }
  
  $binaryPath = if ($binary -is [System.IO.FileInfo]) {
    $binary.FullName
  } else {
    Join-Path $extractDir $binary
  }
  
  # Create install directory if needed
  if (-not (Test-Path $INSTALL_DIR)) {
    Write-Info "Creating $INSTALL_DIR..."
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
  }
  
  Write-Info "Installing to $INSTALL_DIR..."
  
  try {
    Copy-Item -Path $binaryPath -Destination (Join-Path $INSTALL_DIR "ansilust.exe") -Force
  } catch {
    Write-Error-Custom "Failed to copy binary to $INSTALL_DIR"
    Write-Error-Custom "Try running PowerShell as Administrator"
    return $false
  }
  
  Write-Success "Binary installed to $INSTALL_DIR"
  return $true
}

# Add to PATH
function Add-To-Path {
  Write-Info "Checking PATH..."
  
  $userPath = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
  
  if ($userPath -like "*$INSTALL_DIR*") {
    Write-Success "$INSTALL_DIR is already in your PATH"
    return
  }
  
  if ($WhatIf) {
    Write-Host "Would add $INSTALL_DIR to user PATH" -ForegroundColor Yellow
    return
  }
  
  Write-Warning-Custom "$INSTALL_DIR is not in your PATH"
  Write-Info "Adding to user PATH..."
  
  try {
    $newPath = "$INSTALL_DIR;$userPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Success "Added to PATH"
    Write-Info "Restart your terminal or PowerShell for the change to take effect"
  } catch {
    Write-Error-Custom "Failed to update PATH: $_"
    Write-Info "Please add manually: $INSTALL_DIR to your PATH environment variable"
  }
}

# Verify installation
function Verify-Installation {
  $binaryPath = Join-Path $INSTALL_DIR "ansilust.exe"
  
  Write-Info "Verifying installation..."
  
  if (-not (Test-Path $binaryPath)) {
    Write-Error-Custom "Binary not found at $binaryPath"
    return $false
  }
  
  if ($WhatIf) {
    Write-Host "Would verify binary at: $binaryPath" -ForegroundColor Yellow
    return $true
  }
  
  try {
    $version = & $binaryPath --version 2>&1
    Write-Success "Installation successful! Version: $version"
  } catch {
    Write-Error-Custom "Binary exists but failed to execute"
    return $false
  }
  
  if ($env:Path -notlike "*$INSTALL_DIR*") {
    Write-Warning-Custom "Note: $INSTALL_DIR is not in your current PATH"
    Write-Info "Restart your terminal for the PATH change to take effect"
  }
  
  return $true
}

# Main installation flow
function Main {
  Write-Info "ansilust installer"
  
  Write-Info "Detecting platform..."
  
  $platform = Detect-Platform
  if (-not $platform) {
    return $false
  }
  
  Write-Success "Detected platform: $platform"
  
  $zipFile = Download-Binary -Platform $platform
  if (-not $zipFile) {
    return $false
  }
  
  if (-not $WhatIf) {
    if (-not (Verify-Checksum -FilePath $zipFile -Platform $platform)) {
      return $false
    }
  }
  
  if (-not (Install-Binary -ZipFile $zipFile -Platform $platform)) {
    return $false
  }
  
  Add-To-Path
  
  if (-not (Verify-Installation)) {
    return $false
  }
  
  Write-Host ""
  Write-Success "Installation complete!"
  Write-Host ""
  Write-Info "Get started:"
  Write-Host "  ansilust --help"
  Write-Host ""
  
  return $true
}

# Run main function
Main
