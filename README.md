[**Tiếng Việt**](file:///home/dwcks/Projects/gtranslate/README.vi.md) | **English**

# gtranslate.nvim

A lightweight and powerful Neovim plugin for translating text/documentation directly in the editor, supporting both Google Translate and Gemini AI.

## ✨ Features

- **Quick Translation (Gtrans)**: Uses Google Translate API (free, no key required).
- **Smart Translation (Atrans)**: Uses Gemini AI for more accurate document translation, preserving context.
- **Automatic Language Detection**: Automatically identifies the source language.
- **Syntax Highlighting**: Translations are displayed in a split window with correct highlighting according to the `filetype` of the code (e.g., translating lua code in docs will highlight the result as lua).
- **Float/Hover docs support**: Can translate directly from hover lsp windows, noice, etc. (Automatically jumps back to the main window to open the split).

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "your-username/gtranslate", -- Change after you push to GitHub
    config = function()
        require("gtranslate").setup({
            target_lang = "vi", -- Default target language
            gemini_api_key = os.getenv("GEMINI_API_KEY"), -- Or paste your key directly here
            gemini_model = "gemini-2.0-flash", -- Gemini model to use
            google_url = "https://translate.googleapis.com/translate_a/single", -- Proxy/Custom Google API
            gemini_url = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", -- Custom Gemini API URL
            width_percent = 0.4, -- Results window width (40%)
        })
    end,
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'your-username/gtranslate'
```

## ⚙️ Configuration

Below are the default options:

```lua
require("gtranslate").setup({
  source_lang = "auto", -- Source language code (e.g., "en", "ja")
  target_lang = "vi",   -- Target language code
  width_percent = 0.5,  -- Window width (0.1 to 0.9)
  gemini_api_key = nil, -- API Key for Atrans command
  gemini_model = "gemini-2.0-flash", -- Gemini model to use
  google_url = "https://translate.googleapis.com/translate_a/single", -- Custom Google API URL
  gemini_url = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", -- Custom Gemini API URL
})
```

## 🐛 Debug

```lua
nvim --clean -u minimal.lua
```

### How to get Gemini API Key
Visit [Google AI Studio](https://aistudio.google.com/app/apikey) to create a free key.

## 🚀 Usage

1. **Visual Mode**: Highlight the text you want to translate.
2. **Commands**:
   - `:Gtrans [target_lang]`: Translate using Google Translate. 
     - Example: `:Gtrans en` (translate to English), defaults to (`vi`) if empty.
   - `:Atrans [target_lang]`: Translate using Gemini AI (Requires API Key).
     - Example: `:Atrans ja` (translate to Japanese using AI).

3. **Results Window**:
   - Press `q` to quickly close the translation result window.

## ⌨️ Keybindings (Recommended)

You can add keybindings to your config for faster operation:

```lua
-- Quick translation with Google
vim.keymap.set("v", "<leader>Gt", ":'<,'>Gtrans<CR>", { desc = "Google Translate" })
-- Precise translation with AI
vim.keymap.set("v", "<leader>Ga", ":'<,'>Atrans<CR>", { desc = "Gemini AI Translate" })
```

## 🛠️ Requirements

- Neovim >= 0.8.0 (Recommend 0.10+ for best text extraction).
- `curl` installed on your system.

## License
MIT
