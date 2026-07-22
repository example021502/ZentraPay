import re
from pathlib import Path

base_path = Path("zentrapay_application/lib")

# Comprehensive fix for ALL remaining import issues
remaining_fixes = [
    # Fix any remaining old import paths
    (r"import 'package:zentrapay_application/home_wallet/", 
     "import 'package:zentrapay_application/features/home/"),
    (r"import 'package:zentrapay_application/navigation_bar/",
     "import 'package:zentrapay_application/core/theme/navigation_bar/"),
    (r"import 'package:zentrapay_application/zbanking/",
     "import 'package:zentrapay_application/features/wallet/"),
    (r"import 'package:zentrapay_application/zgrow/",
     "import 'package:zentrapay_application/features/payments/"),
    (r"import 'package:zentrapay_application/zremit/",
     "import 'package:zentrapay_application/features/payments/"),
    (r"import 'package:zentrapay_application/liquidity_hub/",
     "import 'package:zentrapay_application/features/payments/"),
    (r"import 'package:zentrapay_application/milestones/",
     "import 'package:zentrapay_application/features/payments/"),
    (r"import 'package:zentrapay_application/converter/",
     "import 'package:zentrapay_application/features/payments/"),
    (r"import 'package:zentrapay_application/fraud_detection/",
     "import 'package:zentrapay_application/features/payments/"),
    (r"import 'package:zentrapay_application/voice_recording/",
     "import 'package:zentrapay_application/features/payments/"),
    (r"import 'package:zentrapay_application/ai_assistance/",
     "import 'package:zentrapay_application/features/payments/"),
    (r"import 'package:zentrapay_application/settings/",
     "import 'package:zentrapay_application/features/profile/"),
    (r"import 'package:zentrapay_application/Common/",
     "import 'package:zentrapay_application/core/utils/Common/"),
    (r"import 'package:zentrapay_application/onboarding/",
     "import 'package:zentrapay_application/features/auth/"),
    
    # Fix relative imports
    (r"import '\.\./interceptor\.dart';",
     "import 'package:zentrapay_application/core/utils/interceptor.dart';"),
    (r"import '\.\./api_home_wallet_services\.dart';",
     "import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';"),
    (r"import '\.\./home_wallet/",
     "import 'package:zentrapay_application/features/home/"),
    (r"import 'widgets/",
     "import '"),
]

dart_files = list(base_path.rglob("*.dart"))
print(f"Scanning {len(dart_files)} files for remaining import issues...\n")

fixed_count = 0
for dart_file in dart_files:
    try:
        content = dart_file.read_text(encoding='utf-8')
        original = content
        
        for pattern, replacement in remaining_fixes:
            content = re.sub(pattern, replacement, content)
        
        if content != original:
            dart_file.write_text(content, encoding='utf-8')
            print(f"Fixed: {dart_file.relative_to(base_path)}")
            fixed_count += 1
    except Exception as e:
        print(f"Error: {dart_file}: {e}")

print(f"\n✓ Fixed {fixed_count} files")