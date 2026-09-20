# Generates the native launcher and iOS launch images from the same simple mark.
# Run from PowerShell on Windows: ./tool/generate_brand_assets.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$background = [System.Drawing.Color]::FromArgb(11, 16, 32)
$blueLight = [System.Drawing.Color]::FromArgb(118, 190, 255)
$blueDark = [System.Drawing.Color]::FromArgb(35, 91, 216)

function Draw-GeeMark {
    param(
        [System.Drawing.Graphics] $Graphics,
        [single] $X,
        [single] $Y,
        [single] $Side
    )

    $radius = $Side * 0.27
    $diameter = $radius * 2
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Side - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Side - $diameter, $Y + $Side - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Side - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()

    $bounds = [System.Drawing.RectangleF]::new($X, $Y, $Side, $Side)
    $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        $bounds, $blueLight, $blueDark, 45.0
    )
    $white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    try {
        $Graphics.FillPath($gradient, $path)
        $triangle = [System.Drawing.PointF[]] @(
            [System.Drawing.PointF]::new($X + $Side * 0.29, $Y + $Side * 0.21),
            [System.Drawing.PointF]::new($X + $Side * 0.29, $Y + $Side * 0.79),
            [System.Drawing.PointF]::new($X + $Side * 0.76, $Y + $Side * 0.50)
        )
        $Graphics.FillPolygon($white, $triangle)
    }
    finally {
        $white.Dispose()
        $gradient.Dispose()
        $path.Dispose()
    }
}

function Save-GeeImage {
    param(
        [string] $Path,
        [int] $Width,
        [int] $Height,
        [bool] $Transparent,
        [single] $MarkSide
    )

    $pixelFormat = if ($Transparent) {
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    }
    else {
        [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    }
    $bitmap = [System.Drawing.Bitmap]::new($Width, $Height, $pixelFormat)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.Clear($(if ($Transparent) { [System.Drawing.Color]::Transparent } else { $background }))
        $x = [single] (($Width - $MarkSide) / 2)
        $y = [single] (($Height - $MarkSide) / 2)
        Draw-GeeMark -Graphics $graphics -X $x -Y $y -Side $MarkSide
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$androidRes = Join-Path $projectRoot 'android/app/src/main/res'
$androidSizes = [ordered] @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}
foreach ($density in $androidSizes.Keys) {
    $pixels = $androidSizes[$density]
    $destination = Join-Path (Join-Path $androidRes $density) 'ic_launcher.png'
    Save-GeeImage -Path $destination -Width $pixels -Height $pixels -Transparent $false -MarkSide ([single] ($pixels * 0.76))
}

$iosIconRoot = Join-Path $projectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$iconManifest = Get-Content -LiteralPath (Join-Path $iosIconRoot 'Contents.json') -Raw | ConvertFrom-Json
foreach ($image in $iconManifest.images) {
    $pointSize = [double]::Parse($image.size.Split('x')[0], [Globalization.CultureInfo]::InvariantCulture)
    $scale = [int] $image.scale.Substring(0, 1)
    $pixels = [int] [Math]::Round($pointSize * $scale)
    $destination = Join-Path $iosIconRoot $image.filename
    Save-GeeImage -Path $destination -Width $pixels -Height $pixels -Transparent $false -MarkSide ([single] ($pixels * 0.76))
}

$iosLaunchRoot = Join-Path $projectRoot 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
for ($scale = 1; $scale -le 3; $scale++) {
    $filename = if ($scale -eq 1) { 'LaunchImage.png' } else { "LaunchImage@${scale}x.png" }
    $destination = Join-Path $iosLaunchRoot $filename
    Save-GeeImage -Path $destination -Width (168 * $scale) -Height (185 * $scale) -Transparent $true -MarkSide ([single] (112 * $scale))
}

Write-Output 'Generated Android and iOS Gee Player icons and iOS launch images.'
