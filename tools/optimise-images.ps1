# Shrinks oversized photos in images/ ready for the web.
#
#   Preview:  powershell -File tools/optimise-images.ps1
#   Apply:    powershell -File tools/optimise-images.ps1 -Apply
#
# Only looks at files git reports as UNTRACKED, so anything already committed has
# already been through this and is left alone. Re-encoding a JPEG a second time loses
# quality for no size benefit, so the script also skips any file that is already
# within the size cap and not unreasonably large.
#
# Files ending -orig are skipped on purpose: that suffix means "keep my full-res
# original", and shrinking it would destroy the thing being kept.

param(
  [switch]$Apply,
  [int]$Max = 1600,      # longest edge, in px. Plenty for a lightbox photo.
  [int]$Quality = 82
)

Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot

Push-Location $root
$files = @(& git status --porcelain=v1 -- images/ |
  Where-Object { $_ -match '^\?\?' } |
  ForEach-Object { ($_ -replace '^\?\?\s+', '').Trim() } |
  Where-Object { $_ -match '\.(jpe?g|png)$' } |
  Where-Object { $_ -notmatch '-orig\.[^.]+$' })
Pop-Location

if (-not $files.Count) { "Nothing untracked in images/ to optimise."; return }

$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$qp = New-Object System.Drawing.Imaging.EncoderParameters 1
$qp.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $Quality)

# Phone photos carry EXIF orientation. System.Drawing ignores it, so without this a
# portrait photo comes out rotated.
function Get-Flip($img) {
  if ($img.PropertyIdList -notcontains 0x0112) { return $null }
  switch ($img.GetPropertyItem(0x0112).Value[0]) {
    2 {'RotateNoneFlipX'} 3 {'Rotate180FlipNone'} 4 {'RotateNoneFlipY'}
    5 {'Rotate90FlipX'}   6 {'Rotate90FlipNone'}  7 {'Rotate270FlipX'}
    8 {'Rotate270FlipNone'} default {$null}
  }
}

$before = 0; $after = 0; $done = @(); $skipped = @(); $failed = @()

foreach ($rel in $files) {
  # git prints forward slashes; normalise so the path is consistent on Windows.
  $path = Join-Path $root ($rel -replace '/', '\')
  if (-not (Test-Path -LiteralPath $path)) { continue }
  $name = Split-Path $rel -Leaf
  $b = (Get-Item $path).Length

  $bytes = [System.IO.File]::ReadAllBytes($path)
  $ms = New-Object System.IO.MemoryStream(,$bytes)
  $img = [System.Drawing.Image]::FromStream($ms)
  $long = [Math]::Max($img.Width, $img.Height)

  if ($long -le $Max -and $b -le 800KB) {
    $skipped += "$name ($($img.Width)x$($img.Height), $([int]($b/1KB)) KB)"
    $img.Dispose(); $ms.Dispose(); continue
  }

  $flip = Get-Flip $img
  $scale = [Math]::Min(1.0, $Max / $long)
  $nw = [int][Math]::Round($img.Width * $scale); $nh = [int][Math]::Round($img.Height * $scale)

  $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
  $bmp.SetResolution($img.HorizontalResolution, $img.VerticalResolution)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode='HighQualityBicubic'; $g.PixelOffsetMode='HighQuality'
  $g.SmoothingMode='HighQuality'; $g.CompositingQuality='HighQuality'
  $g.DrawImage($img, 0, 0, $nw, $nh); $g.Dispose()
  if ($flip) { $bmp.RotateFlip($flip); $nw = $bmp.Width; $nh = $bmp.Height }
  $img.Dispose(); $ms.Dispose()

  $a = $b
  if ($Apply) {
    # Write to temp then move. Saving straight over the source from inside a script
    # throws a generic GDI+ error in this environment, and this shape also means a
    # failed encode can never leave a truncated original behind.
    $tmp = [System.IO.Path]::Combine($env:TEMP, "opt-$name")
    try {
      $bmp.Save($tmp, $jpeg, $qp)
      $bmp.Dispose()
      Move-Item -LiteralPath $tmp -Destination $path -Force
      $a = (Get-Item $path).Length
    } catch {
      $failed += "$name : $($_.Exception.Message)"
      if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
      continue
    }
  } else { $bmp.Dispose() }

  $before += $b; $after += $a
  $done += [pscustomobject]@{
    File = $name
    Dim = "$($nw)x$($nh)"
    Orient = if ($nw -gt $nh) { "landscape" } elseif ($nh -gt $nw) { "portrait" } else { "square" }
    KB = [int]($a/1KB)
    Exif = if ($flip) { "rotated" } else { "" }
  }
}

if ($done.Count) { $done | Format-Table -AutoSize }
if ($skipped.Count) {
  "Skipped, already web-sized:"
  $skipped | ForEach-Object { "  $_" }
}
if ($done.Count) {
  "{0} processed: {1:N1} MB -> {2:N1} MB ({3:N0}% smaller)" -f `
    $done.Count, ($before/1MB), ($after/1MB), ((1 - $after/$before) * 100)
}
if ($failed.Count) { "`n$($failed.Count) FAILED:"; $failed | ForEach-Object { "  $_" } }
elseif ($Apply -and $done.Count) { "all writes succeeded" }
if (-not $Apply) { "`nDRY RUN. Re-run with -Apply to write." }
