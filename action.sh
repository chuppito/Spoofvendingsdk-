#!/system/bin/sh

JSON_PATH="/data/adb/modules/playintegrityfix/custom.pif.json"
KILL_SCRIPT="/data/adb/modules/playintegrityfix/killpi.sh"

log() {
  echo "$1"
  ui_print "$1"
}

log " "
log "==============================="
log " Volume+ : ACTIVER spoofVendingSdk"
log " Volume- : DÉSACTIVER spoofVendingSdk"
log " (10 secondes pour appuyer...)"
log "==============================="

# Attente d'un événement volume
VOLUME_KEY=""
event=""

SECONDS=0
while [ "$SECONDS" -lt 10 ]; do
  event=$(getevent -lq 2>/dev/null | grep -m 1 "KEY_VOLUME")
  if echo "$event" | grep -q "VOLUMEUP"; then
    VOLUME_KEY="1"
    log "✓ Volume+ détecté"
    break
  elif echo "$event" | grep -q "VOLUMEDOWN"; then
    VOLUME_KEY="0"
    log "✓ Volume- détecté"
    break
  fi
done

if [ -z "$VOLUME_KEY" ]; then
  log "✗ Aucun bouton détecté. Annulation."
  exit 1
fi

# Édition du JSON
if [ -f "$JSON_PATH" ]; then
    cp "$JSON_PATH" "${JSON_PATH}.bak"
    sed -i '/"spoofVendingSdk"/d' "$JSON_PATH"
    sed -i -E '/"spoofBuild"[ ]*:[ ]*"[0-9]+",/a\\    "spoofVendingSdk": "'"$VOLUME_KEY"'",' "$JSON_PATH"
    log "✔ spoofVendingSdk défini à $VOLUME_KEY"
else
    log "❌ Fichier introuvable : $JSON_PATH"
    exit 1
fi

# Redémarrer killpi.sh
log "↻ Vérification de killpi.sh..."

if [ -f "$KILL_SCRIPT" ]; then
    ls -l "$KILL_SCRIPT"
    cat "$KILL_SCRIPT"
    chmod +x "$KILL_SCRIPT"
    "$KILL_SCRIPT"
    log "✔ killpi.sh exécuté avec succès."
else
    log "⚠️ killpi.sh introuvable à $KILL_SCRIPT"
fi

exit 0
