import os
from pathlib import Path

base_path = Path("zentrapay_application/lib")

def remove_empty_folders(path):
    """Recursively remove empty folders"""
    removed = []
    
    for root, dirs, files in os.walk(path, topdown=False):
        for dir_name in dirs:
            dir_path = Path(root) / dir_name
            try:
                # Check if directory is empty
                if dir_path.exists() and not any(dir_path.iterdir()):
                    dir_path.rmdir()
                    removed.append(str(dir_path.relative_to(base_path)))
            except Exception as e:
                pass
    
    return removed

print("Removing empty folders...")
removed = remove_empty_folders(base_path)

if removed:
    print(f"Removed {len(removed)} empty folders:")
    for folder in removed:
        print(f"  - {folder}")
else:
    print("No empty folders found to remove")