$content = [System.IO.File]::ReadAllText('c:\FlutterGov\flutter_demo_app\lib\screens\super_admin\admin_management.dart')
$startMarker = '          // -- Batch Fix Roles Banner'
$endMarker = '          // Register Form Card'

# Use regex to remove from the banner comment to just before Register Form Card
$pattern = '(?s)\s+// [^\n]*Batch Fix Roles Banner.*?(          // Register Form Card)'
$replacement = "`r`n          // Register Form Card"
$newContent = [regex]::Replace($content, $pattern, $replacement)

if ($newContent -eq $content) {
  Write-Host 'Pattern not matched, trying indexOf approach'
  # Try finding by line
  $lines = $content -split "`r`n"
  $startLine = -1
  $endLine = -1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'Batch Fix Roles Banner' -and $startLine -eq -1) {
      $startLine = $i
    }
    if ($lines[$i] -match 'Register Form Card' -and $startLine -ge 0 -and $endLine -eq -1) {
      $endLine = $i
      break
    }
  }
  Write-Host "startLine=$startLine endLine=$endLine"
  if ($startLine -ge 0 -and $endLine -gt $startLine) {
    $before = $lines[0..($startLine - 1)]
    $after = $lines[$endLine..($lines.Count - 1)]
    $newContent = ($before + $after) -join "`r`n"
    [System.IO.File]::WriteAllText('c:\FlutterGov\flutter_demo_app\lib\screens\super_admin\admin_management.dart', $newContent)
    Write-Host 'SUCCESS via line removal'
  }
} else {
  [System.IO.File]::WriteAllText('c:\FlutterGov\flutter_demo_app\lib\screens\super_admin\admin_management.dart', $newContent)
  Write-Host 'SUCCESS via regex'
}
