return {
  {
    "ibhagwan/fzf-lua",
    keys = {
      {
        "<leader>sg",
        function()
          require("fzf-lua").grep_project()
        end,
        desc = "Grep (fzf fuzzy)",
      },
    },
  },
}
