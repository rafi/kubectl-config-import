# kubectl-config-import [![tests](https://github.com/rafi/kubectl-config-import/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/rafi/kubectl-config-import/actions/workflows/test.yml)

> Merge kubeconfig's from a file, stdin, or kubernetes secret.

By default, an interactive fzf selection for namespace and Secret is used for
user to select and merge a Secret as a kubeconfig.

Also, using `-f` or `--file` you can merge a file, or simply via stdin.

## Install

Choose one of the following methods:

- Krew:

  ```sh
  kubectl krew install config-import
  ```

- Homebrew:

  ```sh
  brew install rafi/tap/kubectl-config-import
  ```

- Download:

  ```sh
  curl -LO https://github.com/rafi/kubectl-config-import/raw/refs/heads/master/kubectl-config_import
  chmod ug+x kubectl-config_import
  mv kubectl-config_import ~/.local/bin/
  # ensure ~/.local/bin is in your PATH
  ```

## Dependencies

- [fzf](https://github.com/junegunn/fzf)
- [yq](https://github.com/mikefarah/yq) (when importing secret)

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
# help screen
$ kubectl config-import --help

$ kubectl config-import                                # import secret interactively
$ kubectl config-import default remote-cluster-secret  # import namespaced secret

$ kubectl config-import -f ~/Downloads/foo  # import from file
$ cat foo | kubectl config-import           # import from stdin

$ kubectl config-import --delete  # delete context (not cluster/user)
$ kubectl config-import --edit    # edit kubeconfig
```

## Import Methods

### File

```sh
kubectl config-import -f ~/Downloads/foobar.kubeconfig
```

Will import the specified file into the current kubeconfig.

### Stdin

You can also use stdin to import a kubeconfig:

```sh
kubectl config-import < ~/Downloads/foobar.kubeconfig

cat ~/Downloads/foobar.kubeconfig | kubectl config-import
```

### Kubernetes Secret

Kubernetes secret can be imported in different ways:

- Run `kubectl config-import` and interactively select a namespace and secret.
- Run `kubectl config-import namespace` to interactively select a secret.
- Run `kubectl config-import namespace secret` to import a specific secret.

For example, say the following manifest is applied on cluster:

```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: mycluster-kubeconfig
stringData:
  kubeconfig.conf: |
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority-data: LS0tLS…
        server: https://mycluster:6443
      name: mycluster
    contexts:
    - context:
        cluster: mycluster
        user: mycluster-user
      name: mycluster
    users:
    - name: mycluster-user
      user:
        client-certificate-data: LS0tLS…
        client-key-data: LS0tLS…
```

Run `kubectl config-import default mycluster-kubeconfig` to import the
kubeconfig store in the `kubeconfig.conf` key.

## License

MIT License

Copyright (c) 2024 Rafael Bodill
