# config.nu
#
# Installed by:
# version = "0.113.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

$env.config = {

    show_banner: false

    hooks: {
        pre_prompt: [{ ||
            let base_name = $env.USER
            let current_dir = (pwd | path basename)
            let title = if (($env.PWD | path expand) == ($env.HOME | path expand)) {
                $base_name
            } else {
                $"($base_name):($current_dir)"
            }
            print -n $"(ansi title)($title)(ansi string_terminator)"
        }]
    }
}
