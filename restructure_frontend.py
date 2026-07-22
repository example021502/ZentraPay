import os
import shutil
from pathlib import Path

# Define the base path
base_path = Path("zentrapay_application/lib")

# Step 1: Move core files to core/utils
print("Moving core files to core/utils...")
core_files = {
    "interceptor.dart": "core/utils/interceptor.dart",
    "storage_service.dart": "core/utils/storage_service.dart",
    "Notifier.dart": "core/utils/Notifier.dart",
}

for src, dst in core_files.items():
    src_path = base_path / src
    dst_path = base_path / dst
    if src_path.exists():
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src_path), str(dst_path))
        print(f"  Moved {src} -> {dst}")

# Step 2: Move api_dashboard_services.dart to services
print("\nMoving service files...")
api_src = base_path / "api_dashboard_services.dart"
api_dst = base_path / "services" / "api_service.dart"
if api_src.exists():
    api_dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(api_src), str(api_dst))
    print(f"  Moved api_dashboard_services.dart -> services/api_service.dart")

# Step 3: Flatten nested folders in features/auth
print("\nFlattening features/auth...")
auth_base = base_path / "features" / "auth"
for subfolder in ["auth", "login", "onboarding", "widgets"]:
    subfolder_path = auth_base / subfolder
    if subfolder_path.exists() and subfolder_path.is_dir():
        try:
            for item in subfolder_path.iterdir():
                dest = auth_base / item.name
                if not dest.exists():
                    shutil.move(str(item), str(dest))
                    print(f"  Moved {subfolder}/{item.name} -> auth/{item.name}")
            # Remove empty subfolder
            try:
                subfolder_path.rmdir()
                print(f"  Removed empty folder: {subfolder}")
            except:
                pass
        except PermissionError:
            print(f"  Skipping {subfolder} (permission denied)")

# Step 4: Flatten nested folders in features/home
print("\nFlattening features/home...")
home_base = base_path / "features" / "home"
for subfolder in ["home_wallet", "HomePayActionHelpers", "widgets"]:
    subfolder_path = home_base / subfolder
    if subfolder_path.exists() and subfolder_path.is_dir():
        try:
            for item in subfolder_path.iterdir():
                dest = home_base / item.name
                if not dest.exists():
                    shutil.move(str(item), str(dest))
                    print(f"  Moved {subfolder}/{item.name} -> home/{item.name}")
            # Remove empty subfolder
            try:
                subfolder_path.rmdir()
                print(f"  Removed empty folder: {subfolder}")
            except:
                pass
        except PermissionError:
            print(f"  Skipping {subfolder} (permission denied)")

# Step 5: Flatten nested folders in features/profile
print("\nFlattening features/profile...")
profile_base = base_path / "features" / "profile"
for subfolder in ["profile", "settings"]:
    subfolder_path = profile_base / subfolder
    if subfolder_path.exists() and subfolder_path.is_dir():
        try:
            for item in subfolder_path.iterdir():
                dest = profile_base / item.name
                if not dest.exists():
                    shutil.move(str(item), str(dest))
                    print(f"  Moved {subfolder}/{item.name} -> profile/{item.name}")
            # Remove empty subfolder
            try:
                subfolder_path.rmdir()
                print(f"  Removed empty folder: {subfolder}")
            except:
                pass
        except PermissionError:
            print(f"  Skipping {subfolder} (permission denied)")

# Step 6: Flatten nested folders in features/payments
print("\nFlattening features/payments...")
payments_base = base_path / "features" / "payments"
payment_subfolders = [
    "ai_assistance", "converter", "fraud_detection", "liquidity_hub",
    "milestones", "voice_recording", "zgrow", "zremit"
]
for subfolder in payment_subfolders:
    subfolder_path = payments_base / subfolder
    if subfolder_path.exists() and subfolder_path.is_dir():
        try:
            for item in subfolder_path.iterdir():
                if item.is_file():
                    dest = payments_base / item.name
                    if not dest.exists():
                        shutil.move(str(item), str(dest))
                        print(f"  Moved {subfolder}/{item.name} -> payments/{item.name}")
            # Move any sub-subfolders (like widgets) contents up
            for subsub in subfolder_path.iterdir():
                if subsub.is_dir():
                    for item in subsub.iterdir():
                        dest = payments_base / item.name
                        if not dest.exists():
                            shutil.move(str(item), str(dest))
                            print(f"  Moved {subfolder}/{subsub.name}/{item.name} -> payments/{item.name}")
            # Remove empty subfolder
            try:
                subfolder_path.rmdir()
                print(f"  Removed empty folder: {subfolder}")
            except:
                pass
        except PermissionError:
            print(f"  Skipping {subfolder} (permission denied)")

# Step 7: Flatten nested folders in features/wallet
print("\nFlattening features/wallet...")
wallet_base = base_path / "features" / "wallet"
for subfolder in ["zbanking"]:
    subfolder_path = wallet_base / subfolder
    if subfolder_path.exists() and subfolder_path.is_dir():
        try:
            for item in subfolder_path.iterdir():
                dest = wallet_base / item.name
                if not dest.exists():
                    shutil.move(str(item), str(dest))
                    print(f"  Moved {subfolder}/{item.name} -> wallet/{item.name}")
            # Remove empty subfolder
            try:
                subfolder_path.rmdir()
                print(f"  Removed empty folder: {subfolder}")
            except:
                pass
        except PermissionError:
            print(f"  Skipping {subfolder} (permission denied)")

print("\n✓ Folder restructuring complete!")
print("\nNew structure:")
for root, dirs, files in os.walk(base_path):
    level = root.replace(str(base_path), '').count(os.sep)
    indent = ' ' * 2 * level
    print(f'{indent}{os.path.basename(root)}/')
    subindent = ' ' * 2 * (level + 1)
    for file in files[:5]:  # Show first 5 files per folder
        print(f'{subindent}{file}')
    if len(files) > 5:
        print(f'{subindent}... ({len(files)} files total)')