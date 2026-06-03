local M = {}

M.get_projects = function()
  local path = vim.fn.stdpath("config") .. "/data/projects.json"
  local file = io.open(path, "r")
  if not file then
    return {}
  end
  local content = file:read("*a")
  file:close()
  local ok, parsed = pcall(vim.json.decode, content)
  return (ok and type(parsed) == "table") and parsed or {}
end

M.save_projects = function(projects)
  local data_dir = vim.fn.stdpath("config") .. "/data"
  if vim.fn.isdirectory(data_dir) == 0 then vim.fn.mkdir(data_dir, "p") end
  local path = data_dir .. "/projects.json"
  local file = io.open(path, "w")
  if file then
    file:write(vim.json.encode(projects))
    file:close()
  end
end

M.add_project = function(project)
  local projects = M.get_projects()
  table.insert(projects, project)
  M.save_projects(projects)
end

M.clean_path = function(base, name)
  local path = base .. "/" .. name
  return path:gsub("//", "/")
end

M.write_file = function(path, content)
  local file = io.open(path, "w")
  if file then
    file:write(content)
    file:close()
  end
end

M.read_template = function(lang, file_name)
  local configPath = vim.fn.stdpath("config") .. "/lua/project_templates/templates/"
  local path = configPath .. lang .. "/" .. file_name
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    return content
  end
  return "Template file not found: " .. path
end

M.setup_git = function(path, init_git)
  if not init_git then return end

  print("Initializing Git...")
  vim.fn.system("cd " .. vim.fn.shellescape(path) .. " && git init")
  
  -- Basic gitignore
  local gitignore = "build/\ntarget/\nnode_modules/\nvenv/\n__pycache__/\n.env\n.vscode/\n"
  M.write_file(path .. "/.gitignore", gitignore)
end

return M
