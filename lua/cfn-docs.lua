local M = {}
-- local http = require("plenary.curl")
-- local htmlparser = require("htmlparser") -- Vous pouvez installer un parseur HTML Lua

M.config = {
	verbosity = 0, -- 0 = aucun log, 1 = essentiel, 2 = détaillé
	use_w3m = true, -- Utiliser w3m pour afficher la doc (sinon juste copier l'URL)
	keymaps = {
		show_doc = "<leader>co",
		copy_doc = "<leader>cd",
	},
}

function M.setup(user_config)
	-- Fusionner les options utilisateur avec les valeurs par défaut
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

	-- Appliquer les keymaps si elles sont activées
	if M.config.keymaps.show_doc then
		vim.api.nvim_set_keymap(
			"n",
			M.config.keymaps.show_doc,
			':lua require("cfn-docs").show_documentation()<CR>',
			{ noremap = true, silent = true, desc = "Show CloudFormation doc URL" }
		)
	end

	if M.config.keymaps.copy_doc then
		vim.api.nvim_set_keymap(
			"n",
			M.config.keymaps.copy_doc,
			':lua require("cfn-docs").copy_cloudformation_doc_url()<CR>',
			{ noremap = true, silent = true, desc = "Copy CloudFormation doc URL" }
		)
	end
end

function M.send_notification(message, level, opts)
	level = level or "info"
	opts = opts or {}

	-- Utilisation de la notification native de Neovim
	vim.notify(message, vim.log.levels[string.upper(level)] or vim.log.levels.INFO, {
		title = opts.title or "Notification",
		timeout = opts.timeout or 3000,
	})
end

local function log(message, level)
	level = level or 1 -- Niveau par défaut = 1
	if (M.config.verbosity or 0) >= level then -- Évite la comparaison avec nil
		print(message)
	end
end

function M.show_documentation()
	local url = M.generate_cloudformation_doc_url()
	if M.config.use_w3m then
		vim.cmd("W3mVSplit " .. url)
	else
		M.send_notification("Documentation URL: " .. url, "info")
	end
end

vim.api.nvim_create_user_command("CfnDoc", function()
	M.show_documentation()
end, { desc = "Show CloudFormation documentation for resource under cursor" })

-- Fonction privée pour récupérer le type de ressource sous le curseur
local function get_resource_type()
	-- Récupère les paramètres de position pour la requête
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	local position_encoding = (clients[1] and clients[1].offset_encoding) or "utf-16"

	-- local params = vim.lsp.util.make_position_params(0, { position_encoding = "utf8" })
	local params = vim.lsp.util.make_position_params(0, position_encoding)
	-- Envoie une requête LSP avec les paramètres complets
	local result = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)

	if not result or vim.tbl_isempty(result) then
		log("No response from LSP or empty result.", 1)
		return nil
	end

	local cursor_line = params.position.line + 1
	log("Cursor Line: " .. cursor_line, 2) -- Affiche la ligne actuelle du curseur

	-- Fonction pour trouver la ressource sous le curseur
	local function find_resource_at_cursor(symbols)
		for _, symbol in ipairs(symbols or {}) do
			local range = symbol.range or symbol.selectionRange
			if range and range.start.line + 1 <= cursor_line and range["end"].line + 1 >= cursor_line then
				log("Cursor is inside symbol: " .. symbol.name, 2)

				-- Si le symbole est "Resources", chercher plus profondément
				if symbol.name == "Resources" and symbol.children then
					return find_resource_at_cursor(symbol.children)
				end

				-- Retourne uniquement si c'est une ressource individuelle
				if symbol.children then
					return symbol
				end
			end
		end
		return nil
	end

	-- Fonction pour trouver le champ Type dans une ressource donnée
	local function find_type_in_resource(resource)
		for _, child in ipairs(resource.children or {}) do
			if child.name == "Type" then
				log("Found Type: " .. (child.detail or child.name), 2)
				return child.detail or child.name
			end
		end
		return nil
	end

	-- Parcourt les résultats pour trouver la ressource et son champ Type
	for _, res in pairs(result) do
		if res.result then
			local resource = find_resource_at_cursor(res.result)
			if resource then
				log("Found resource: " .. resource.name, 1)
				-- Une fois la ressource trouvée, cherchez le champ Type
				return find_type_in_resource(resource)
			end
		end
	end

	log("Type not found in current resource.", 1)
	return nil
end

function M.generate_cloudformation_doc_url()
	local resource_type = get_resource_type()
	if not resource_type then
		log("Resource Type not found.", 1)
		M.send_notification("Resource Type not found.", "warn")
		return
	end

	-- Supprimer le préfixe "AWS::" si présent
	local type_without_prefix = resource_type:gsub("^AWS::", "")
	-- Transformer le type en chemin pour l'URL
	local type_path = type_without_prefix:gsub("::", "-"):lower()
	local url = "https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-" .. type_path .. ".html"

	local function validate_url(url)
		local http = require("plenary.curl")
		local response = http.get({ url = url, timeout = 3000 })
		return response and response.status == 200
	end

	if not validate_url(url) then
		log("Invalid or inaccessible URL: " .. url, 1)
		return
	end

	return url
end

-- Fonction pour copier l'URL CloudFormation dans le presse-papiers
function M.copy_cloudformation_doc_url()
	local url = M.generate_cloudformation_doc_url()
	if url then
		vim.fn.system("win32yank.exe -i", url) -- Copier dans le presse-papiers
		M.send_notification("Copied URL: " .. url, "info")
	end
end

vim.opt.foldcolumn = "0"
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""

vim.opt.foldnestmax = 3
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

local function close_all_folds()
	vim.api.nvim_exec2("%foldc!", { output = false })
end
local function open_all_folds()
	vim.api.nvim_exec2("%foldo!", { output = false })
end

vim.keymap.set("n", "<leader>zs", close_all_folds, { desc = "[s]hut all folds" })
vim.keymap.set("n", "<leader>zo", open_all_folds, { desc = "[o]pen all folds" })

return M
