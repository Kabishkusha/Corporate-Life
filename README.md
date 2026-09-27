# Toolchain Checker

Animated environment checker for:

* Git
* Node.js
* npm

This repository provides separate scripts for **Ubuntu/Debian-based Linux** and **Windows**.

---

## Files

```text
.
├── check-tools.sh
├── check-tools.ps1
└── README.md
```

### Ubuntu / Debian

`check-tools.sh`

Uses `apt-get` to check, install, and update Git, Node.js, and npm.

### Windows

`check-tools.ps1`

Uses `winget` to check, install, and update Git, Node.js, and npm.

---

# Ubuntu / Debian

## 1. Make the script executable

Open a terminal in the project directory:

```bash
chmod +x check-tools.sh
```

## 2. Run the checker

```bash
./check-tools.sh
```

The script will:

1. Update the APT package index
2. Check Git
3. Check Node.js
4. Check npm
5. Install missing tools
6. Update outdated tools
7. Display the installed versions

The script automatically requests `sudo` privileges when required.

---

# Windows

## 1. Open PowerShell

Navigate to the project directory:

```powershell
cd path\to\project
```

## 2. Run the checker

```powershell
.\check-tools.ps1
```

The Windows script requires **Windows Package Manager (`winget`)**.

If PowerShell blocks script execution, run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Then run:

```powershell
.\check-tools.ps1
```

---

# What Gets Checked?

| Tool                  | Ubuntu / Debian | Windows |
| --------------------- | :-------------: | :-----: |
| Git                   |        ✓        |    ✓    |
| Node.js               |        ✓        |    ✓    |
| npm                   |        ✓        |    ✓    |
| Install missing tools |        ✓        |    ✓    |
| Update tools          |        ✓        |    ✓    |
| Package manager       |       APT       |  winget |
| Node.js target        |       20+       |   20+   |

The scripts check whether Node.js is below version 20 and update it when necessary.

---

# Verify Installation

After running the checker, verify the versions manually.

## Git

```bash
git --version
```

## Node.js

```bash
node --version
```

## npm

```bash
npm --version
```

The same commands can be used in Windows PowerShell:

```powershell
git --version
node --version
npm --version
```

---

# Troubleshooting

## Ubuntu: `apt-get` not found

The Linux script requires `apt-get` and is intended for Ubuntu/Debian-based systems.

Check your distribution:

```bash
cat /etc/os-release
```

---

## Windows: `winget` not found

Check whether `winget` is installed:

```powershell
winget --version
```

The Windows script will stop if `winget` is unavailable.

---

## PowerShell execution policy error

Run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Then:

```powershell
.\check-tools.ps1
```

---

# Quick Start

## Ubuntu / Debian

```bash
chmod +x check-tools.sh
./check-tools.sh
```

## Windows

```powershell
.\check-tools.ps1
```

---

# Toolchain

```text
             TOOLCHAIN CHECKER
                    │
          ┌─────────┴─────────┐
          │                   │
       Ubuntu               Windows
          │                   │
        apt-get             winget
          │                   │
          └─────────┬─────────┘
                    │
          ┌─────────┼─────────┐
          │         │         │
         Git      Node.js     npm
          │         │         │
          └─────────┼─────────┘
                    │
             Ready to Develop
```
