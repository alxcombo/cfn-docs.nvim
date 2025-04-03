# 🚀 cfn-docs.nvim

A Neovim plugin to access AWS CloudFormation documentation **without leaving your editor**.  
Stay focused, save time — **zero friction, zero distraction.**

---

## ✨ Features

- 🧠 Detect CloudFormation resource types using LSP
- 🌐 Generate and open documentation URLs
- 🖥️ Open docs in terminal via `w3m` (or just copy the link)
- 📋 Copy doc URLs to clipboard
- 🧩 Fully configurable keymaps
- ⚙️ Idempotent and minimal by design

---

## ⚙️ Installation & Configuration

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  {
    "alxcombo/cfn-docs.nvim",
    config = function()
      require("cfn-docs").setup({
        verbosity = 0,
        use_w3m = true,
        keymaps = {
          show_doc = "<leader>cfs",
          copy_doc = "<leader>cfc",
        },
      })
    end,
  },
}
```

> ℹ️ If `use_w3m = false`, `show_doc` will behave like `copy_doc`, simply copying the URL to your clipboard.
>
> 🔜 In the future, `show_doc` may open the URL in your system browser when `w3m` is disabled.

---

## 🚀 Usage

With your cursor **anywhere** inside a CloudFormation resource:

- `<leader>cfs` → open the doc inside Neovim with `w3m`
- `<leader>cfc` → copy the doc URL to clipboard

Or use the commands:

- `:CfnDocs` → show documentation
- `:CfnDocsCopy` → copy URL

---

## 🧪 Development

### Running Tests

```bash
# Minimal output
make test

# Verbose output
make test-verbose

# Pretty UTF symbols
make test-pretty
```

---

## 📝 License

[MIT](./LICENSE)

---

## 🙌 Contributing

PRs, issues and suggestions welcome!  
Feel free to open an issue or contribute directly. Let's make Neovim even more cloud-friendly ☁️
