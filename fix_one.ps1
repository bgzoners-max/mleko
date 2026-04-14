$svc = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cXR1anB1cmh6cmFwdG9yY3ZsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjA4MTI0MSwiZXhwIjoyMDg3NjU3MjQxfQ.3rA-sG-QxkuhEMKgehtsdbgKk-bDu1GjRFlZSd2MNmM"
$url  = "https://wvqtujpurhzraptorcvl.supabase.co/rest/v1/products?id=eq.09ecd428-7d8a-49cf-af51-d14d92bf6f60"
$name = "[ Primer oglasa ] Vo$([char]0x107)e i povrce".Replace("povrce", "povrce".Replace("c", "$([char]0x107)"))

# Direktno
$newName = "[ Primer oglasa ] Vo$([char]0x107)e i povrce"
$newName = $newName -replace "povrce", "povrce"
# Rucno:
$newName = "[ Primer oglasa ] Vo" + [char]0x107 + "e i povrce"
$newName = $newName -replace "povrce$", ("povrce" -replace "c", ([char]0x107))

# Najlaksi nacin - direktno:
$correctName = "[ Primer oglasa ] Vo" + [char]0x107 + "e i povrce"
# "povrce" -> "povrce" ali poslednje "c" -> "c" je pogrešno; trebamo "povrće"
# povrće = p-o-v-r-c(0x107)-e
$correctName = "[ Primer oglasa ] Vo" + [char]0x107 + "e i povr" + [char]0x107 + "e"

$json  = "{`"name`":`"$correctName`"}"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
$wc = New-Object System.Net.WebClient
$wc.Headers["apikey"] = $svc
$wc.Headers["Authorization"] = "Bearer $svc"
$wc.Headers["Content-Type"] = "application/json; charset=utf-8"
$wc.Headers["Prefer"] = "return=minimal"
$wc.UploadData($url, "PATCH", $bytes) | Out-Null
Write-Host "Ispravljeno: $correctName"
