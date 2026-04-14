$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$svc  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cXR1anB1cmh6cmFwdG9yY3ZsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjA4MTI0MSwiZXhwIjoyMDg3NjU3MjQxfQ.3rA-sG-QxkuhEMKgehtsdbgKk-bDu1GjRFlZSd2MNmM"
$base = "https://wvqtujpurhzraptorcvl.supabase.co/rest/v1/products"

# Pomocna funkcija za PATCH
function Patch-Product($id, $cat) {
  $url   = "$base`?id=eq.$id"
  $json  = @{ category = $cat } | ConvertTo-Json -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $wc    = New-Object System.Net.WebClient
  $wc.Headers["apikey"]        = $svc
  $wc.Headers["Authorization"] = "Bearer $svc"
  $wc.Headers["Content-Type"]  = "application/json; charset=utf-8"
  $wc.Headers["Prefer"]        = "return=minimal"
  $wc.UploadData($url, "PATCH", $bytes) | Out-Null
  Write-Host "OK: $id -> $cat"
}

Patch-Product "96a1ed31-39de-4645-b6ba-8bcbf176fe0c" "Sve$([char]0x017e)e meso"
Patch-Product "792c86c1-fdb8-4a51-88ff-6c01d9593191" "$([char]0x160)unke i pr$([char]0x161)ute"
Patch-Product "52a99a73-6f54-42b6-acb2-bb422e6e5093" "Sve$([char]0x17e)e vo$([char]0x107)e"
Patch-Product "f305f067-d2d3-493c-9254-ad25b15f7a02" "Koko$([char]0x161)ija jaja"
Patch-Product "617a57cd-df7b-487f-9557-0dcfb0b1246d" "D$([char]0x17e)emovi"
Patch-Product "f292e257-67e8-41a0-ac3c-f32f9821db7e" "Za$([char]0x10d)ini"
Patch-Product "fbf4cad2-809e-4a75-bdca-8eb111255e83" "Hleb i pe$([char]0x10d)iva"
Patch-Product "d30d0172-5308-40b9-abed-36b420e0dcf8" "Bra$([char]0x161)no"
Patch-Product "7f53f8f2-f22b-427b-86e5-e18f796563ae" "Smrznuto vo$([char]0x107)e"

Write-Host "Gotovo!"
