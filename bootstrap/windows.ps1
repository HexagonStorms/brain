# Stage 1: Windows bootstrap for a fresh Lenovo (or any Windows 11) install.
# Run from an elevated PowerShell prompt.
#
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\windows.ps1
#
# Idempotent. Safe to re-run; winget skips already-installed packages.

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

# --- Wi-Fi ----------------------------------------------------------------
# NOTE: this file is committed to the brain repo. Keeping the household
# Wi-Fi password here is a deliberate convenience. If the brain repo ever
# goes public, rotate the Wi-Fi password and replace this block with an
# interactive Read-Host prompt.

Write-Step "Joining Wi-Fi 'friendly neighborhood spiderman'"

$wifiSsid     = "friendly neighborhood spiderman"
$wifiPassword = "raincloud2@"
$wifiHexSsid  = -join ($wifiSsid.ToCharArray() | ForEach-Object { '{0:X2}' -f [int]$_ })

$profileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>$wifiSsid</name>
  <SSIDConfig>
    <SSID>
      <hex>$wifiHexSsid</hex>
      <name>$wifiSsid</name>
    </SSID>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>auto</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>WPA2PSK</authentication>
        <encryption>AES</encryption>
        <useOneX>false</useOneX>
      </authEncryption>
      <sharedKey>
        <keyType>passPhrase</keyType>
        <protected>false</protected>
        <keyMaterial>$wifiPassword</keyMaterial>
      </sharedKey>
    </security>
  </MSM>
</WLANProfile>
"@

$wifiProfilePath = Join-Path $env:TEMP "wifi-profile.xml"
Set-Content -Path $wifiProfilePath -Value $profileXml -Encoding UTF8
netsh wlan add profile filename="$wifiProfilePath" user=current | Out-Null
netsh wlan connect name=$wifiSsid | Out-Null
Remove-Item $wifiProfilePath -Force

# --- WSL ------------------------------------------------------------------

Write-Step "Installing WSL2 + Ubuntu"

# wsl --install handles enabling features, downloading the kernel, and
# installing the default distro. On a fresh install this requires a reboot.
wsl --install -d Ubuntu --no-launch

# --- winget apps ----------------------------------------------------------

Write-Step "Installing apps via winget"

$wingetApps = @(
    # id, source (msstore or winget)
    @{ id = "Google.Chrome";                              source = "winget"  },
    @{ id = "Valve.Steam";                                source = "winget"  },
    @{ id = "SlackTechnologies.Slack";                    source = "winget"  },
    @{ id = "Anthropic.Claude";                           source = "winget"  },
    @{ id = "Docker.DockerDesktop";                       source = "winget"  },
    @{ id = "Discord.Discord";                            source = "winget"  },
    @{ id = "Cloudflare.Warp";                            source = "winget"  },
    @{ id = "Postman.Postman";                            source = "winget"  },
    @{ id = "PrivateInternetAccess.PrivateInternetAccess"; source = "winget" },
    @{ id = "Tailscale.Tailscale";                        source = "winget"  },
    @{ id = "9WZDNCRFJ4MV";                               source = "msstore" }, # Lenovo Vantage
    @{ id = "9NF8H0H7WMLT";                               source = "msstore" }  # NVIDIA Control Panel
)

foreach ($app in $wingetApps) {
    Write-Host "  -> $($app.id)"
    winget install --exact --id $app.id --source $app.source `
        --accept-source-agreements --accept-package-agreements `
        --silent --disable-interactivity
}

# --- Manual installs notice ----------------------------------------------

Write-Step "Apps that need manual installers"
Write-Host @"
The following are not reliably available via winget. Install them by hand:

  - Ableton Live 12 Suite   https://www.ableton.com/account/  (use license)
  - Riot Client             https://www.riotgames.com/en/download
  - Fregonator (v6.0)       installer not in any package source; restore from backup
  - NVIDIA Graphics Driver  https://www.nvidia.com/Download/index.aspx
                            (RTX 3070 Laptop GPU — installer also brings PhysX
                            and bundles the new NVIDIA App; the Control Panel
                            msstore install above is the legacy panel)

"@ -ForegroundColor Yellow

Write-Step "Stage 1 complete."
Write-Host @"
Next steps:
  1. Reboot if WSL just installed the kernel for the first time.
  2. Launch 'Ubuntu' from the Start menu, finish first-run user setup.
  3. Inside Ubuntu, run:
       bash <(curl -fsSL https://raw.githubusercontent.com/HexagonStorms/brain/main/bootstrap/wsl.sh)
"@ -ForegroundColor Green
