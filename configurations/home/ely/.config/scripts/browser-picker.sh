#!/usr/bin/env bash
# ~/.local/bin/browser-picker
# Definir como browser padrão do sistema

URL="$1"

# Browsers disponíveis — edite à vontade
declare -A BROWSERS=(
  ["  Firefox (estudos/trabalho)"]="firefox"
  ["  Brave Origin (gaming/leve)"]="brave-origin" # ou o nome do binário
)

# Monta a lista pro rofi
CHOICE=$(printf '%s\n' "${!BROWSERS[@]}" |
  rofi -dmenu \
    -p "Abrir com:" \
    -theme-str 'window {width: 600px;}' \
    -i)

# Sai silenciosamente se cancelar
[[ -z "$CHOICE" ]] && exit 0

# Executa o browser escolhido com a URL
exec "${BROWSERS[$CHOICE]}" "$URL"
