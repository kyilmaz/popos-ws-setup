# Pop!_OS Workstation Setup Script

This script automates the setup of a complete development and data science workstation on a fresh installation of Pop!_OS 22.04 LTS. It is specifically tailored for AI/ML development, but is also excellent for general-purpose programming.

## What it Does

The script performs the following actions:

- **System Maintenance:** Updates and upgrades all system packages, removes `snapd`, and handles potential conflicts with `PackageKit`.
- **Performance Optimization:**
    - Installs and configures `tuned` with the `throughput-performance` profile.
    - Adjusts kernel parameters (`swappiness`, `vfs_cache_pressure`) for better performance.
    - Disables automatic suspend/sleep to keep the workstation running.
- **Essential Tools:** Installs a wide range of development and system tools, including `git`, `build-essential`, `curl`, `htop`, `neofetch`, `remmina`, `vlc`, and more.
- **Development Environments:**
    - **Programming Languages:** Installs the latest versions of Rust, Go, and Node.js.
    - **Python/AI Stack:** Installs the Anaconda Python distribution, CUDA Toolkit, and key libraries like PySpark, PyTorch, TensorFlow, Transformers, and scikit-learn.
    - **Editors:** Installs Visual Studio Code.
- **Containerization:**
    - Installs and configures Docker, Docker Compose, Rancher Desktop, and Minikube.
    - Adds the current user to the `docker` group.
- **Shell Configuration:** Adds useful aliases and sets up the shell environment for a better workflow.

## How to Use

1.  **Download the script:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/popos-ws-setup.git
    cd popos-ws-setup
    ```

2.  **Make it executable:**
    ```bash
    chmod +x popos-ws-setup.sh
    ```

3.  **Run it:**
    **IMPORTANT:** Do NOT run this script as root. It will ask for `sudo` password when needed.
    ```bash
    ./popos-ws-setup.sh
    ```

4.  **Reboot:** After the script completes, reboot your system for all changes to take effect.

## Disclaimer

This script is provided as-is. While it is designed to be safe, always review a script before running it on your system. The author is not responsible for any data loss or system instability.
