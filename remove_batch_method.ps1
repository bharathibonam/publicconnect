$lines = [System.IO.File]::ReadAllLines('c:\FlutterGov\flutter_demo_app\lib\screens\super_admin\admin_management.dart')
# Lines are 0-indexed, method is at lines 587-754 (1-indexed) = 586-753 (0-indexed)
# Find start and end by searching for the method signatures
$startIdx = -1
$endIdx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'void _showBatchFixRolesDialog' -and $startIdx -eq -1) {
        $startIdx = $i
    }
    if ($lines[$i] -match 'void _showEditRoleDialog' -and $startIdx -ge 0 -and $endIdx -eq -1) {
        $endIdx = $i
        break
    }
}
Write-Host "Batch method: lines $($startIdx+1) to $($endIdx) (1-indexed)"
if ($startIdx -ge 0 -and $endIdx -gt $startIdx) {
    $before = $lines[0..($startIdx - 2)]  # skip the blank line before
    $after = $lines[$endIdx..($lines.Count - 1)]
    $newLines = $before + $after
    [System.IO.File]::WriteAllLines('c:\FlutterGov\flutter_demo_app\lib\screens\super_admin\admin_management.dart', $newLines)
    Write-Host 'SUCCESS'
}
