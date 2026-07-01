
$bytes = [System.IO.File]::ReadAllBytes('c:\FlutterGov\flutter_demo_app\lib\screens\super_admin\admin_management.dart')
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

$pattern = '(?s)([ ]+)Container\(\r\n\s+padding: const EdgeInsets\.symmetric\(horizontal: 10, vertical: 4\),\r\n\s+decoration: BoxDecoration\(color: Colors\.teal\.shade50, borderRadius: BorderRadius\.circular\(12\)\),\r\n\s+child: Text\(\r\n\s+isTelugu \? .+? : .Active.,\r\n\s+style: TextStyle\(fontSize: 10, fontWeight: FontWeight\.bold, color: Colors\.teal\.shade700\),\r\n\s+\),\r\n\s+\),\r\n(\s+\],\r\n\s+\),\r\n\s+\),\r\n\s+\);\r\n\s+\},\r\n\s+\),)'

$replacement = '                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCategory || isMandal)
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).primaryColor),
                                    tooltip: ''Edit Role'',
                                    onPressed: () => _showEditRoleDialog(context, o, isTelugu, appState),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                  tooltip: ''Delete'',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text(''Confirm Delete''),
                                        content: Text(''Delete '' + o.name + ''?''),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(''Cancel'')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text(''Delete'', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      await appState.deleteUser(o.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),'

$newContent = [regex]::Replace($content, $pattern, $replacement)
if ($newContent -eq $content) { 
  Write-Host 'NO MATCH - pattern not found'
} else {
  [System.IO.File]::WriteAllBytes('c:\FlutterGov\flutter_demo_app\lib\screens\super_admin\admin_management.dart', [System.Text.Encoding]::UTF8.GetBytes($newContent))
  Write-Host 'SUCCESS'
}
