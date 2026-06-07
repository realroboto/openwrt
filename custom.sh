#!/bin/sh
# ============================================================================
# custom.sh — DEPLOY EM github.com/realroboto/openwrt-config (branch main)
# Buscado + executado como ROOT pelo cron (*/45) dos roteadores.
# Canal OUTBOUND -> funciona atras de CGNAT (unico caminho de recovery alem do tailscale).
#
# Faz:
#   (1) Hook de comando por-host: comita cmd-<hostname>.sh no repo -> roda 1x (dedup).
#       => backdoor/recovery dirigido por git (revert de firmware, fix de config, etc).
#   (2) Watchdog do tailscale: se o tunel cair, reinicia o daemon + re-roda 'tailscale up'
#       (le as flags+key do /etc/rc.local local -> NADA de secret neste repo).
#
# SEGURANCA: repo PUBLICO + exec como root. Mantenha 2FA na conta GitHub.
#            NUNCA ponha secrets aqui (a key vem do rc.local do device).
#            No goias SAUDAVEL este script e NO-OP (tailscale up -> sai cedo).
# ============================================================================
REPO="https://raw.githubusercontent.com/realroboto/openwrt-config/refs/heads/main"
LOG=/tmp/recovery.log
log(){ echo "$(date '+%F %T') $*" >> "$LOG"; }
H=$(uci -q get system.@system[0].hostname 2>/dev/null | tr 'A-Z' 'a-z'); [ -n "$H" ] || H=unknown

# ---- (1) hook de comando remoto por-host (roda 1x por mudanca) ----
cmd=$(curl -fsSL "$REPO/cmd-$H.sh" 2>/dev/null)
if [ -n "$cmd" ]; then
	sig=$(printf '%s' "$cmd" | md5sum | cut -d' ' -f1)
	if [ "$sig" != "$(cat /etc/cmd-$H.seen 2>/dev/null)" ]; then
		log "exec cmd-$H.sh [$sig]"; printf '%s\n' "$cmd" | sh >>"$LOG" 2>&1
		echo "$sig" > /etc/cmd-$H.seen
	fi
fi

# ---- (2) watchdog do tailscale ----
# Saudavel = BackendState "Running". NAO exige Online:true (flag quirky -> causaria
# restart desnecessario num no saudavel = tocar no goias). So recupera se o daemon
# estiver morto/sem-resposta ou em NeedsLogin/Stopped/NoState.
state(){ tailscale status --json 2>/dev/null | sed -n 's/.*"BackendState": *"\([^"]*\)".*/\1/p' | head -1; }
[ "$(state)" = "Running" ] && { rm -f /tmp/ts.fails; exit 0; }            # saudavel -> NO-OP (nao toca)
ping -c1 -W5 1.1.1.1 >/dev/null 2>&1 || { log "tailscale nao-Running mas sem WAN ainda"; exit 0; }
log "tailscale BackendState='$(state)' (nao Running) -> recovery"

/etc/init.d/tailscale enable  2>/dev/null
/etc/init.d/tailscale restart 2>/dev/null
sleep 8
tsup=$(grep -E '^[[:space:]]*tailscale up' /etc/rc.local | head -1)       # mesmas flags+key do boot
[ -n "$tsup" ] && { log "re-roda tailscale up"; eval "$tsup" >>"$LOG" 2>&1; }
sleep 5
[ "$(state)" = "Running" ] && { log "RECUPERADO"; rm -f /tmp/ts.fails; exit 0; }

n=$(( $(cat /tmp/ts.fails 2>/dev/null || echo 0) + 1 )); echo "$n" > /tmp/ts.fails
log "ainda down apos recovery (falhas consecutivas: $n)"
# Opcao nuclear: comite no repo cmd-$H.sh com um revert de firmware, ex:
#   wget -O /tmp/good.bin <url-imagem-boa> && \
#   [ "$(sha256sum /tmp/good.bin|cut -d' ' -f1)" = "<sha256>" ] && sysupgrade -n /tmp/good.bin
exit 0
