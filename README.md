# kubectl-config-import [![tests](https://github.com/rafi/kubectl-config-import/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/rafi/kubectl-config-import/actions/workflows/test.yml)

> Merge kubeconfigs from a file, stdin, or kubernetes secret.

By default, an interactive fzf selection for namespace and secret is used for
user to select and merge as a kubeconfig. Using `-f` or `--file` you can merge a
file, or simply via stdin.

## Install

- Download:

  ```sh
  curl -LO https://github.com/rafi/kubectl-config-import/raw/refs/heads/master/kubectl-config_import
  chmod ug+x kubectl-config_import
  mv kubectl-config_import ~/.local/bin/
  ```

- Homebrew:

  ```sh
  brew install rafi/tap/kubectl-config-import
  ```

## Usage

```sh
USAGE:
  kubectl config-import [--url str|--jsonpath str] [namespace] [secret] : import from secret
  kubectl config-import [-f|--file str]  : import kubeconfig from file
  cat <FILE> | kubectl config-import     : import kubeconfig from stdin
  kubectl config-import -d, --delete     : delete context
  kubectl config-import -e, --edit       : edit kubeconfig(s)
  kubectl config-import -h, --help       : show this help overview

[options]
  --url str:       set server url when importing secret, e.g. https://localhost:6443
  --jsonpath str:  jsonpath for kubectl get secret, default: {.data.kubeconfig\.conf}
  -f, --file FILE: import specified kubeconfig file
  -d, --delete:    delete context interactively
  -e, --edit:      edit kubeconfig
  -h, --help:      this help overview
```

## Examples

```sh
$ kubectl config-import --help   # help screen

$ kubectl config-import                                # import secret interactively
$ kubectl config-import default remote-cluster-secret  # import namespaced secret

$ kubectl config-import -f ~/Downloads/foo  # import from file
$ cat foo | kubectl config-import           # import from stdin

$ kubectl config-import --delete  # delete context (not cluster/user)
$ kubectl config-import --edit    # edit kubeconfig
```
