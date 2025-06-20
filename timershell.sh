#!/usr/bin/env bash

#----------------------------------------------------|
#  Timershell v2.3.5
#  Matheus Martins 3mhenrique@gmail.com
#  https://github.com/mateuscomh/timershell
#  14/12/2024 GPL3
#  Shell GUI timer regressivo com notificação
#  Deps: Linux (dunstify, paplay),timer(https://github.com/caarlos0/timer)
#  Deps: Mac osascript, afplay, timer(https://github.com/caarlos0/timer)
#----------------------------------------------------|

USAGE=$(
	cat <<'EOF'
   __   _                        _____  __           __ __
  / /_ (_)____ ___   ___   _____/ ___/ / /_   ___   / // /
 / __// // __ '__ \ / _ \ / ___/\__ \ / __ \ / _ \ / // /
/ /_ / // / / / / //  __// /   ___/ // / / //  __// // /
\__//_//_/ /_/ /_/ \___//_/   /____//_/ /_/ \___//_//_/
v2.3.2
EOF
)
echo -e "$USAGE"
tempo="$1"

function _saida() {
	local input="$1"
	if [[ "$input" =~ [Qq]$ ]]; then
		echo "Saindo.."
		exit 0
	fi
}

if [[ "$(uname)" == "Darwin" ]]; then
	OS="macOS"
elif [[ "$(uname)" == "Linux" ]]; then
	OS="Linux"
else
	echo "Sistema operacional não suportado."
	exit 1
fi

if [[ "$OS" == "macOS" ]]; then
	deps=("osascript" "afplay" "timer")
elif [[ "$OS" == "Linux" ]]; then
	deps=("dunstify" "paplay" "timer")
fi

_check_dep() {
	if ! command -v "$1" &>/dev/null; then
		echo "Erro: $1 não está instalado."
		exit 1
	fi
}

for dep in "${deps[@]}"; do
	_check_dep "$dep"
done

if [[ -z $1 ]]; then
	echo "Defina o temporizador ou [qQ] para sair"
	echo "(ex: 5m, 1h ou 2:30h para timer regressivo)"
	echo "(HH:MM para temporizado hora específica até 23:59)"
	read -rp " " tempo
fi

_saida "$tempo"
tempo=${tempo:-10s}

# Verificação do formato de tempo
if [[ "$tempo" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
	echo "Calculando tempo até $tempo..."
	current_time=$(date +%s)
	IFS=: read -r hora minuto <<<"$tempo"
	if [[ "$OS" == "macOS" ]]; then
		target_time=$(date -j -f "%H:%M" "$tempo" +%s)
	else
		target_time=$(date -d "$hora:$minuto" +%s)
	fi
	if ((target_time < current_time)); then
		target_time=$((target_time + 86400))
	fi
	segundos_total=$((target_time - current_time))
	echo "Tempo restante: $segundos_total segundos."
elif [[ "$tempo" =~ ^([0-9]+):([0-5][0-9])h$ ]]; then
	# Formato hh:mmh (intervalo de tempo)
	IFS=: read -r horas minutos <<<"${tempo%h}"
	segundos_total=$((horas * 3600 + minutos * 60))
	echo "Iniciando temporizador de $horas horas e $minutos minutos..."
elif [[ "$tempo" =~ ^[0-9]+[smh]$ ]]; then
	case ${tempo: -1} in
	s) segundos_total=${tempo%?} ;;
	m) segundos_total=$((${tempo%?} * 60)) ;;
	h) segundos_total=$((${tempo%?} * 3600)) ;;
	*)
		echo "Formato de tempo inválido."
		exit 1
		;;
	esac
else
	echo "Formato de tempo inválido. Use o formato 10s, 5m, 1h, 02:30 ou 02:30h."
	exit 1
fi

mensagem="${*:2}"

if [[ -z "$mensagem" ]]; then
	read -rp "Digite a mensagem para exibir ao final do temporizador: " mensagem
fi
[[ -z "$mensagem" ]] && mensagem="em execução"

clear
echo "$USAGE"
echo "Iniciando temporizador $mensagem por $segundos_total segundos..."

if [[ "$OS" == "macOS" ]]; then
	end_time=$(date -v +"$segundos_total"S +"%H:%M:%S")
else
	end_time=$(date -d "+$segundos_total seconds" +"%H:%M:%S")
fi

echo "O temporizador irá terminar às $end_time."

bash -c "timer --format 24h ${segundos_total}" &
PID=$!
start_time=$(date +%s)

while true; do
	current_time=$(date +%s)
	elapsed_time=$((current_time - start_time))
	tempo_restante=$((segundos_total - elapsed_time))

	if ((tempo_restante <= -5)); then
		break
	fi

	# Converte o tempo restante para horas, minutos e segundos
	horas=$((tempo_restante / 3600))
	minutos=$(((tempo_restante % 3600) / 60))
	segundos=$((tempo_restante % 60))

	if ((horas > 0)); then
		temporizador="$horas hora(s), $minutos minuto(s) e $segundos segundo(s)"
	elif ((minutos > 0)); then
		temporizador="$minutos minuto(s) e $segundos segundo(s)"
	else
		temporizador="$segundos segundo(s)"
	fi

	# Verifica se o timer ainda está em execução
	if ! kill -0 "$PID" 2>/dev/null; then
		wait "$PID"
		exit_status=$?
		if [ "$exit_status" -ne 0 ]; then
			echo "TimerShell $tempo interrompido em $(date '+%H:%M:%S %d-%m-%Y')"
			echo "Restavam: $temporizador"
			if [[ "$OS" == "macOS" ]]; then
				osascript -e "display notification \"Cancelado às: $(date '+%H:%M:%S %d/%m/%Y')\" with title \"Temporizador de $tempo $mensagem\""
			elif [[ "$OS" == "Linux" ]]; then
				dunstify -u normal "Temporizador de $tempo $mensagem" "cancelado às: $(date '+%H:%M:%S %d/%m/%Y')"
			fi
			exit 127
		fi
		sleep 0.9
	fi

	# Exibir notificação
	if [[ "$OS" == "macOS" ]]; then
		osascript -e "display notification \"Faltam $temporizador\" with title \"Temporizador $mensagem...\""
	elif [[ "$OS" == "Linux" ]]; then
		dunstify --icon preferences-desktop-screensaver \
			-h int:value:"$((elapsed_time * 100 / segundos_total))" \
			-h 'string:hlcolor:#ff4444' -u low \
			-h string:x-dunst-stack-tag:temporizador \
			--timeout=5000 "Temporizador $tempo $mensagem..." "Faltam $temporizador para $end_time"
	fi
done

if [[ "$OS" == "macOS" ]]; then
	osascript -e "display notification \"Finalizado às: $(date '+%H:%M:%S %d/%m/%Y')\" with title \"Temporizador de $tempo $mensagem\""
	echo "Temporizador de $tempo $mensagem" "finalizado às: $(date '+%H:%M:%S %d/%m/%Y')"
	seq 3 | xargs -I {} afplay /System/Library/Sounds/Ping.aiff
elif [[ "$OS" == "Linux" ]]; then
	msg="Temporizador de $tempo $mensagem finalizado às: $(date '+%H:%M:%S %d/%m/%Y')"
	curl -s -o /dev/null -X POST -d "$msg" http://192.168.2.185/test
	echo "$msg"
	dunstify -u critical "Temporizador de $tempo $mensagem" "finalizado às: $(date '+%H:%M:%S %d/%m/%Y')"
	paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga
fi
