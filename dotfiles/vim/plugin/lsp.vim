vim9script

# yegappan/lsp configuration
# Servers are registered declaratively; each entry is added only when its
# binary is on $PATH so absent toolchains stay silent at startup.
def LspServerConfigs(): list<dict<any>>
    var servers: list<dict<any>> = []
    if executable('zls')
        add(servers, {
            name: 'zls',
            filetype: ['zig'],
            path: 'zls',
            args: [],
            rootSearch: ['build.zig', '.git/'],
        })
    endif
    if executable('gopls')
        add(servers, {
            name: 'gopls',
            filetype: ['go', 'gomod', 'gowork', 'gosum'],
            path: 'gopls',
            args: [],
            rootSearch: ['go.work', 'go.mod', '.git/'],
            syncInit: true,
            workspaceConfig: {gopls: {
                staticcheck: true,
                gofumpt: true,
                completeUnimported: true,
                usePlaceholders: true,
            }},
        })
    endif
    if executable('terraform-ls')
        add(servers, {
            name: 'terraform-ls',
            filetype: ['terraform', 'terraform-vars'],
            path: 'terraform-ls',
            args: ['serve'],
            rootSearch: ['main.tf', 'versions.tf', 'providers.tf', '.terraform/', '.git/'],
        })
    endif
    if executable('rust-analyzer')
        add(servers, {
            name: 'rust-analyzer',
            filetype: ['rust'],
            path: 'rust-analyzer',
            args: [],
            rootSearch: ['Cargo.toml', '.git/'],
            syncInit: true,
        })
    endif
    if executable('pylsp')
        add(servers, {
            name: 'pylsp',
            filetype: ['python'],
            path: 'pylsp',
            args: [],
            rootSearch: ['pyproject.toml', 'setup.cfg', 'requirements.txt', '.git/'],
        })
    endif
    if executable('nixd')
        add(servers, {
            name: 'nixd',
            filetype: ['nix'],
            path: 'nixd',
            args: [],
            rootSearch: ['flake.nix', 'shell.nix', 'default.nix', '.git/'],
        })
    endif
    if executable('yaml-language-server')
        # Schema-aware validation/completion for Kubernetes manifests and
        # any YAML with a schemastore.org match (GitHub workflows, Chart.yaml,
        # docker-compose, ...). Style linting stays with ALE/yamllint and
        # formatting with ALE/yamlfmt: the server's own prettier-based
        # formatter is disabled so there is a single format-on-save path.
        # Helm templates are unaffected: polyglot gives them ft=helm.
        add(servers, {
            name: 'yamlls',
            filetype: ['yaml'],
            path: 'yaml-language-server',
            args: ['--stdio'],
            rootSearch: ['.git/'],
            workspaceConfig: {
                yaml: {
                    format: {enable: false},
                    validate: true,
                    hover: true,
                    completion: true,
                    schemaStore: {
                        enable: true,
                        url: 'https://www.schemastore.org/api/json/catalog.json',
                    },
                    # The reserved `kubernetes` keyword resolves to the
                    # builtin K8s API schema. Manifests have no standard
                    # filename, so association is by directory glob.
                    # Caveat: kustomization/Chart files inside these trees
                    # get the K8s schema too; override per file with a
                    # modeline `# yaml-language-server: $schema=<url>`.
                    schemas: {
                        kubernetes: [
                            '**/kubernetes/**/*.yaml',
                            '**/k8s/**/*.yaml',
                            '**/manifests/**/*.yaml',
                        ],
                    },
                },
                redhat: {telemetry: {enabled: false}},
            },
        })
    endif
    return servers
enddef

def WarnMissingServer(bin: string)
    if !executable(bin)
        echohl WarningMsg
        echom bin .. ' not found in $PATH; LSP features disabled for this buffer.'
        echohl None
    endif
enddef

augroup enk_lsp
    autocmd!
    autocmd User LspSetup g:LspOptionsSet({autoComplete: true, autoHighlight: true})
    autocmd User LspSetup g:LspAddServer(LspServerConfigs())
    autocmd FileType zig call WarnMissingServer('zls')
    autocmd FileType go,gomod,gowork,gosum call WarnMissingServer('gopls')
    autocmd FileType terraform,terraform-vars call WarnMissingServer('terraform-ls')
augroup END

# gopls (gofumpt: true above) is the single Go format-on-save path;
# vim-go's own autosave formatting is disabled via g:go_fmt_autosave = 0
augroup go_lsp_format_on_save
    autocmd!
    autocmd BufWritePre *.go if exists(':LspFormat') == 2 | execute 'LspFormat' | endif
augroup END
