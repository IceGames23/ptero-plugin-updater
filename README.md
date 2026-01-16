# Minecraft Pterodactyl Auto-Update Wrapper

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Pterodactyl-10529F?style=flat-square&logo=pterodactyl&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

A robust, "set-and-forget" wrapper script designed for **Pterodactyl** Minecraft servers. It automatically handles plugin updates, manages rolling backups, and safeguards your data before the server starts.

> **Originally created for [AfterLands Project](https://www.afterlands.com)**.
> **Support Discord:** https://discord.gg/qGqRxx3V2J

---

## 🚀 Features

* **Smart Plugin Updating**: Detects new `.jar` files in the `auto-updater` folder.
* **Strict Identity Matching**: Differentiates between similar plugins (e.g., `Plugin-v1.jar` vs `PluginAddon-v1.jar`) using regex, preventing accidental deletions.
* **Automatic Backups**: Before updating any plugin, a backup of the old version is created.
* **Rolling Retention**: Automatically deletes backup folders older than **3 days** (configurable) to save disk space.
* **Self-Updating Script**: The script can update itself from this repository (optional toggle for safety).
* **Java Flag Management**: Configure memory and Java flags directly within the script variables.
* **Crash Prevention**: Uses `exec` to seamlessly pass control to Java, preventing Pterodactyl container crashes.

## 📂 Directory Structure

The script automatically manages this structure:

```text
/home/container/
├── plugins/               # Your active plugins
├── auto-updater/          # Drop new updates here (Auto-created)
├── backups-plugins/       # Backups stored by date (Auto-created)
│   ├── 2023-10-27/
│   │   └── WorldEdit-2023-10-27_15-30.jar
│   └── ...
└── auto_update.sh         # This script
```

## 🛠️ Installation

1.  Download `auto_update.sh` and upload it to the root directory of your server (`/home/container`).
2.  Go to the **Startup** tab in your Pterodactyl panel.
3.  Change the **Startup Command** to:
    ```bash
    bash auto_update.sh
    ```
4.  Restart the server.

## ⚙️ Configuration

Open `auto_update.sh` to edit these variables at the top of the file:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `ENABLE_SELF_UPDATE` | Set to `"true"` to allow the script to update itself from GitHub. | `"false"` |
| `BACKUP_RETENTION_DAYS` | Number of days to keep plugin backups. | `3` |
| `JAVA_FLAGS` | Java arguments (Memory, GC, Terminal). | `-Xms128M...` |
| `REMOTE_URL` | The Raw GitHub URL for self-updates. | *https://github.com/IceGames23/ptero-plugin-updater/* |

## 📦 How to Update Plugins

1.  Upload the new version of your plugins (e.g., `EssentialsX-2.20.jar`) into the **`auto-updater`** folder.
2.  Restart the server.
3.  **Done!**
    * The script detects the update.
    * Identifies the old `EssentialsX` in your plugins folder.
    * Backups the old version.
    * Installs the new version.
    * Starts the server.

## 🤝 Credits

* **Developed by:** IceGames
* **Powered by:** [AfterLands](https://www.afterlands.com)
* **Support Discord:** https://discord.gg/qGqRxx3V2J

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.
