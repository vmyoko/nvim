local creator = require("project_templates.ui.creator")
local core = require("project_templates.core")

return function(on_complete)
  creator.create({
    title = " New  Node.js Project ",
    preview = { "", "   Node.js + TS", "", " Generates:", "  - package.json", "  - tsconfig.json", "  - src/index.ts" },
    fields = { { id = "name", label = "Project Name" } },
  }, function(data)
    local full_path = core.clean_path(data.path, data.name)
    vim.fn.mkdir(full_path, "p")
    
    local cmd_prefix = "cd " .. vim.fn.shellescape(full_path) .. " && "
    vim.fn.system(cmd_prefix .. "npm init -y")
    vim.fn.system(cmd_prefix .. "npm i -D typescript @types/node ts-node")
    vim.fn.system(cmd_prefix .. "npx tsc --init")
    
    vim.fn.mkdir(full_path .. "/src", "p")
    core.write_file(full_path .. "/src/index.ts", "console.log('Hello Node.js!');\n")

    core.setup_git(full_path, data.init_git, data.setup_ci)

    vim.api.nvim_set_current_dir(full_path)
    vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/src/index.ts"))

    if on_complete then
      on_complete({ name = data.name, path = full_path, date = os.date("%Y/%m/%d"), lang = "" })
    end
  end)
end
