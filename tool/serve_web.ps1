# Minimal static server for build\web (local preview only).
# Keep this file ASCII-only: Windows PowerShell 5.1 misreads UTF-8 without BOM.
$Port = if ($env:PORT) { [int]$env:PORT } else { 8080 }

$root = Join-Path $PSScriptRoot '..\build\web' | Resolve-Path
$types = @{
  '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript'; '.mjs' = 'text/javascript'
  '.json' = 'application/json'; '.css' = 'text/css'; '.png' = 'image/png'; '.jpg' = 'image/jpeg'
  '.svg' = 'image/svg+xml'; '.wasm' = 'application/wasm'; '.otf' = 'font/otf'; '.ttf' = 'font/ttf'
  '.ico' = 'image/x-icon'; '.bin' = 'application/octet-stream'; '.frag' = 'application/octet-stream'
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/"

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
  if ($rel -eq '') { $rel = 'index.html' }
  $file = Join-Path $root $rel
  if (-not (Test-Path $file -PathType Leaf)) { $file = Join-Path $root 'index.html' }
  $ext = [IO.Path]::GetExtension($file).ToLower()
  $ctx.Response.ContentType = $(if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' })
  $bytes = [IO.File]::ReadAllBytes($file)
  $ctx.Response.ContentLength64 = $bytes.Length
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.Close()
}
