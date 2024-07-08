#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
NC='\033[0m' # No Color

SERVICE_NAME="gre-tunnel.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

# Function to create the GRE tunnel service
create_service() {
    echo -e "${YELLOW}"
    echo "========================================="
    echo "  CREATE CONFIGURATION AND SERVICE       "
    echo "========================================="
    echo -e "${NC}"

    echo -e "${YELLOW}Select Server Type:${NC}"
    echo -e "${CYAN}1. Iran Server${NC}"
    echo -e "${CYAN}2. Kharej Server${NC}"
    read -rp "$(echo -e ${CYAN})Enter your choice: $(echo -e ${NC})" server_type
    case $server_type in
        1)
            local_ip="2001:db8::1"
            other_local_ip="2001:db8::2"
            ;;
        2)
            local_ip="2001:db8::2"
            other_local_ip="2001:db8::1"
            ;;
        *)
            echo -e "${RED}Invalid choice.${NC}"
            return
            ;;
    esac

    read -rp "$(echo -e ${CYAN})Enter local IP: $(echo -e ${NC})" local
    read -rp "$(echo -e ${CYAN})Enter remote IP: $(echo -e ${NC})" remote

    cat <<EOF > $SERVICE_FILE
[Unit]
Description=IPv6 GRE Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ip -6 tunnel add gre10 mode ip6gre remote $remote local $local
ExecStart=/sbin/ip -6 addr add $local_ip/64 dev gre10
ExecStart=/sbin/ip link set gre10 up
ExecStop=/sbin/ip link set gre10 down
ExecStop=/sbin/ip -6 tunnel del gre10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl start $SERVICE_NAME

    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}GRE tunnel service created and started successfully.${NC}"
    else
        echo -e "${RED}Failed to start GRE tunnel service.${NC}"
    fi

    echo -e "${CYAN}Local IP used in the configuration: ${GREEN}$local_ip${NC}"
}

# Function to remove the GRE tunnel service
remove_service() {
    echo -e "${RED}"
    echo "========================================="
    echo "  REMOVE CONFIGURATION AND SERVICE       "
    echo "========================================="
    echo -e "${NC}"

    read -rp "$(echo -e ${RED})Are you sure you want to remove the service? (yes/no): $(echo -e ${NC})" confirm
    if [[ $confirm == "yes" ]]; then
        systemctl stop $SERVICE_NAME
        systemctl disable $SERVICE_NAME
        rm -f $SERVICE_FILE
        systemctl daemon-reload
        echo -e "${GREEN}GRE tunnel service removed successfully.${NC}"
    else
        echo -e "${YELLOW}Operation canceled.${NC}"
    fi
}

# Function to show the GRE tunnel service status
show_status() {
    echo -e "${CYAN}"
    echo "========================================="
    echo "      SHOW SERVICE STATUS                "
    echo "========================================="
    echo -e "${NC}"

    systemctl status $SERVICE_NAME --no-pager
    read -p "Press Enter to continue..."
}

# Function to restart the GRE tunnel service
restart_service() {
    echo -e "${CYAN}"
    echo "========================================="
    echo "      RESTART GRE TUNNEL SERVICE         "
    echo "========================================="
    echo -e "${NC}"

    systemctl restart $SERVICE_NAME

    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}GRE tunnel service restarted successfully.${NC}"
    else
        echo -e "${RED}Failed to restart GRE tunnel service.${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to check the connection by pinging the other local IP
check_connection() {
    echo -e "${CYAN}"
    echo "========================================="
    echo "         CHECK CONNECTION                "
    echo "========================================="
    echo -e "${NC}"

    if ping6 -c 4 $other_local_ip; then
        echo -e "${GREEN}Ping to $other_local_ip successful.${NC}"
    else
        echo -e "${RED}Ping to $other_local_ip failed.${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Main menu function
main_menu() {
    while true; do
        clear
        echo -e "${GREEN}"
        echo "========================================="
        echo "   MahdiPatrioT GRE6 MENU                "
        echo "========================================="
        echo -e "${NC}"

        echo -e "${GREEN}1. Create Configuration and Service${NC}"
        echo -e "${RED}2. Remove Configuration and Service${NC}"
        echo -e "${CYAN}3. Show Service Status${NC}"
        echo -e "${YELLOW}4. Restart GRE Tunnel Service${NC}"
        echo -e "${CYAN}5. Check Connection${NC}"
        echo -e "${RED}6. Exit${NC}"
        echo ""
        echo -e "${CYAN}GitHub Source: ${GREEN}https://github.com/mahdipatriot/GRE_Tunnel/new/main${NC}"
        echo ""
        echo -n "Enter your choice: "
        read choice

        case $choice in
            1)
                create_service
                ;;
            2)
                remove_service
                ;;
            3)
                show_status
                ;;
            4)
                restart_service
                ;;
            5)
                check_connection
                ;;
            6)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Start the main menu
main_menu
