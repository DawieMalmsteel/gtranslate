**Tiếng Việt** | [**English**](README.md)

# gtranslate.nvim

Một plugin Neovim nhẹ nhàng và mạnh mẽ để dịch văn bản/tài liệu ngay trong trình soạn thảo, hỗ trợ cả Google Translate và Gemini AI.

## ✨ Tính năng

- **Dịch nhanh (Gtrans)**: Sử dụng Google Translate API (miễn phí, không cần key).
- **Dịch thông minh (Atrans)**: Sử dụng Gemini AI để dịch tài liệu chuẩn xác hơn, giữ nguyên ngữ cảnh.
- **Giải thích code (Etrans)**: Sử dụng Gemini AI để vừa dịch vừa giải thích chi tiết đoạn code/văn bản.
- **Tự động nhận diện ngôn ngữ**: Tự động xác định ngôn ngữ nguồn.
- **Highlight cú pháp**: Bản dịch được hiển thị trong cửa sổ split với highlight đúng theo `filetype` của code (ví dụ: bôi đen code lua trong docs sẽ hiện kết quả highlight lua).
- **Hỗ trợ Float/Hover docs**: Có thể dịch trực tiếp từ các cửa sổ hover lsp, noice, v.v. (Tự động nhảy về cửa sổ chính để mở split).

## 📦 Cài đặt

Sử dụng [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "DawieMalmsteel/gtranslate",
    config = function()
        require("gtranslate").setup({
            target_lang = "vi", -- Ngôn ngữ đích mặc định
            gemini_api_key = os.getenv("GEMINI_API_KEY"), -- Hoặc dán trực tiếp key vào đây
            gemini_model = "gemini-2.0-flash", -- Model Gemini sử dụng
            google_url = "https://translate.googleapis.com/translate_a/single", -- URL API Google tùy chỉnh
            gemini_url = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", -- URL API Gemini tùy chỉnh
            width_percent = 0.4, -- Độ rộng cửa sổ kết quả (40%)
        })
    end,
}
```

Sử dụng [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'DawieMalmsteel/gtranslate'
```

## ⚙️ Cấu hình

Dưới đây là các tùy chọn mặc định:

```lua
require("gtranslate").setup({
  source_lang = "auto", -- Mã ngôn ngữ nguồn (ví dụ: "en", "ja")
  target_lang = "vi",   -- Mã ngôn ngữ đích
  width_percent = 0.5,  -- Chiều rộng cửa sổ (0.1 đến 0.9)
  gemini_api_key = nil, -- API Key cho lệnh Atrans
  gemini_model = "gemini-2.0-flash", -- Model Gemini sử dụng
  google_url = "https://translate.googleapis.com/translate_a/single", -- URL API Google tùy chỉnh
  gemini_url = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", -- URL API Gemini tùy chỉnh
})
```

## 🐛 Debug

```lua
nvim --clean -u minimal.lua
```

### Cách lấy Gemini API Key
Truy cập [Google AI Studio](https://aistudio.google.com/app/apikey) để tạo key miễn phí.

## 🚀 Cách sử dụng

1. **Visual Mode**: Bôi đen đoạn văn bản bạn muốn dịch.
2. **Lệnh**:
   - `:Gtrans [target_lang]`: Dịch bằng Google Translate. 
     - Ví dụ: `:Gtrans en` (dịch sang tiếng Anh), nếu không điền sẽ lấy mặc định (`vi`).
   - `:Atrans [target_lang]`: Dịch bằng Gemini AI (Yêu cầu API Key).
     - Ví dụ: `:Atrans ja` (dịch sang tiếng Nhật bằng AI).
   - `:Etrans [target_lang]`: Vừa dịch vừa giải thích bằng Gemini AI (Yêu cầu API Key).
     - Ví dụ: `:Etrans vi` (dịch và giải thích bằng tiếng Việt).

3. **Cửa sổ kết quả**:
   - Nhấn `q` để đóng nhanh cửa sổ kết quả dịch.

## ⌨️ Phím tắt (Khuyên dùng)

Bạn có thể thêm các phím tắt vào config để thao tác nhanh hơn:

```lua
-- Dịch nhanh bằng Google
vim.keymap.set("v", "<leader>Gt", ":'<,'>Gtrans<CR>", { desc = "Dịch Google" })
-- Dịch chuẩn bằng AI
vim.keymap.set("v", "<leader>Ga", ":'<,'>Atrans<CR>", { desc = "Dịch Gemini AI" })
-- Dịch và giải thích code
vim.keymap.set("v", "<leader>Ge", ":'<,'>Etrans<CR>", { desc = "Dịch & Giải thích" })
```

## 🛠️ Yêu cầu

- Neovim >= 0.8.0 (Khuyên dùng 0.10+ để lấy text chuẩn nhất).
- `curl` được cài đặt trong hệ thống.

## License
MIT
