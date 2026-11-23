#!/usr/bin/env bash
# Lee el super stock con lpdump y saca los valores para BoardConfig.mk.
# Uso (en la PC, con android-tools instalado):
#   tools/leer-super.sh ~/lisbon/fw/super.raw
# También sirve contra el teléfono (TWRP o Android con root):
#   adb shell lpdump > lpdump.txt && tools/leer-super.sh --texto lpdump.txt
set -euo pipefail

if [[ "${1:-}" == "--texto" ]]; then
    dump="$(cat "$2")"
else
    img="${1:?uso: $0 super.raw | --texto lpdump.txt}"
    command -v lpdump >/dev/null || { echo "falta lpdump (sudo dnf install android-tools)"; exit 1; }
    dump="$(lpdump "$img")"
fi

printf '%s\n' "$dump" > "${TMPDIR:-/tmp}/lpdump-lisbon.txt"
echo "lpdump completo guardado en ${TMPDIR:-/tmp}/lpdump-lisbon.txt"
echo

python3 - "${TMPDIR:-/tmp}/lpdump-lisbon.txt" <<'EOF'
import re, sys
t = open(sys.argv[1]).read()

slots = re.search(r'Metadata slot count:\s*(\d+)', t)
print(f"Metadata slot count: {slots.group(1) if slots else '?'}  (2 = A/B normal, 3 = A/B con virtual A/B posible)")
flags = re.search(r'Header flags:\s*(.*)', t)
print(f"Header flags: {flags.group(1).strip() if flags else '(no aparece)'}  ('virtual_ab_device' => virtual A/B)")

dev = re.search(r'Block device table:.*?Size:\s*(\d+)\s*bytes', t, re.S)
if dev:
    print(f"BOARD_SUPER_PARTITION_SIZE := {dev.group(1)}")

print("\nGrupos:")
for name, size in re.findall(r'Name:\s*(\S+)\s*\n\s*Maximum size:\s*(\d+)\s*bytes', t):
    print(f"  {name:40s} max {int(size):>13,d} bytes ({int(size)/2**20:,.0f} MiB)")

print("\nParticiones (tamaño actual):")
for m in re.finditer(r'Name:\s*(\S+)\s*\n\s*Group:\s*(\S+)\s*\n\s*Attributes:\s*(.*?)\n\s*Extents:\s*\n((?:\s*\d+ \.\. \d+ linear.*\n)*)', t):
    name, group, attrs, ext = m.groups()
    sectors = sum(int(b) - int(a) + 1 for a, b in re.findall(r'(\d+) \.\. (\d+) linear', ext))
    print(f"  {name:20s} {group:40s} {sectors*512/2**20:>9,.1f} MiB  [{attrs.strip()}]")

print("""
Qué pegar en BoardConfig.mk:
  - BOARD_SUPER_PARTITION_SIZE: el de arriba.
  - BOARD_MOTOROLA_DYNAMIC_PARTITIONS_SIZE: el 'Maximum size' del grupo
    motorola_dynamic_partitions_a (sin sufijo en el BoardConfig).
    Si sale 0 o no hay máximo: SUPER - 4 MiB en virtual A/B, o
    SUPER/2 - 4 MiB en A/B normal.
""")
EOF
