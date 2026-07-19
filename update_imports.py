import os
import re
from pathlib import Path

base_path = Path("zentrapay_application/lib")

# Define import replacements
import_replacements = {
    # Core utilities
    r"import 'package:zentrapay_application/interceptor.dart'": "import 'package:zentrapay_application/core/utils/interceptor.dart'",
    r"import 'package:zentrapay_application/storage_service.dart'": "import 'package:zentrapay_application/core/utils/storage_service.dart'",
    r"import 'package:zentrapay_application/Notifier.dart'": "import 'package:zentrapay_application/core/utils/Notifier.dart'",
    
    # Services
    r"import 'package:zentrapay_application/api_dashboard_services.dart'": "import 'package:zentrapay_application/services/api_service.dart'",
    r"import 'package:zentrapay_application/services/api_dashboard_services.dart'": "import 'package:zentrapay_application/services/api_service.dart'",
    
    # Auth feature - remove nested paths
    r"import 'package:zentrapay_application/features/auth/auth/": "import 'package:zentrapay_application/features/auth/",
    r"import 'package:zentrapay_application/features/auth/login/": "import 'package:zentrapay_application/features/auth/",
    r"import 'package:zentrapay_application/features/auth/onboarding/": "import 'package:zentrapay_application/features/auth/",
    r"import 'package:zentrapay_application/features/auth/widgets/": "import 'package:zentrapay_application/features/auth/",
    
    # Home feature - remove nested paths
    r"import 'package:zentrapay_application/features/home/home_wallet/": "import 'package:zentrapay_application/features/home/",
    r"import 'package:zentrapay_application/features/home/HomePayActionHelpers/": "import 'package:zentrapay_application/features/home/",
    r"import 'package:zentrapay_application/features/home/widgets/": "import 'package:zentrapay_application/features/home/",
    
    # Profile feature - remove nested paths
    r"import 'package:zentrapay_application/features/profile/profile/": "import 'package:zentrapay_application/features/profile/",
    r"import 'package:zentrapay_application/features/profile/settings/": "import 'package:zentrapay_application/features/profile/",
    
    # Payments feature - remove nested paths
    r"import 'package:zentrapay_application/features/payments/ai_assistance/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/converter/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/fraud_detection/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/liquidity_hub/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/milestones/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/voice_recording/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/zgrow/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/zgrow/widgets/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/zgrow/zinvest/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/zremit/": "import 'package:zentrapay_application/features/payments/",
    r"import 'package:zentrapay_application/features/payments/zremit/widgets/": "import 'package:zentrapay_application/features/payments/",
    
    # Wallet feature - remove nested paths
    r"import 'package:zentrapay_application/features/wallet/zbanking/": "import 'package:zentrapay_application/features/wallet/",
}

# Walk through all dart files
dart_files = list(base_path.rglob("*.dart"))
print(f"Found {len(dart_files)} Dart files to update\n")

updated_count = 0
for dart_file in dart_files:
    try:
        content = dart_file.read_text(encoding='utf-8')
        original_content = content
        
        # Apply all replacements
        for pattern, replacement in import_replacements.items():
            content = re.sub(pattern, replacement, content)
        
        # Only write if content changed
        if content != original_content:
            dart_file.write_text(content, encoding='utf-8')
            print(f"Updated: {dart_file.relative_to(base_path)}")
            updated_count += 1
    except Exception as e:
        print(f"Error updating {dart_file}: {e}")

print(f"\n✓ Updated {updated_count} files with new import paths")