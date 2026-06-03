local M = {}

M.run = function()
  -- Check if already ran
  local state_file = vim.fn.stdpath("state") .. "/healthcheck_done"
  if vim.uv.fs_stat(state_file) then
    return
  end

  local missing = {}
  local is_win = vim.fn.has("win32") == 1
  local tools = {}

  if is_win then
    tools = {
      { cmd = "git", name = "Git" },
      { cmd = "npm", name = "Node.js (npm)" },
      { cmd = "python", name = "Python", alt = "python3" },
      { cmd = "go", name = "Go" },
      { cmd = "gcc", name = "MinGW Compiler (gcc)", alt = "clang" },
      { cmd = "unzip", name = "Unzip (or 7z)", alt = "7z" },
      { cmd = "curl", name = "Curl" },
      { cmd = "rg", name = "Ripgrep" },
      { cmd = "fd", name = "Fd" }
    }
  else
    tools = {
      { cmd = "git", name = "Git" },
      { cmd = "npm", name = "Node.js (npm)" },
      { cmd = "python", name = "Python", alt = "python3" },
      { cmd = "go", name = "Go" },
      { cmd = "gcc", name = "C Compiler (gcc/clang)", alt = "clang" },
      { cmd = "unzip", name = "Unzip" },
      { cmd = "curl", name = "Curl" },
      { cmd = "rg", name = "Ripgrep" },
      { cmd = "fd", name = "Fd (fd-find)", alt = "fdfind" }
    }
  end

  for _, tool in ipairs(tools) do
    if vim.fn.executable(tool.cmd) == 0 then
      if tool.alt and vim.fn.executable(tool.alt) == 1 then
        -- alt exists, we're fine
      else
        table.insert(missing, tool.name)
      end
    end
  end

  if #missing > 0 then
    -- Wait a bit for UI to settle, then notify
    vim.defer_fn(function()
      local os_hint = vim.fn.has("win32") == 1 and "Windows Package Manager (Winget, Scoop, Choco)" or "your Linux Package Manager (APT, DNF, Pacman, etc.)"
      local msg = "System tools are missing from your PATH.\nPlease install them using " .. os_hint .. " or check README.md:\n\n"
      for _, m in ipairs(missing) do
        msg = msg .. "- " .. m .. "\n"
      end
      vim.notify(msg, vim.log.levels.WARN, { title = "System Health Check", timeout = 10000 })
    end, 3000)
  else
    -- Everything is fine, mark as done
    local f = io.open(state_file, "w")
    if f then
      f:write("ok")
      f:close()
    end
    vim.defer_fn(function()
      vim.notify("All system dependencies are installed! Mason will now work correctly.", vim.log.levels.INFO, { title = "System Health Check" })
    end, 3000)
  end
end

return M
