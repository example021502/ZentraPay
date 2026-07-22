import re
from pathlib import Path

base_path = Path("zentrapay_application/lib")

# Define API endpoint fixes
api_fixes = {
    # Fix getBalance endpoint - backend has /api/getBalances/fiat/all and /api/getBalances/crypto/all
    r"/api/getBalance\?user_id=([^&]+)&currencyCode=([^']+)": r"/api/getBalances/fiat/all?user_id=\1",
    
    # Fix payments endpoint - backend has /api/payments/initiate
    r"'/api/payments'": r"'/api/payments/initiate'",
    r'"/api/payments"': r'"/api/payments/initiate"',
    
    # Fix getAccessCode endpoint - should use queryParameters instead of data for GET request
    r"await dio\.get\(\s*'/api/paystackAccessCode/accessCode',\s*data: form": 
    r"await dio.get('/api/paystackAccessCode/accessCode', queryParameters: form)",
}

dart_files = list(base_path.rglob("*.dart"))
print(f"Scanning {len(dart_files)} Dart files for API endpoint fixes...\n")

updated_count = 0
for dart_file in dart_files:
    try:
        content = dart_file.read_text(encoding='utf-8')
        original_content = content
        
        # Apply all API fixes
        for pattern, replacement in api_fixes.items():
            content = re.sub(pattern, replacement, content)
        
        # Only write if content changed
        if content != original_content:
            dart_file.write_text(content, encoding='utf-8')
            print(f"Fixed API endpoints in: {dart_file.relative_to(base_path)}")
            updated_count += 1
    except Exception as e:
        print(f"Error updating {dart_file}: {e}")

print(f"\n✓ Fixed API endpoints in {updated_count} files")