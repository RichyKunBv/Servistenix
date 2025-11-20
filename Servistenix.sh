#!/bin/bash


# version 0.1


# --- Colores para la interfaz ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin Color

# --- Función para mostrar servicios de Homebrew ---
function show_brew_services() {
    echo -e "${BLUE}--- Servicios de Homebrew ---${NC}"
    
    # === CAMBIO AQUÍ ===
    # Reemplazamos 'mapfile' con un bucle 'while' para mayor compatibilidad
    services=() # Inicializamos un array vacío
    while IFS= read -r line; do
        services+=("$line")
    done < <(brew services list | tail -n +2)
    # === FIN DEL CAMBIO ===

    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${YELLOW}No se encontraron servicios de Homebrew.${NC}"
        return
    fi

    echo "Selecciona un servicio para gestionar:"
    options=("${services[@]}" "Volver al menú principal")
    
    select choice in "${options[@]}"; do
        local last_option_num=$((${#options[@]}))
        
        if [ "$REPLY" -eq "$last_option_num" ]; then
            break
        elif [[ "$REPLY" -gt 0 && "$REPLY" -le "${#services[@]}" ]]; then
            local service_line="${services[$REPLY-1]}"
            local service_name=$(echo "$service_line" | awk '{print $1}')
            manage_service "homebrew" "$service_name"
            break
        else
            echo "Opción no válida. Inténtalo de nuevo."
        fi
    done
    show_brew_services
}

# --- Función para mostrar servicios de Aplicaciones (LaunchAgents) ---
function show_app_services() {
    echo -e "${BLUE}--- Servicios/Agentes de Aplicaciones de Usuario ---${NC}"
    local agents_path="$HOME/Library/LaunchAgents"

    # === CAMBIO AQUÍ ===
    # También reemplazamos 'mapfile' aquí
    agent_names=() # Inicializamos un array vacío
    while IFS= read -r line; do
        agent_names+=("$line")
    done < <(find "$agents_path" -maxdepth 1 -name "*.plist" -exec basename {} \; 2>/dev/null)
    # === FIN DEL CAMBIO ===

    if [ ${#agent_names[@]} -eq 0 ]; then
        echo -e "${YELLOW}No se encontraron agentes de aplicaciones en $agents_path${NC}"
        return
    fi
    
    echo "Selecciona un agente para gestionar:"
    options=("${agent_names[@]}" "Volver al menú principal")

    select choice in "${options[@]}"; do
        local last_option_num=$((${#options[@]}))

        if [ "$REPLY" -eq "$last_option_num" ]; then
            break
        elif [[ "$REPLY" -gt 0 && "$REPLY" -le "${#agent_names[@]}" ]]; then
            local agent_name="${agent_names[$REPLY-1]}"
            manage_service "launchctl" "$agents_path/$agent_name"
            break
        else
            echo "Opción no válida. Inténtalo de nuevo."
        fi
    done
    show_app_services
}

# --- Función para gestionar el servicio seleccionado ---
function manage_service() {
    local type=$1
    local name=$2
    local simple_name=$(basename "$name" .plist)

    echo -e "\nGestionando: ${YELLOW}$simple_name${NC}"
    echo "¿Qué deseas hacer?"
    
    options=("Iniciar/Habilitar" "Detener/Deshabilitar" "Cancelar")

    select action in "${options[@]}"; do
        case $REPLY in
            1)
                if [ "$type" == "homebrew" ]; then
                    brew services start "$name"
                else
                    launchctl load -w "$name"
                    echo -e "${GREEN}Agente habilitado.${NC}"
                fi
                break
                ;;
            2)
                if [ "$type" == "homebrew" ]; then
                    brew services stop "$name"
                else
                    launchctl unload -w "$name"
                    echo -e "${GREEN}Agente deshabilitado.${NC}"
                fi
                break
                ;;
            3)
                break
                ;;
            *)
                echo "Opción no válida."
                ;;
        esac
    done
}

# --- Menú Principal ---
while true; do
    clear
    echo -e "${GREEN}===== Monitor de Servicios para macOS =====${NC}"
    echo "Elige una categoría:"
    
    options=("Servicios de Homebrew" "Servicios de Aplicaciones" "Salir")
    PS3="Ingresa el número de tu opción: "

    select choice in "${options[@]}"; do
        case $REPLY in
            1)
                show_brew_services
                break
                ;;
            2)
                show_app_services
                break
                ;;
            3)
                echo "¡Hasta luego!"
                exit 0
                ;;
            *)
                echo "Opción no válida. Inténtalo de nuevo."
                break
                ;;
        esac
    done
    echo -e "\n${YELLOW}Presiona Enter para volver al menú principal...${NC}"
    read
done
