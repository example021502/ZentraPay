Select-String -Path (Get-ChildItem -Recurse -File "c:\Zentrapay_Workspace\zentrapay_application\lib" -Include *.dart) -Pattern 'SearchRepository','senderDetails','fiatAccounts','\.zentag' |
  Select-Object Path, LineNumber, Line |
  Format-Table -AutoSize -Wrap |
  Out-String -Width 250 |
  Out-File -Encoding utf8 c:\Zentrapay_Workspace\search_usage.txt