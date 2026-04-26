-- Set the build command to scala-cli compile
-- We use --color false to make parsing easier
vim.opt.makeprg = "scala-cli compile % 2>&1 \\| ansifilter"

-- Define the error format to match scala-cli output
vim.opt.errorformat = {
    "%E[error] %f:%l:%c",
    "%C[error] %m",
    "%-G[error] %p^",
    "%-G%.%#"
}
