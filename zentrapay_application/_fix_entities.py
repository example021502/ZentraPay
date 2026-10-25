"""Align the working-tree JPA entities with the authoritative schema.

Two sources of truth are combined:
  * build/live_schema.sql  — the replayed, verified schema (authoritative)
  * git HEAD's entity layer — the entity/column mapping that matched it

The working-tree entity layer was rewritten to map every primary key as a
generic `id` column and, in a few places, to camelCase column names that
no longer exist. That broke every `getWalletId()`-style call site in the
service layer (58 javac errors).

For each entity this script:
  1. finds the @Id field and replaces it with the HEAD-era field/column
     pair, but only when that column really exists in live_schema.sql;
  2. fixes any other @Column(name=...) that points at a non-existent
     column when the snake_case form of the field name does exist;
  3. reports anything it cannot resolve for manual handling.

Usage: python _align_entities.py [--apply]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BE = os.path.join(ROOT, "zentrapay_spring_boot_layer")
SCHEMA = os.path.join(BE, "build", "live_schema.sql")
ENTITY_DIR = os.path.join(BE, "src", "main", "java", "com", "zentrapay", "backend", "entity")
OLD_DIR = "zentrapay_spring_boot_layer/src/main/java/com/zentrapay_application/zentrapay_spring_boot_layer/domain/model"

CREATE_RE = re.compile(r"CREATE TABLE (?:public\.)?(\w+)\s*\((.*?)\n\);", re.S | re.I)
COL_RE = re.compile(
    r"^\s*\"?(\w+)\"?\s+(character varying|bigint|integer|smallint|boolean|timestamp|date|text|numeric|uuid|jsonb|double precision|real|bigserial|serial)\b",
    re.I | re.M)


def snake(name):
    s1 = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", name)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s1).lower()


def load_schema():
    tables = {}
    with open(SCHEMA, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    for m in CREATE_RE.finditer(text):
        cols = []
        for line in m.group(2).splitlines():
            line = line.strip()
            if not line or line.startswith("--"):
                continue
            cm = COL_RE.match(line)
            if cm:
                cols.append(cm.group(1))
        tables[m.group(1)] = cols
    return tables


def head_entities():
    """table -> {pk_col, pk_field} as recorded in git HEAD."""
    names = subprocess.run(
        ["git", "-C", ROOT, "ls-tree", "-r", "--name-only", "HEAD", OLD_DIR],
        capture_output=True, text=True, encoding="utf-8").stdout.split()
    out = {}
    for n in names:
        if not n.endswith(".java"):
            continue
        p = subprocess.run(["git", "-C", ROOT, "show", f"HEAD:{n}"],
                           capture_output=True, text=True, encoding="utf-8", errors="replace")
        if p.returncode != 0:
            continue
        src = p.stdout
        tm = re.search(r'@Table\(\s*name\s*=\s*"(\w+)"', src, re.S)
        if not tm:
            continue
        idm = re.search(r"@Id\b.*?@Column\(name\s*=\s*\"(\w+)\".*?private\s+([\w.<>, ]+?)\s+(\w+)\s*;",
                        src, re.S)
        if idm:
            out[tm.group(1)] = {"pk_col": idm.group(1), "pk_field": idm.group(3)}
    return out


TABLE_RE = re.compile(r'@Table\(\s*name\s*=\s*"(\w+)"', re.S)
ID_BLOCK_RE = re.compile(
    r"(@Id\b\s*(?:@[\w.]+(?:\([^)]*\))?\s*)*@Column\(([^)]*)\)\s*private\s+([\w.<>, ]+?)\s+(\w+)\s*(?:=[^;]*)?;)",
    re.S)
COL_BLOCK_RE = re.compile(
    r"(@Column\(([^)]*)\)\s*private\s+([\w.<>, ]+?)\s+(\w+)\s*(?:=[^;]*)?;)",
    re.S)


def main():
    apply = "--apply" in sys.argv
    tables = load_schema()
    head = head_entities()
    changed, unresolved = 0, []

    for fn in sorted(os.listdir(ENTITY_DIR)):
        if not fn.endswith(".java"):
            continue
        path = os.path.join(ENTITY_DIR, fn)
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
        tm = TABLE_RE.search(src)
        if not tm:
            continue
        table = tm.group(1)
        if table not in tables:
            unresolved.append(f"{fn}: table '{table}' absent from live schema")
            continue
        live = tables[table]
        new, notes = src, []

        # ---- 1. primary key ------------------------------------------------
        im = ID_BLOCK_RE.search(src)
        if im:
            block, ann, jtype, field = im.group(1), im.group(2), im.group(3), im.group(4)
            nm = re.search(r'name\s*=\s*"(\w+)"', ann)
            mapped = nm.group(1) if nm else None
            target = head.get(table)
            want_col = target["pk_col"] if target else None
            want_field = target["pk_field"] if target else None
            if want_col and want_col not in live:
                cands = [c for c in live if c.endswith("_id")]
                want_col = cands[0] if cands else None
                want_field = None
            if want_col and mapped != want_col and want_col in live:
                new_ann = ann
                if nm:
                    new_ann = ann.replace(f'name = "{mapped}"', f'name = "{want_col}"')
                else:
                    new_ann = f'name = "{want_col}", ' + ann
                new_block = (f"@Id\n    @Column({new_ann})\n    private {jtype} {want_field or field};")
                new = new.replace(block, new_block)
                notes.append(f"PK {mapped} -> {want_col} (field {field} -> {want_field or field})")

        # ---- 2. other columns whose @Column(name) is stale ------------------
        for cm in list(COL_BLOCK_RE.finditer(new)):
            ann, field = cm.group(2), cm.group(4)
            nm = re.search(r'name\s*=\s*"(\w+)"', ann)
            if not nm:
                continue
            mapped = nm.group(1)
            if mapped in live:
                continue
            cand = snake(field)
            if cand in live:
                new = new.replace(f'name = "{mapped}"', f'name = "{cand}"')
                notes.append(f"{field}: {mapped} -> {cand}")

        if new != src:
            changed += 1
            print(f"{fn} ({table}):")
            for n in notes:
                print(f"    {n}")
            if apply:
                with open(path, "w", encoding="utf-8") as fh:
                    fh.write(new)

    print(f"\n{changed} entity file(s) {'updated' if apply else 'would change'}")
    if unresolved:
        print("\nNeeds manual review:")
        for u in unresolved:
            print(f"    {u}")


if __name__ == "__main__":
    main()

