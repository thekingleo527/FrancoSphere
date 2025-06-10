#!/usr/bin/env bash
set -euo pipefail

# ───────────────────────────────────────────────────────────
# 1️⃣  Locate Data/ and Resources/ relative to $SRCROOT
#     ($SRCROOT == $(PROJECT_DIR) when the Run-Script phase runs)
# ───────────────────────────────────────────────────────────
ROOT="$SRCROOT"                 # Xcode always sets this
DATA_DIR="$ROOT/Data"
RESOURCES_DIR="$ROOT/Resources"
OUTPUT_SQL="$RESOURCES_DIR/FrancoSphereSeed.sql"

if [[ ! -d "$DATA_DIR" || ! -d "$RESOURCES_DIR" ]]; then
  echo "❌ ERROR: Expected \$SRCROOT/Data and \$SRCROOT/Resources but one or both are missing." >&2
  echo "   SRCROOT=$SRCROOT" >&2
  exit 1
fi

echo "🔍 Data dir      : $DATA_DIR"
echo "🔍 Resources dir : $RESOURCES_DIR"
echo "🔍 Output SQL    : $OUTPUT_SQL"

# ───────────────────────────────────────────────────────────
# 2️⃣  Build a list of CSV→table pairs that actually exist
# ───────────────────────────────────────────────────────────
CSV_PAIRS=(
  "$DATA_DIR/AllTasks.csv:routine_tasks"
  "$DATA_DIR/buildings.csv:buildings"
  "$DATA_DIR/workers.csv:workers"
  "$DATA_DIR/inventory.csv:inventory"
)

VALID_PAIRS=()
for pair in "${CSV_PAIRS[@]}"; do
  path="${pair%%:*}"
  table="${pair##*:}"
  if [ -f "$path" ]; then
    VALID_PAIRS+=("$path::$table")
  else
    echo "⚠️  Skipping missing CSV: $path"
  fi
done

if [ "${#VALID_PAIRS[@]}" -eq 0 ]; then
  echo "❌ ERROR: No CSV files found – aborting." >&2
  exit 1
fi

# ensure Resources folder exists
mkdir -p "$(dirname "$OUTPUT_SQL")"

# ───────────────────────────────────────────────────────────
# 3️⃣  Pass the pairs & output path into embedded Python
# ───────────────────────────────────────────────────────────
export _CSV_PAIRS="$(printf "%s;;" "${VALID_PAIRS[@]}")"
export _OUT_SQL="$OUTPUT_SQL"

python3 <<'PYCODE'
import csv, hashlib, pathlib, os, sys

# Read our environment variables
csv_pairs = os.environ["_CSV_PAIRS"].split(";;")
out_file  = pathlib.Path(os.environ["_OUT_SQL"])
sha       = hashlib.sha256()

# Build map and checksum
map_entries = []
for pair in csv_pairs:
    if not pair: continue
    path, table = pair.split("::",1)
    p = pathlib.Path(path)
    if p.exists():
        map_entries.append((p, table))
        sha.update(p.read_bytes())
    else:
        print(f"⚠️  (Python) skipping missing: {p}")

checksum = sha.hexdigest()

# Write the SQL
with out_file.open("w", encoding="utf-8") as out:
    out.write(f"-- CHECKSUM:{checksum}\n")
    out.write("-- Auto-generated — DO NOT EDIT.\n")
    out.write("BEGIN IMMEDIATE;\n\n")

    CHUNK = 300
    for p, table in map_entries:
        rows = list(csv.DictReader(open(p, newline='', encoding='utf-8')))
        if not rows:
            continue

        cols = ",".join(f'"{c}"' for c in rows[0].keys())
        for i in range(0, len(rows), CHUNK):
            batch = rows[i:i+CHUNK]
            vals = []
            for r in batch:
                safe = [str(v).replace("'", "''") for v in r.values()]
                vals.append("(" + ",".join(f"'{v}'" for v in safe) + ")")
            out.write(f"INSERT INTO {table} ({cols}) VALUES\n")
            out.write(",\n".join(vals) + ";\n")
        out.write(f"\n-- End of {table}\n\n")

    out.write(
        f"INSERT OR REPLACE INTO app_settings (key,value) "
        f"VALUES ('csv_checksum','{checksum}');\n"
    )
    out.write("COMMIT;\n")

print(f"✅ Generated SQL seed at {out_file}")
PYCODE

echo "✅ csv2sql.sh finished successfully."
