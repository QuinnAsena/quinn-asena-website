# Builds images/og-card.jpg, the 1200x630 preview image that LinkedIn, Bluesky, Slack
# and email clients show when someone shares a link to this site.
#
#   Run:  powershell -File tools/make-og-card.ps1
#
# Edit the text below and re-run. Nothing else needs changing: _quarto.yml already
# points open-graph and twitter-card at images/og-card.jpg.
#
# 1200x630 is the size those platforms crop to. Keep it, or the card gets letterboxed.

# ---------------------------------------------------------------------------
# TEXT: edit these
# ---------------------------------------------------------------------------
$name = "Quinn Asena"
$role = "Ecologist and data scientist"

# Positioning statement. Write it however you like: the script measures the text and
# wraps it to fit, so line breaks here are only for your own readability. There is room
# for 3 lines; the script warns if it needs more.
$lede = @(
  "Invetigating ecological dynamics in the past, present and future",
  "with statistical and process-based modelling, deep learning",
  "and continental-scale simulation."
)

# Research areas, joined with a middle dot.
$tags = @("Palaeoecology", "Wildfire risk", "Boreal forests")

$photo = "images\profile_pic.jpg"   # shown at its native aspect ratio, never cropped

# ---------------------------------------------------------------------------
# Rendering: no need to edit below here
# ---------------------------------------------------------------------------
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$out  = Join-Path $root "images\og-card.jpg"
$src  = Join-Path $root $photo

$W = 1200; $H = 630
$cream   = [System.Drawing.ColorTranslator]::FromHtml("#FDFBF7")
$teal900 = [System.Drawing.ColorTranslator]::FromHtml("#0A4552")
$teal700 = [System.Drawing.ColorTranslator]::FromHtml("#106074")
$teal500 = [System.Drawing.ColorTranslator]::FromHtml("#147C91")
$gray    = [System.Drawing.ColorTranslator]::FromHtml("#64605F")
$border  = [System.Drawing.ColorTranslator]::FromHtml("#EFE6D2")

# Punctuation from a char code on purpose: PowerShell 5.1 reads .ps1 as ANSI, so a
# literal UTF-8 middot typed into this file arrives as mojibake ("Â·").
$sep = " " + [char]0x00B7 + " "

$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.TextRenderingHint = 'ClearTypeGridFit'
$g.Clear($cream)

# Brand bar along the bottom, echoing the accent rule under the site navbar.
$g.FillRectangle((New-Object System.Drawing.SolidBrush($teal500)), 0, $H - 14, $W, 14)

# Photo at native aspect, rounded to match the site's card treatment.
$img = [System.Drawing.Image]::FromFile($src)
$pw = 448
$ph = [int]($pw * $img.Height / $img.Width)
$px = 84
$py = [int](($H - 14 - $ph) / 2)
$r = 22
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddArc($px, $py, $r*2, $r*2, 180, 90)
$path.AddArc($px+$pw-$r*2, $py, $r*2, $r*2, 270, 90)
$path.AddArc($px+$pw-$r*2, $py+$ph-$r*2, $r*2, $r*2, 0, 90)
$path.AddArc($px, $py+$ph-$r*2, $r*2, $r*2, 90, 90)
$path.CloseFigure()
$g.SetClip($path)
$g.DrawImage($img, (New-Object System.Drawing.Rectangle($px, $py, $pw, $ph)))
$g.ResetClip()
$g.DrawPath((New-Object System.Drawing.Pen($border, 2)), $path)
$img.Dispose()

# Georgia stands in for Source Serif 4: System.Drawing cannot read woff2, and Georgia
# is the same fallback the site's heading stack uses.
$tx = 588
$fName = New-Object System.Drawing.Font("Georgia", 54, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$fRole = New-Object System.Drawing.Font("Segoe UI Semibold", 26, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$fBody = New-Object System.Drawing.Font("Segoe UI", 23, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$fTag  = New-Object System.Drawing.Font("Segoe UI Semibold", 20, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)

$g.DrawString($name, $fName, (New-Object System.Drawing.SolidBrush($teal900)), $tx, 158)
$g.DrawString($role, $fRole, (New-Object System.Drawing.SolidBrush($teal700)), $tx, 236)

# Wrap the lede to the space actually available, rather than trusting hand-counted
# character limits. Greedy word wrap against MeasureString.
$avail = $W - $tx - 84
$words = (($lede -join " ") -split '\s+') | Where-Object { $_ }
$lines = @(); $cur = ""
# NOTE: do not name this loop variable $w. PowerShell variables are case-insensitive,
# so $w and $W are the same variable, and using $w here silently overwrites the canvas
# width with the last word of the lede.
foreach ($word in $words) {
  $try = if ($cur) { "$cur $word" } else { $word }
  if ($g.MeasureString($try, $fBody).Width -le $avail) {
    $cur = $try
  } else {
    if ($cur) { $lines += $cur }
    $cur = $word
  }
}
if ($cur) { $lines += $cur }

# The hairline and the tag row follow the lede rather than sitting at fixed heights, so
# a longer statement pushes them down instead of colliding with them.
$y = 292
foreach ($line in $lines) {
  $g.DrawString($line, $fBody, (New-Object System.Drawing.SolidBrush($gray)), $tx, $y)
  $y += 32
}

$ruleY = $y + 18
$tagY  = $ruleY + 20
$g.DrawLine((New-Object System.Drawing.Pen($border, 2)), $tx, $ruleY, $W - 84, $ruleY)
$g.DrawString(($tags -join $sep), $fTag, (New-Object System.Drawing.SolidBrush($teal500)), $tx, $tagY)
$g.Dispose()

# Only complain when the text would actually reach the brand bar at the bottom.
if (($tagY + 26) -gt ($H - 14)) {
  Write-Warning ("Lede wraps to {0} lines, which pushes the tag row past the bottom bar. Shorten it." -f $lines.Count)
}

# JPEG, not PNG: this is a photograph, and PNG came out nearly six times larger.
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$qp = New-Object System.Drawing.Imaging.EncoderParameters 1
$qp.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 86)

# Write to temp then move: saving straight over an existing file from inside a script
# throws a generic GDI+ error in this environment.
$tmp = [System.IO.Path]::Combine($env:TEMP, "og-card-build.jpg")
$bmp.Save($tmp, $jpeg, $qp)
$bmp.Dispose()
Move-Item -LiteralPath $tmp -Destination $out -Force

"wrote images/og-card.jpg ({0} KB)" -f [int]((Get-Item $out).Length / 1KB)
"Re-share the URL afterwards: platforms cache preview images aggressively."
"LinkedIn cache refresh: https://www.linkedin.com/post-inspector/"
