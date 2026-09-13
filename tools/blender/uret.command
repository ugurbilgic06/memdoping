#!/bin/bash
# MemDoping — hafıza sarayı üretimi. Çift tıklayın.
# Her şeyi tools/blender/son_calisma.log dosyasına da yazar.

cd "$(dirname "$0")/../.." || exit 1
LOG="tools/blender/son_calisma.log"
exec > >(tee "$LOG") 2>&1

echo "=== MemDoping üretim günlüğü ==="
date
echo "Çalışma klasörü: $(pwd)"
echo

BL=""
for p in \
  "/Applications/Blender.app/Contents/MacOS/Blender" \
  "$HOME/Applications/Blender.app/Contents/MacOS/Blender" \
  "$HOME/Downloads/Blender.app/Contents/MacOS/Blender" \
  "$HOME/Desktop/Blender.app/Contents/MacOS/Blender" \
  "/Volumes/Blender/Blender.app/Contents/MacOS/Blender"
do
  echo "denendi: $p"
  [ -x "$p" ] && BL="$p" && echo "  ↑ BULUNDU" && break
done

if [ -z "$BL" ]; then
  echo "Bilinen yollarda yok — çalışan süreçlere bakılıyor"
  RUNNING=$(ps -Ao args | grep -m1 "[B]lender.app/Contents/MacOS/Blender")
  echo "ps sonucu: ${RUNNING:-(boş)}"
  [ -n "$RUNNING" ] && BL="${RUNNING%% *}"
fi

if [ -z "$BL" ] || [ ! -x "$BL" ]; then
  echo
  echo "SONUÇ: Blender bulunamadı."
  echo "Blender.app'i Applications klasörüne taşıyın."
  read -n 1 -s -r -p "Kapatmak için bir tuşa basın"
  exit 1
fi

echo
echo "Blender: $BL"
echo "Script:  tools/blender/memory_palace.py"
echo "----------------------------------------"
"$BL" -b -P tools/blender/memory_palace.py -- \
  --out MemDoping/MemDoping/Resources/Models/palace_home.usdz --route home
RC=$?
echo "----------------------------------------"
echo "Blender çıkış kodu: $RC"
echo
ls -la MemDoping/MemDoping/Resources/Models/ 2>&1
echo
echo "=== bitti ==="
read -n 1 -s -r -p "Kapatmak için bir tuşa basın"
