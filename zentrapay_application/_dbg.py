import io
import os
import re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OLD = "zentrapay_spring_boot_layer/src/main/java/com/zentrapay_application/zentrapay_spring_boot_layer/domain/model/ServiceProviderModel.java"

p = subprocess.run(["git", "-C", ROOT, "show", "HEAD:" + OLD],
                   capture_output=True, text=True, encoding="utf-8")
s = p.stdout
print("rc:", p.returncode, "len:", len(s))
m = re.search(r'@Id\b.*?@Column\(name\s*=\s*"(\w+)".*?private\s+([\w.<>, ]+?)\s+(\w+)\s*;', s, re.S)
print("id match:", m.groups() if m else None)
print("has @Table:", re.search(r'@Table\(\s*name\s*=\s*"(\w+)"', s, re.S).group(1)
      if re.search(r'@Table\(\s*name\s*=\s*"(\w+)"', s, re.S) else None)
