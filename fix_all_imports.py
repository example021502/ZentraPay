import re
from pathlib import Path

base_path = Path("zentrapay_application/lib")

# Comprehensive import fixes
import_fixes = [
    # Fix responsive_navigation.dart imports
    (r"import 'package:zentrapay_application/home_wallet/home_wallet_main.dart';", 
     "import 'package:zentrapay_application/features/home/home_wallet_main.dart';"),
    (r"import 'package:zentrapay_application/home_wallet/widgets/closeConfirmation.dart';",
     "import 'package:zentrapay_application/features/home/closeConfirmation.dart';"),
    (r"import 'package:zentrapay_application/navigation_bar/navigation_bar_main.dart';",
     "import 'package:zentrapay_application/core/theme/navigation_bar/navigation_bar_main.dart';"),
    (r"import 'package:zentrapay_application/zbanking/zbanking_screen.dart';",
     "import 'package:zentrapay_application/features/wallet/zbanking_screen.dart';"),
    (r"import 'package:zentrapay_application/zgrow/zgrow_screen.dart';",
     "import 'package:zentrapay_application/features/payments/zgrow_screen.dart';"),
    (r"import '\.\./zremit/zremit_screen.dart';",
     "import 'package:zentrapay_application/features/payments/zremit_screen.dart';"),
    
    # Fix main.dart relative imports
    (r"import 'auth/register_screen.dart';",
     "import 'package:zentrapay_application/features/auth/register_screen.dart';"),
    (r"import 'auth/verify_screen.dart';",
     "import 'package:zentrapay_application/features/auth/verify_screen.dart';"),
    (r"import 'onboarding/onboarding_screen.dart';",
     "import 'package:zentrapay_application/features/auth/onboarding_screen.dart';"),
    
    # Fix external_payment_screen.dart imports
    (r"import '\.\./home_wallet/widgets/getCurrencyISOCodeHelper.dart';",
     "import 'package:zentrapay_application/features/home/getCurrencyISOCodeHelper.dart';"),
    
    # Fix external_payment_service.dart imports
    (r"import '\.\./interceptor.dart';",
     "import 'package:zentrapay_application/core/utils/interceptor.dart';"),
    
    # Fix home_quick_actions.dart imports
    (r"import 'package:zentrapay_application/Common/EnterAmount.dart';",
     "import 'package:zentrapay_application/core/utils/Common/EnterAmount.dart';"),
    (r"import 'package:zentrapay_application/home_wallet/widgets/pay.dart';",
     "import 'package:zentrapay_application/features/home/pay.dart';"),
    (r"import '\.\./api_home_wallet_services.dart';",
     "import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';"),
    
    # Fix home_services_grid.dart imports
    (r"import 'package:zentrapay_application/home_wallet/api_home_wallet_services.dart';",
     "import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';"),
    
    # Fix zgrow_screen.dart imports
    (r"import 'package:zentrapay_application/zgrow/zinvest/zinvest_screen.dart';",
     "import 'package:zentrapay_application/features/payments/zinvest_screen.dart';"),
    (r"import 'package:zentrapay_application/milestones/milestones_screen.dart';",
     "import 'package:zentrapay_application/features/payments/milestones_screen.dart';"),
    (r"import 'package:zentrapay_application/ai_assistance/ai_assistance_screen.dart';",
     "import 'package:zentrapay_application/features/payments/ai_assistance_screen.dart';"),
    (r"import 'widgets/zgrow_header.dart';",
     "import 'zgrow_header.dart';"),
    (r"import 'widgets/saving_challenges.dart';",
     "import 'saving_challenges.dart';"),
    (r"import 'widgets/zgrow_quick_actions.dart';",
     "import 'zgrow_quick_actions.dart';"),
    (r"import 'widgets/zgrow_rewards.dart';",
     "import 'zgrow_rewards.dart';"),
    (r"import 'widgets/learn_and_earn.dart';",
     "import 'learn_and_earn.dart';"),
    (r"import 'widgets/financial_tools.dart';",
     "import 'financial_tools.dart';"),
    (r"import 'widgets/ai_couch.dart';",
     "import 'ai_couch.dart';"),
    
    # Fix zremit_screen.dart imports
    (r"import 'package:zentrapay_application/zremit/widgets/RecentSends.dart';",
     "import 'package:zentrapay_application/features/payments/RecentSends.dart';"),
    (r"import 'widgets/zremit_header.dart';",
     "import 'zremit_header.dart';"),
    
    # Fix instant_transfer_screen.dart imports
    (r"import 'widgets/transfer_user_selection.dart';",
     "import 'transfer_user_selection.dart';"),
    (r"import 'widgets/zremit_header.dart';",
     "import 'zremit_header.dart';"),
]

dart_files = list(base_path.rglob("*.dart"))
print(f"Fixing imports in {len(dart_files)} Dart files...\n")

updated_count = 0
for dart_file in dart_files:
    try:
        content = dart_file.read_text(encoding='utf-8')
        original_content = content
        
        # Apply all replacements
        for pattern, replacement in import_fixes:
            content = re.sub(pattern, replacement, content)
        
        # Only write if content changed
        if content != original_content:
            dart_file.write_text(content, encoding='utf-8')
            print(f"Fixed: {dart_file.relative_to(base_path)}")
            updated_count += 1
    except Exception as e:
        print(f"Error updating {dart_file}: {e}")

print(f"\n✓ Fixed imports in {updated_count} files")