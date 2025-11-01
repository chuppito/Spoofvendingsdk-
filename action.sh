 
#!/system/bin/sh
# =====================================================
# Script : pif-toggle.sh
# Auteur : [Chuppito]
# Objet  : Active ou désactive spoofVendingSdk selon Volume+ ou Volume-
# Fonction :
#   - Extraction automatique du FINGERPRINT depuis custom.pif.json
#   - Injection dans spoofVendingFinger
#   - Mise à jour de spoofVendingSdk (1 ou 0)
#   - Exécution de killpi.sh à la fin
# =====================================================

JSON_PATH="/data/adb/modules/playintegrityfix/custom.pif.json"
KILL_SCRIPT="/data/adb/modules/playintegrityfix/killpi.sh"

# === Fonction de log ===
log() {
    echo "$1"
    ui_print "$1"
}

# === En-tête ===
log ""
log "==============================="
log " Volume+ : active (1) spoofVendingSdk"
log " Volume- : désactive (0) spoofVendingSdk"
log " (10 secondes pour appuyer...)"
log "==============================="

# === Détection de la touche volume ===
VOLUME_KEY=""
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

# === Modification du JSON ===
if [ -f "$JSON_PATH" ]; then
    log "↻ Début de la modification du JSON..."
    cp "$JSON_PATH" "${JSON_PATH}.bak"

    # 1️⃣ Extraire la valeur du FINGERPRINT
    FINGERPRINT_VALUE=$(grep '"FINGERPRINT"' "$JSON_PATH" | sed -E 's/.*"[^"]*"[[:space:]]*:[[:space:]]*"([^"]*)",?/\1/')

    if [ -n "$FINGERPRINT_VALUE" ]; then
        log "✓ FINGERPRINT extrait : $FINGERPRINT_VALUE"

        # 2️⃣ Supprimer l'ancienne ligne spoofVendingFinger
        sed -i '/"spoofVendingFinger"/d' "$JSON_PATH"
        log "✔ Ancienne \"spoofVendingFinger\" supprimée (si présente)."

        # 3️⃣ S’assurer que verboseLogs finit par une virgule
        sed -i -E '/"verboseLogs"[[:space:]]*:[[:space:]]*"[0O]"$/s/"$/",/' "$JSON_PATH"

        # 4️⃣ Ajouter la nouvelle ligne spoofVendingFinger après verboseLogs
        NEW_FINGER_LINE='    "spoofVendingFinger": "'"$FINGERPRINT_VALUE"'",'
        sed -i -E '/"verboseLogs"/a\'"$NEW_FINGER_LINE" "$JSON_PATH"
        log "✔ Nouvelle ligne \"spoofVendingFinger\" insérée avec succès."
    else
        log "❌ ERREUR : Impossible d'extraire la valeur du FINGERPRINT."
    fi

    # 5️⃣ Mettre à jour spoofVendingSdk selon la touche Volume
    sed -i '/"spoofVendingSdk"/d' "$JSON_PATH"
    sed -i -E '/"spoofBuild"[[:space:]]*:[[:space:]]*"[01]",/a\    "spoofVendingSdk": "'"$VOLUME_KEY"'",' "$JSON_PATH"
    log "✔ spoofVendingSdk défini à $VOLUME_KEY"

else
    log "❌ Fichier introuvable : $JSON_PATH"
    exit 1
fi

# === Exécution de killpi.sh ===
log ""
log "↻ Vérification de killpi.sh..."

if [ -f "$KILL_SCRIPT" ]; then
    chmod +x "$KILL_SCRIPT"
    "$KILL_SCRIPT"
    log "✔ killpi.sh exécuté avec succès."
else
    log "⚠️  killpi.sh introuvable à $KILL_SCRIPT"
fi

exit 0