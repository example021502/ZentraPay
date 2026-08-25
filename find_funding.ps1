Get-ChildItem -Recurse -File "c:\Zentrapay_Workspace\zentrapay_spring_boot_layer\src\main\java\com\zentrapay_application\zentrapay_spring_boot_layer" -Include *.java |
  Where-Object { $_.Name -match 'Funding|Bank|Channel|Link' } |
  Select-Object -ExpandProperty FullName |
  Out-File -Encoding utf8 c:\Zentrapay_Workspace\funding_files.txt