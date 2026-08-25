@echo off
git -C c:\Zentrapay_Workspace\zentrapay_spring_boot_layer show ec73ddf --stat > c:\Zentrapay_Workspace\git_show_ec73.txt 2>&1
git -C c:\Zentrapay_Workspace\zentrapay_spring_boot_layer show ec73ddf -- src/main/java/com/zentrapay_application/zentrapay_spring_boot_layer/modules/searchContacts > c:\Zentrapay_Workspace\git_show_search.txt 2>&1
git -C c:\Zentrapay_Workspace\zentrapay_application show 690aae1 --stat > c:\Zentrapay_Workspace\git_show_690.txt 2>&1
git -C c:\Zentrapay_Workspace\zentrapay_application show 690aae1 -- lib/core/models/search_result.dart lib/core/repositories/search_repository.dart > c:\Zentrapay_Workspace\git_show_front.txt 2>&1