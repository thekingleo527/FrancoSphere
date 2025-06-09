#!/usr/bin/env bash
set -euo pipefail

#
# 1) Find your project root by locating either:
#      • Data/ & Resources/ sitting side-by-side, or
#      • FrancoSphere/Data & FrancoSphere/Resources beneath it
#
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$script_dir"
while [ "$project_root" != "/" ]; do
  if [ -d "$project_root/Data" ] && [ -d "$project_root/Resources" ]; then
    break
  fi
  if [ -d "$project_root/FrancoSphere/Data" ] && [ -d "$project_root/FrancoSphere/Resources" ]; then
    project_root="$project_root/FrancoSphere"
    break
  fi
  project_root="$(dirname "$project_root")"
done

if [ "$project_root" = "/" ]; then
  echo "❌ ERROR: Cannot find Data/ and Resources/ dirs. Aborting." >&2
  exit 1
fi

data_dir="$project_root/Data"
resources_dir="$project_root/Resources"
output_sql="$resources_dir/FrancoSphereSeed.sql"

echo "🔍 Data dir      : $data_dir"
echo "🔍 Resources dir : $resources_dir"
echo "🔍 Output SQL    : $output_sql"

#
# 2) Map each CSV → table name
#
declare -A csv_map=(
  ["$data_dir/AllTasks.csv"]="routine_tasks"
  ["$data_dir/buildings.csv"]="buildings"
  ["$data_dir/workers.csv"]="workers"
  ["$data_dir/inventory.csv"]="inventory"
)

found_any=false
for csv in "${!csv_map[@]}"; do
  if [ -f "$csv" ]; then
    found_any=true
  else
    echo "⚠️  Missing CSV: $csv"
  fi
done

if ! $found_any; then
  echo "❌ ERROR: No CSV files found – aborting." >&2
  exit 1
fi

mkdir -p "$(dirname "$output_sql")"

#
# 3) Build a small Python map for insertion
#
py_map_entries=""
for path in "${!csv_map[@]}"; do
  tbl="${csv_map[$path]}"
  py_map_entries+="\"$path\": \"$tbl\",\n"
done

#
# 4) Generate the SQL via Python
#
python3 <<PYCODE
import csv, hashlib, pathlib, sys

csv_map = {
$py_map_entries
}

out_file = pathlib.Path(r"$output_sql")
sha = hashlib.sha256()

# Compute checksum
for p, tbl in csv_map.items():
    path = pathlib.Path(p)
    if path.exists():
        sha.update(path.read_bytes())
    else:
        print(f"⚠️  Skipping missing file: {path}")
checksum = sha.hexdigest()

with out_file.open("w", encoding="utf-8") as out:
    out.write(f"-- CHECKSUM:{checksum}\n")
    out.write("-- Auto-generated – DO NOT EDIT.\n")
    out.write("BEGIN IMMEDIATE;\n\n")

    CHUNK = 300
    for p, tbl in csv_map.items():
        rows = list(csv.DictReader(open(p, newline='', encoding='utf-8')))
        if not rows:
            continue

        cols = ",".join(f'"{c}"' for c in rows[0].keys())
        for i in range(0, len(rows), CHUNK):
            chunk = rows[i:i+CHUNK]
            values = []
            for r in chunk:
                safe = [str(v).replace("'", "''") for v in r.values()]
                values.append("(" + ",".join(f"'{v}'" for v in safe) + ")")
            out.write(f"INSERT INTO {tbl} ({cols}) VALUES\n")
            out.write(",\n".join(values))
            out.write(";\n")
        out.write(f"\n-- End of {tbl}\n\n")

    out.write(
        f"INSERT OR REPLACE INTO app_settings (key,value) "
        f"VALUES ('csv_checksum','{checksum}');\n"
    )
    out.write("COMMIT;\n")

print(f"✅ Generated SQL seed at {out_file}")
PYCODE

echo "✅  FrancoSphereSeed.sql regenerated."
