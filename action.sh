 
#!/system/bin/sh
# =====================================================
# Script : pif-toggle.sh
# Auteur : [Chuppito]
# Objet  : Active ou désactive spoofVendingSdk selon Volume+ ou Volume-
MODDIR=${0%/*}
PROP_PATH="/data/adb/modules/playintegrityfix/custom.pif.prop"
KILL_SCRIPT="/data/adb/modules/playintegrityfix/killpi.sh"

ui_print() { echo "$1"; }

ui_print "-----------------------------------"
ui_print " Volume+ = ENABLE spoofVendingSdk (1)"
ui_print " Volume- = DISABLE spoofVendingSdk (0)"
ui_print " (10s pour appuyer...)"
ui_print "-----------------------------------"

# wait for volume key (10s)
VOLUME_KEY=""
SECONDS=0
while [ "$SECONDS" -lt 10 ]; do
  ev=$(getevent -lq 2>/dev/null | grep -m1 "KEY_VOLUME")
  if echo "$ev" | grep -q "VOLUMEUP"; then
    VOLUME_KEY="1"; ui_print "Volume+ détecté"; break
  elif echo "$ev" | grep -q "VOLUMEDOWN"; then
    VOLUME_KEY="0"; ui_print "Volume- détecté"; break
  fi
done

if [ -z "$VOLUME_KEY" ]; then
  ui_print "Aucun bouton détecté - annulation."
  exit 1
fi

if [ ! -f "$PROP_PATH" ]; then
  ui_print "Fichier non trouvé: $PROP_PATH"
  exit 1
fi

# backup
cp "$PROP_PATH" "${PROP_PATH}.bak"
ui_print "Sauvegarde: ${PROP_PATH}.bak"

# extract fingerprint from PROP_PATH
# look for ro.build.fingerprint=..., or FINGERPRINT=..., or a generic fingerprint line
FINGERPRINT_VALUE=""
FINGERPRINT_VALUE=$(grep -m1 '^ro.build.fingerprint=' "$PROP_PATH" 2>/dev/null | sed 's/^ro.build.fingerprint=//')
if [ -z "$FINGERPRINT_VALUE" ]; then
  # try other possible keys
  FINGERPRINT_VALUE=$(grep -m1 -i '^fingerprint[[:space:]]*=' "$PROP_PATH" 2>/dev/null | sed -E 's/^[^=]*=[[:space:]]*//')
fi

# trim CR/LF and surrounding quotes/spaces
FINGERPRINT_VALUE=$(printf "%s" "$FINGERPRINT_VALUE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//;s/\r//g')

if [ -z "$FINGERPRINT_VALUE" ]; then
  ui_print "Aucun fingerprint trouvé dans $PROP_PATH. Aucune insertion de spoofVendingFinger."
else
  ui_print "Fingerprint trouvé: $FINGERPRINT_VALUE"
  # remove existing spoofVendingFinger line(s)
  sed -i '/^spoofVendingFinger[[:space:]]*=/d' "$PROP_PATH"
  # ensure last non-empty line ends with newline and append the new key at the end
  printf "\nspoofVendingFinger=%s\n" "$FINGERPRINT_VALUE" >> "$PROP_PATH"
  ui_print "spoofVendingFinger ajouté en bas du fichier."
fi

# update spoofVendingSdk in the same prop file
# remove any existing spoofVendingSdk= lines
sed -i '/^spoofVendingSdk[[:space:]]*=/d' "$PROP_PATH"
# append new value (or you may prefer to insert near other settings)
printf "spoofVendingSdk=%s\n" "$VOLUME_KEY" >> "$PROP_PATH"
ui_print "spoofVendingSdk=%s ajouté dans %s" "$VOLUME_KEY" "$PROP_PATH"

# run killpi.sh if present
if [ -f "$KILL_SCRIPT" ]; then
  chmod +x "$KILL_SCRIPT" 2>/dev/null || true
  sh "$KILL_SCRIPT" 2>/dev/null || true
  ui_print "killpi.sh exécuté."
else
  ui_print "killpi.sh introuvable (ignoré)."
fi

ui_print "Opération terminée."
exit 0
