-- nvim-cmp minimal setup
local ok_cmp, cmp = pcall(require, 'cmp')
if not ok_cmp then return end

local ok_snip, luasnip = pcall(require, 'luasnip')
if ok_snip then require('luasnip.loaders.from_vscode').lazy_load() end

cmp.setup({
  snippet = {
    expand = function(args)
      if ok_snip then luasnip.lsp_expand(args.body) end
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'path' }, { name = 'buffer' } }),
})
