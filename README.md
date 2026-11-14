# simple-note.nvim

SNn：vault / 日记 / 新建 / 模板 / frontmatter / reload。

## 命令

- `:Snote vault`
- `:Snote today [input]`
- `:Snote daily [n] [input]`
- `:Snote homepage`
- `:Snote frontmatter`
- `:Snote new [title]`
- `:Snote ntemplate <template> [title]`（别名 `new_from_template`）
- `:Snote template <template>`
- `:Snote reload`

## 安装（开发期）

```lua
{
  dir = vim.fn.expand "~/.config/nvim/.works/simple-note.nvim",
  name = "simple-note.nvim",
  main = "simple-note",
  lazy = false,
  opts = {
    vault = vim.fn.expand "~/SCH",
  },
}
```

`welcome = false` 时改成 `lazy = true, cmd = { "Snote" }`。

## 配置

`vault`、`homepage`、`welcome`、`welcome_action`、`welcome_key`、`welcome_label`、
`welcome_icon`、`notice_missing_welcome`、`daily_dir`、`templates_dir`、
`daily_template`、`defaultnew_template`、`frontmatter_extensions`、
`substitute_key`、`date_format`、`time_format`、`timestamp_format`。

## 测试

```sh
nvim --headless -i NONE -c "luafile /path/to/tests/p1_smoke.lua" +qa
```

测试使用临时 vault，不触碰真实笔记库。
