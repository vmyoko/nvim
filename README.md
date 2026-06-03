# Advanced NvChad Configuration

Welcome to a highly customized, heavily supercharged version of [NvChad](https://nvchad.com/) tailored for absolute peak productivity. 

We started with the clean, fast base of NvChad and systematically replaced, upgraded, and overhauled its systems to create a fully fledged, cross-platform IDE.

---

## 🛠️ Installation & Prerequisites

To ensure that Mason correctly installs Language Servers (LSPs) and Formatters without throwing errors, you must have the following dependencies installed on your host system. 

*(A custom Neovim Health Check runs on your first startup to verify these are installed!)*

### Windows
Run in an Admin PowerShell:
```powershell
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Python.Python.3.11
winget install GoLang.Go
winget install LLVM.LLVM
winget install GNU.GCC
winget install curl
winget install 7zip.7zip
```

### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install -y build-essential git curl unzip cmake clang gdb golang-go
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
sudo apt install -y python3 python3-pip python3-venv
```

---

## 🚀 The Upgrades

### 1. Custom NvDash & UI
The dashboard has been customized with a dynamic, background-ticking clock that doesn't flicker, along with a localized date display. NvChad's NvimTree has also been upgraded to feature real-time Git status tracking, LSP error integration, and "Follow-Me" mode that always highlights your current file.

### 2. Project Management
Use `:NewProject` and `:ProjectManager` to automatically scaffold code environments (like C++ Makefiles or Go layouts) from templates without leaving Neovim. 

### 3. Debugging (DAP)
Fully configured with UI panels (`nvim-dap-ui`) for step-through debugging. Pre-configured adapters for:
- **C/C++ & Rust** (`codelldb` / `gdb`)
- **Go** (`delve`)
- **C#** (`netcoredbg`)

### 4. Pure Coding Power-Ups
- **Flash.nvim (`s`)**: Teleport anywhere on your screen instantly.
- **Trouble.nvim (`<leader>xx`)**: A beautiful, dedicated panel for exploring project-wide errors, warnings, and references.
- **Todo-comments (`<leader>ft`)**: Highlights `TODO`, `FIXME`, and `HACK` in your code and makes them searchable via Telescope.
- **Autotag**: Writing HTML/JSX? Tags close automatically and rename themselves automatically.

### 5. Git Integration
- **Neogit (`<leader>gs`)**: A Magit clone for extremely fast staging and committing.
- **Diffview (`<leader>gd`)**: A gorgeous, side-by-side diff interface for reviewing your changes.

### 6. The "Bleeding Edge" Plugins
- **Barbecue (Breadcrumbs):** Look at the top of your screen to see your exact context (e.g., `src > main.lua > function init()`).
- **Telescope Undo (`<leader>fu`)**: A visual time machine. Search your undo history and view diffs of your past edits.
- **Persistence (`<leader>qs`)**: Seamless session management. Open a folder, and Neovim restores your exact layout and cursor positions.
- **Refactoring (`<leader>re` in visual mode)**: Extract massive blocks of code into new functions or variables instantly.

---

## ⌨️ Keybindings Quick Reference

| Key | Mode | Action |
| --- | --- | --- |
| `<F5>` | Normal | Start Debugger |
| `<S-F5>` | Normal | Run Code (make run) |
| `-` | Normal | Open Oil.nvim (File Explorer) |
| `<leader>xx` | Normal | Open Trouble (Diagnostics) |
| `s` | Normal | Flash (Jump anywhere) |
| `<leader>fu` | Normal | Telescope Undo History |
| `<leader>ft` | Normal | Search TODO Comments |
| `<leader>qs` | Normal | Restore Session for Project |
| `<leader>re` | Visual | Extract Function (Refactoring) |
