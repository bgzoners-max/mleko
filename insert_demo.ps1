$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$svc    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cXR1anB1cmh6cmFwdG9yY3ZsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjA4MTI0MSwiZXhwIjoyMDg3NjU3MjQxfQ.3rA-sG-QxkuhEMKgehtsdbgKk-bDu1GjRFlZSd2MNmM"
$apiUrl = "https://wvqtujpurhzraptorcvl.supabase.co/rest/v1/products"
$seller = "508b77ee-05de-439f-b3b9-b470c3e0da6d"
$img    = "https://placehold.co/800x600/16a34a/ffffff/png?text=Primer+oglasa"
$desc   = "Ovo je primer oglasa. Pravi oglasi dolaze uskoro."

function Insert-Product($category, $name, $price, $minOrder, $step, $qty, $unit) {
  $obj = [ordered]@{
    seller_id      = $seller
    category       = $category
    name           = $name
    price_per_kg   = $price
    min_order_kg   = $minOrder
    order_step     = $step
    available_kg   = $qty
    unit_type      = $unit
    description    = $desc
    image_urls     = @($img)
    pickup_options = @("$([char]0x4c)i$([char]0x10d)no", "Dogovor")
    location       = "Beograd"
    is_domestic    = $true
    available_now  = $true
  }
  $json  = $obj | ConvertTo-Json -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $wc    = New-Object System.Net.WebClient
  $wc.Headers["apikey"]        = $svc
  $wc.Headers["Authorization"] = "Bearer $svc"
  $wc.Headers["Content-Type"]  = "application/json; charset=utf-8"
  $wc.Headers["Prefer"]        = "return=minimal"
  $wc.UploadData($apiUrl, "POST", $bytes) | Out-Null
  Write-Host "OK: $name"
}

# 16 demo proizvoda sa ispravnim srpskim slovima
Insert-Product "Mleko"                        "[ Primer oglasa ] Mle$([char]0x10d)ni proizvodi"           500  1    1    10  "L"
Insert-Product "Svje$([char]0x17e)e meso"     "[ Primer oglasa ] Meso i prera$([char]0x111)evine"         800  1    1    10  "kg"
Insert-Product "$([char]0x160)unke i pr$([char]0x161)ute"  "[ Primer oglasa ] Suhomesnato"              1200 0.5  0.5  10  "kg"
Insert-Product "Ajvar i ljutenica"            "[ Primer oglasa ] Zimnica i namazi"                         600  0.5  0.5  10  "kg"
Insert-Product "Med"                          "[ Primer oglasa ] Med i p$([char]0x10d)elarski"            1500 0.5  0.5  10  "kg"
Insert-Product "Sve$([char]0x17e)e vo$([char]0x107)e"  "[ Primer oglasa ] Vo$([char]0x107)e i povrce"    200  1    1    20  "kg"
Insert-Product "Prirodni sokovi"              "[ Primer oglasa ] Sokovi i pi$([char]0x107)a"               300  1    1    10  "L"
Insert-Product "Koko$([char]0x161)ija jaja"   "[ Primer oglasa ] Jaja"                                     30   10   10   100 "kom"
Insert-Product "D$([char]0x17e)emovi"         "[ Primer oglasa ] Slatko i d$([char]0x17e)emovi"           700  0.3  0.3  10  "kg"
Insert-Product "Za$([char]0x10d)ini"          "[ Primer oglasa ] Za$([char]0x10d)ini i bilje"             1000 0.1  0.1  5   "kg"
Insert-Product "Hleb i pe$([char]0x10d)iva"   "[ Primer oglasa ] Pekarsko i testa"                         300  0.5  0.5  10  "kg"
Insert-Product "Bra$([char]0x161)no"          "[ Primer oglasa ] Bra$([char]0x161)no i $([char]0x17e)itarice"  150  1  1  50  "kg"
Insert-Product "Sapuni"                       "[ Primer oglasa ] Prirodna kozmetika"                       500  1    1    10  "kom"
Insert-Product "Gotova jela"                  "[ Primer oglasa ] Gotova jela i delikates"                  600  0.5  0.5  5   "kg"
Insert-Product "Smrznuto vo$([char]0x107)e"   "[ Primer oglasa ] Smrznuti proizvodi"                      400  0.5  0.5  10  "kg"
Insert-Product "Poklon setovi"                "[ Primer oglasa ] Poklon paketi"                           1000 1    1    5   "kom"

Write-Host ""
Write-Host "Ubaceno 16 demo proizvoda!"
