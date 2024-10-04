# kubectl-config-import

> Merge kubeconfigs stored as Kubernetes secrets or files.

With this plugin you can merge kubeconfigs into your main config. By default, an
interactive fzf selection for namespace and secret is used for user to select
and merge as a kubeconfig. Also, using `-f` or `--file` you can merge a file, or
use stdin.

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
Command:
  kubectl config-import [--url str|--jsonpath str] [namespace] [secret name]
  kubectl config-import [-f|--file str]
  cat file | kubectl config-import
  kubectl config-import -d|--delete
  kubectl config-import -e|--edit

[options]
  --url str:       set server url when importing secret, e.g. https://localhost:6443
  --jsonpath str:  jsonpath for kubectl get secret, default: {.data.kubeconfig\.conf}
  -f, --file str:  import specified kubeconfig file
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
