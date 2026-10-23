"""Compare JPA entity mappings against the live schema.

Reads build/live_schema.sql for the authoritative table/column set, then
parses every entity in src/main/java/com/zentrapay/backend/entity/*.java and
reports:
  * columns the entity maps that do not exist in the table
  * NOT NULL table columns the entity does not map at all

The entity side resolves:
  * explicit @Column(name = "...")
  * @JoinColumn(name = "...") on @ManyToOne / @OneToOne relations
  * implicit names, using the Spring physical naming strategy
    (camelCase -> snake_case), which is what Hibernate actually generates
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
BE = os.path.join(os.path.dirname(ROOT), "zentrapay_spring_boot_layer")
SCHEMA = os.path.join(BE, "build", "live_schema.sql")
ENTITY_DIR = os.path.join(BE, "src", "main", "java", "com", "zentrapay", "backend", "entity")

CREATE_RE = re.compile(r"CREATE TABLE (?:public\.)?(\w+)\s*\((.*?)\n\);", re.S | re.I)
COL_RE = re.compile(r"^\s*\"?(\w+)\"?\s+(character varying|bigint|integer|smallint|boolean|timestamp|date|text|numeric|uuid|jsonb|double precision|real|bigserial|serial)(.*)$",
                    re.I | re.M)


def load_schema():
    tables = {}
    with open(SCHEMA, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    for m in CREATE_RE.finditer(text):
        name = m.group(1)
        cols = {}
        for line in m.group(2).splitlines():
            line = line.strip()
            if not line or line.startswith("--"):
                continue
            cm = COL_RE.match(line)
            if not cm:
                continue
            col = cm.group(1)
            notnull = "NOT NULL" in line.upper()
            cols[col] = notnull
        tables[name] = cols
    return tables


ENTITY_RE = re.compile(r"@Table\(\s*name\s*=\s*\"(\w+)\"", re.S)
COLUMN_RE = re.compile(r"@Column\(([^)]*)\)", re.S)
JOIN_RE = re.compile(r"@JoinColumn\(([^)]*)\)", re.S)
NAME_RE = re.compile(r"name\s*=\s*\"(\w+)\"")

# A field declaration (possibly preceded by annotations) up to its ';'
FIELD_RE = re.compile(r"(?P<annos>(?:@[A-Za-z]+(?:\([^()]*(?:\([^()]*\)[^()]*)*\))?\s*)*)"
                       r"(?:public|private|protected)\s+[\w<>,\s\.\[\]]+?\s+(?P<name>\w+)\s*(?:=[^;]*)?;",
                       re.S)


def snake(name):
    """camelCase -> snake_case, matching Spring's physical naming strategy."""
    s = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", name)
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)
    return s.lower()


def parse_entities():
    out = []
    for fn in sorted(os.listdir(ENTITY_DIR)):
        if not fn.endswith(".java"):
            continue
        with open(os.path.join(ENTITY_DIR, fn), encoding="utf-8", errors="replace") as fh:
            src = fh.read()
        tm = ENTITY_RE.search(src)
        if not tm:
            continue
        table = tm.group(1)

        mapped = set()
        for cm in COLUMN_RE.finditer(src):
            nm = NAME_RE.search(cm.group(1))
            if nm:
                mapped.add(nm.group(1))
        for jm in JOIN_RE.finditer(src):
            nm = NAME_RE.search(jm.group(1))
            if nm:
                mapped.add(nm.group(1))

        # Resolve implicit names for fields that carry no explicit @Column name.
        for fm in FIELD_RE.finditer(src):
            field = fm.group("name")
            annos = fm.group("annos") or ""
            if "@Transient" in annos or "static" in annos:
                continue
            # skip fields that already have an explicit @Column(name=..)
            explicit = False
            for cm in COLUMN_RE.finditer(annos):
                nm = NAME_RE.search(cm.group(1))
                if nm:
                    explicit = True
                    break
            if explicit:
                continue
            # @JoinColumn handled above; relations use the join column name
            if "@ManyToOne" in annos or "@OneToOne" in annos or "@ManyToMany" in annos:
                continue
            if "@OneToMany" in annos or "@ElementCollection" in annos or "@Embedded" in annos:
                continue
            if "@Id" in annos or "@Version" in annos or "@Enumerated" in annos or "@Lob" in annos:
                mapped.add(snake(field))
                continue
            mapped.add(snake(field))

        out.append((fn, table, sorted(mapped)))
    return out


def main():
    tables = load_schema()
    entities = parse_entities()
    problems = 0
    for fn, table, mapped in entities:
        if table not in tables:
            print(f"?? {fn}: table '{table}' NOT FOUND in live schema")
            problems += 1
            continue
        live = tables[table]
        missing = [c for c in mapped if c not in live]
        unmapped_notnull = [c for c, nn in live.items() if nn and c not in mapped]
        if missing or unmapped_notnull:
            print(f"--- {fn} -> {table}")
            if missing:
                print(f"    entity maps columns absent from table: {missing}")
            if unmapped_notnull:
                print(f"    table NOT NULL columns entity does not map: {unmapped_notnull}")
            problems += 1
    print(f"\n{problems} entity/table pair(s) with mismatches out of {len(entities)}")


if __name__ == "__main__":
    main()
