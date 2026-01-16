#!/bin/bash

# ==============================================================================
#                        MINECRAFT AUTO-UPDATE WRAPPER
# ==============================================================================
# Originally created for: AfterLands Project (www.afterlands.com)
# Repository: https://github.com/IceGames23/ptero-plugin-updater/
# Description: Automatically updates plugins, manages backups, and handles 
#              server startup for Pterodactyl environments.
# ==============================================================================

# --- [ CONFIGURATION ] --------------------------------------------------------

# Script Versioning
SCRIPT_VERSION="1.1.0"

# Self-Update Settings
# Set to "true" to allow this script to update itself from the GitHub repository.
ENABLE_SELF_UPDATE="false"
# The Raw URL of this script on GitHub
REMOTE_URL="https://raw.githubusercontent.com/IceGames23/ptero-plugin-updater/main/auto_update.sh"

# Directories
PLUGIN_DIR="/home/container/plugins"
UPDATE_DIR="/home/container/auto-updater"
BACKUP_DIR="/home/container/backups-plugins"

# Backup Retention (Days to keep backups)
BACKUP_RETENTION_DAYS=3

# Server JAR (Pterodactyl Environment Variable)
SERVER_JAR=${SERVER_JARFILE:-server.jar} 

# --- [ JAVA CONFIGURATION ] ---------------------------------------------------
# Define the Java binary (usually just "java")
JAVA_BINARY="java"

# Define your startup flags here (Memory, GC, Terminal settings)
JAVA_FLAGS="-Xms128M -XX:MaxRAMPercentage=95.0 -Dterminal.jline=false -Dterminal.ansi=true"

# ------------------------------------------------------------------------------

# --- [ CONSTANTS & HELPERS ] --------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Date formats
TODAY_DIR=$(date +%Y-%m-%d)
TIMESTAMP_SUFFIX=$(date +%Y-%m-%d_%H-%M-%S)

echo -e "${CYAN}[Wrapper] Starting Wrapper Script v${SCRIPT_VERSION}...${NC}"
echo -e "${CYAN}[Wrapper] Powered by AfterLands (www.afterlands.com)${NC}"

# Function: Extract plugin identity (removes version numbers)
get_plugin_identity() {
    echo "$1" | sed -E 's/[-_. ]+[vV]?[0-9].*\.jar$//'
}

# --- [ SELF-UPDATE MODULE ] ---------------------------------------------------
if [ "$ENABLE_SELF_UPDATE" == "true" ]; then
    echo -e "${YELLOW}[Self-Update] Checking for script updates...${NC}"
    
    TEMP_SCRIPT="/tmp/auto_update_latest.sh"
    curl -s -L "$REMOTE_URL" -o "$TEMP_SCRIPT"
    
    if [ -f "$TEMP_SCRIPT" ]; then
        # Try grep with -P (Perl regex)
        REMOTE_VERSION=$(grep -oP 'SCRIPT_VERSION="\K[^"]+' "$TEMP_SCRIPT" 2>/dev/null)
        
        # Fallback for Alpine Linux (BusyBox grep doesn't support -P)
        if [ -z "$REMOTE_VERSION" ]; then
             REMOTE_VERSION=$(grep 'SCRIPT_VERSION=' "$TEMP_SCRIPT" | head -1 | cut -d'"' -f2)
        fi

        if [ "$REMOTE_VERSION" != "$SCRIPT_VERSION" ] && [ -n "$REMOTE_VERSION" ]; then
            echo -e "${GREEN}[Self-Update] New version found: v$REMOTE_VERSION (Current: v$SCRIPT_VERSION). Updating...${NC}"
            cp -f "$TEMP_SCRIPT" "$0"
            chmod +x "$0"
            rm -f "$TEMP_SCRIPT"
            echo -e "${GREEN}[Self-Update] Script updated! Restarting process...${NC}"
            echo "-----------------------------------------------------"
            exec bash "$0"
        else
            echo -e "${CYAN}[Self-Update] Script is up to date.${NC}"
            rm -f "$TEMP_SCRIPT"
        fi
    else
        echo -e "${RED}[Self-Update] Failed to reach GitHub. Skipping update check.${NC}"
    fi
fi

# --- [ INITIALIZATION ] -------------------------------------------------------

if [ ! -d "$UPDATE_DIR" ]; then
    echo -e "${YELLOW}[Updater] Update directory not found. Creating: $UPDATE_DIR${NC}"
    mkdir -p "$UPDATE_DIR"
fi

if [ -d "$BACKUP_DIR" ]; then
    find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +$((BACKUP_RETENTION_DAYS - 1)) -exec rm -rf {} + 2>/dev/null
fi

# --- [ PLUGIN UPDATE LOGIC ] --------------------------------------------------

if [ -n "$(ls -A "$UPDATE_DIR" 2>/dev/null | grep "\.jar$")" ]; then
    echo -e "${YELLOW}[Updater] Processing updates...${NC}"
    mkdir -p "$BACKUP_DIR/$TODAY_DIR"

    for new_jar_path in "$UPDATE_DIR"/*.jar; do
        [ -e "$new_jar_path" ] || continue
        
        new_filename=$(basename -- "$new_jar_path")
        new_identity=$(get_plugin_identity "$new_filename")
        match_found=false

        for installed_plugin_path in "$PLUGIN_DIR"/*.jar; do
            [ -e "$installed_plugin_path" ] || continue
            
            installed_filename=$(basename -- "$installed_plugin_path")
            installed_identity=$(get_plugin_identity "$installed_filename")

            if [ "$new_identity" == "$installed_identity" ]; then
                echo -e "${GREEN}[Update] Replacing: $installed_filename -> $new_filename${NC}"
                
                name_no_ext=${installed_filename%.jar}
                backup_name="${name_no_ext}-${TIMESTAMP_SUFFIX}.jar"
                
                cp -f "$installed_plugin_path" "$BACKUP_DIR/$TODAY_DIR/$backup_name"
                rm -f "$installed_plugin_path"
                mv -f "$new_jar_path" "$PLUGIN_DIR/$new_filename"
                
                match_found=true
                break
            fi
        done

        if [ "$match_found" = false ]; then
            echo -e "${GREEN}[Install] New Plugin Detected: $new_filename${NC}"
            mv -f "$new_jar_path" "$PLUGIN_DIR/$new_filename"
        fi
    done
    
    rm -f "$UPDATE_DIR"/*.jar
    echo -e "${GREEN}[Updater] All tasks finished.${NC}"
else
    echo -e "${CYAN}[Updater] No pending updates found.${NC}"
fi

# --- [ SERVER STARTUP ] -------------------------------------------------------
echo -e "${YELLOW}[System] Starting Java Process ($SERVER_JAR)...${NC}"
echo "-----------------------------------------------------"

exec $JAVA_BINARY $JAVA_FLAGS -jar "$SERVER_JAR"
