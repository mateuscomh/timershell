#!/usr/bin/env bash

#----------------------------------------------------|
#  Timershell v1.6.1
#  Matheus Martins 3mhenrique@gmail.com
#  https://github.com/mateuscomh/yoURL
#  14/12/2024 GPL3
#  Shell GUI timer regressivo com notificação
#  Deps: dunstify, paplay, timer(https://github.com/caarlos0/timer)
#----------------------------------------------------|

USAGE=$(
	cat <<'EOF'
   __   _                        _____  __           __ __
  / /_ (_)____ ___   ___   _____/ ___/ / /_   ___   / // /
 / __// // __ `__ \ / _ \ / ___/\__ \ / __ \ / _ \ / // /
/ /_ / // / / / / //  __// /   ___/ // / / //  __// // /
\__//_//_/ /_/ /_/ \___//_/   /____//_/ /_/ \___//_//_/
v1.6.1
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

deps=("dunstify" "paplay" "timer")

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
	read -rp "Defina o temporizador (ex: 10s, 5m, 1h ou hh:mm) [10s]: " tempo
fi

_saida "$tempo"
tempo=${tempo:-10s}

# Verificação do formato de hora
if [[ "$tempo" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
	echo "Calculando tempo até $tempo..."
	current_time=$(date +%s)
	IFS=: read -r hora minuto <<<"$tempo"
	target_time=$(date -d "today $hora:$minuto" +%s)
	if ((target_time < current_time)); then
		target_time=$((target_time + 86400))
	fi
	# Calcula o tempo restante em segundos
	segundos_total=$((target_time - current_time))
	echo "Tempo restante: $segundos_total segundos."
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
	echo "Formato de tempo inválido. Use o formato 10s, 5m, 1h ou hh:mm."
	exit 1
fi

mensagem="${*:2}"
if [[ -z "$mensagem" ]]; then
	read -rp "Digite a mensagem para exibir ao final do temporizador: " mensagem
fi
#_saida "$mensagem"
[[ -z "$mensagem" ]] && mensagem="em execução"

echo "Iniciando temporizador $mensagem por $segundos_total segundos..."

bash -c "timer ${segundos_total}" &
PID=$!
intervalo=1
total_passos=$((segundos_total / intervalo))
current=0

while [ "$current" -le "$total_passos" ]; do
	progresso=$((current * 100 / total_passos))
	tempo_restante=$((segundos_total - current * intervalo))
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

	dunstify --icon preferences-desktop-screensaver \
		-h int:value:"$progresso" \
		-h 'string:hlcolor:#ff4444' -u low \
		-h string:x-dunst-stack-tag:temporizador \
		--timeout=1020 "Temporizador $mensagem..." "Faltam $temporizador"

	if [ "$current" -ne "$total_passos" ]; then
		if ! kill -0 "$PID" 2>/dev/null; then
			wait "$PID"
			exit_status=$?
			if [ "$exit_status" -ne 0 ]; then
				echo "TimerShell $tempo interrompido, restavam: $temporizador"
				date '+%H:%M:%S +%d-%m-%Y'
				dunstify -u normal "Temporizador de $tempo $mensagem" "cancelado às: $(date '+%H:%M:%S %d/%m/%Y')"
				exit 127
			fi
		fi
	fi

	sleep "$intervalo"
	current=$((current + 1))
done

dunstify -u critical "Temporizador de $tempo $mensagem" "finalizado às: $(date '+%H:%M:%S %d/%m/%Y')"
echo "Temporizador $mensagem finalizado às: $(date '+%H:%M:%S %d/%m/%Y')"
paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga
