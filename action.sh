#!/system/bin/sh

JSON_PATH="/data/adb/modules/playintegrityfix/custom.pif.json"
KILL_SCRIPT="/data/adb/modules/playintegrityfix/killpi.sh"

log() {
echo "$1"
ui_print "$1"
}

log " "
log "==============================="
log " Volume+ : active (1) spoofVendingSdk"
log " Volume- : désactive (0) spoofVendingSdk"
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

# --- Début de la modification JSON ---

if [ -f "$JSON_PATH" ]; then
    log "↻ Début de la modification du JSON..."
    cp "$JSON_PATH" "${JSON_PATH}.bak"
    
    # 1. Extraire la valeur du FINGERPRINT
    # Cherche la ligne, capture la valeur entre les guillemets.
    FINGERPRINT_VALUE=$(grep '"FINGERPRINT"' "$JSON_PATH" | sed -E 's/.*"[^"]*"[[:space:]]*:[[:space:]]*"([^"]*)",?/\1/')

    if [ -n "$FINGERPRINT_VALUE" ]; then
        log "✓ FINGERPRINT extrait : $FINGERPRINT_VALUE"
        
        # 2. Supprimer l'ancienne ligne "spoofVendingFinger" si elle existe
        sed -i '/"spoofVendingFinger"/d' "$JSON_PATH"
        log "✔ Ancienne \"spoofVendingFinger\" supprimée (si présente)."
        
        # 3. Insérer la nouvelle ligne "spoofVendingFinger" APRÈS "verboseLogs"
        # NOTE : On insère la nouvelle ligne AVEC une virgule de fin, car elle doit être suivie
        # d'autres lignes comme "// Beta Released". Sauf si elle était vraiment la dernière clé.
        # En se basant sur la structure montrée, je l'ajoute juste après.
        
        # Pour une insertion correcte dans la section, nous allons l'insérer après verboseLogs,
        # en nous assurant que la ligne précédente se termine par une virgule si ce n'était pas le cas.
        
        # Nous allons d'abord nous assurer que la ligne "verboseLogs" a une virgule de fin
        # (si elle n'est pas déjà présente), car nous allons insérer la nouvelle ligne juste après.
        sed -i -E '/"verboseLogs"[ ]*:[ ]*"[0O]",/s/"[0O]"/"[0O]",/' "$JSON_PATH"
        
        NEW_FINGER_LINE='    "spoofVendingFinger": "'"$FINGERPRINT_VALUE"'",'
        # Insertion APRÈS la ligne "verboseLogs" (qui se termine maintenant par une virgule)
        sed -i -E '/"verboseLogs"/a\'"$NEW_FINGER_LINE" "$JSON_PATH"
        log "✔ \"spoofVendingFinger\" inséré AVANT la fin de la section Advanced Settings."
        
        
        # Petite correction pour l'ordre, si vous le souhaitez vraiment à la fin, il faut être précis.
        # Si vous voulez qu'il soit la VRAIE dernière clé AVANT la fin de la section 'Advanced Settings'
        # il faudrait qu'il n'ait PAS de virgule. Mais en se basant sur votre structure (verboseLogs: "O"),
        # l'insertion après verboseLogs est le plus sûr.
    else
        log "❌ ERREUR: Impossible d'extraire la valeur FINGERPRINT. Vérifiez le format de la ligne \"FINGERPRINT\"."
    fi

    # 4. Mettre à jour "spoofVendingSdk" avec la touche Volume
    # Supprimer l'ancienne ligne "spoofVendingSdk"
    sed -i '/"spoofVendingSdk"/d' "$JSON_PATH"
    # Insérer la nouvelle ligne "spoofVendingSdk" après "spoofBuild" (pour conserver la logique de la clé)
    # NOTE: J'ai conservé cette insertion à cet endroit car c'est une clé standard du module, contrairement à spoofVendingFinger.
    sed -i -E '/"spoofBuild"[ ]*:[ ]*"[01]",/a\    "spoofVendingSdk": "'"$VOLUME_KEY"'",' "$JSON_PATH"
    log "✔ spoofVendingSdk défini à $VOLUME_KEY"
else
    log "❌ Fichier introuvable : $JSON_PATH"
    exit 1
fi

# --- Fin de la modification JSON ---

# démarrer (start) killpi.sh
log " "
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
