#!/usr/bin/env bash
#
# kubectl-import - export Kubernetes secret as kubeconfig file.
#
# Requires yq, https://github.com/mikefarah/yq
# and fzf, https://github.com/junegunn/fzf
#
# Maintainer: Rafael Bodill
#
# 2023-08-09 - add namespace selection
# 2022-09-09 - initial version
set -eu

KUBECONFIG="${KUBECONFIG:=$HOME/.kube/config}"
KUBECONFIG_EXTRA_DIR="$HOME/.kube/configs"

function usage() {
	cat <<EOF
USAGE: $(basename "$0") [options] [namespace] [secret name]

KUBECONFIG="~${KUBECONFIG#"$HOME"}"
KUBECONFIG_EXTRA_DIR="~${KUBECONFIG_EXTRA_DIR#"$HOME"}"

[options]
	--url:           apiserver url, e.g. https://localhost:6443
	-l, --list:      show all available kubeconfigs
	-h, --help:      this help overview
EOF
}

function list_kubeconfigs() {
	current_kubeconfig
	echo "kubeconfigs:"
	get_all_kubeconfigs
}

function current_kubeconfig() {
	echo -n "Current kubeconfig: "
	basename "$(readlink -f "$KUBECONFIG")" | sed 's,%,/,g;s/.yaml//g'
	echo
}

function get_all_kubeconfigs() {
	find -s "$KUBECONFIG_EXTRA_DIR" -type f -execdir echo '{}' ';' \
		| sed 's,%,/,g;s/.yaml//g'
}

function select_namespace() {
	# Use fzf to prompt user to select namespace.
	kubectl get namespaces \
		| fzf --exit-0 --ansi --info=right --height=50% --no-preview \
				--header-lines 1 --margin=1,3,0,3 --scrollbar=▏▕ \
				--prompt 'Select namespace to use as kubeconfig> ' \
		| awk '{print $1}'
}

function select_secret() {
	# Use fzf to prompt user to select secret.
	kubectl get secrets -n "$__namespace" --field-selector type=Opaque \
		| fzf --exit-0 --ansi --info=right --height=50% --no-preview \
				--header-lines 1 --margin=1,3,0,3 --scrollbar=▏▕ \
				--prompt 'Select secret to use as kubeconfig> ' \
		| awk '{print $1}'
}

function validate_secret() {
	if ! kubectl get secret -n "$__namespace" "$__secret_name" 1>/dev/null; then
		echo >&2 "Secret '${__secret_name}' doesn't exist in __namespace '${__namespace}', aborting."
		exit 3
	fi
}

function save_secret_as_kubeconfig() {
	# Concat final path name
	local context_name; context_name="$(kubectl config current-context)"
	local file_name="${context_name}%${__namespace}%${__secret_name}.yaml"
	local file_path="${KUBECONFIG_EXTRA_DIR}/${file_name}"
	[ -d "$KUBECONFIG_EXTRA_DIR" ] || mkdir -p "$KUBECONFIG_EXTRA_DIR"

	# Get secret contents, decode and save as file.
	kubectl get secret "$__secret_name" -n "$__namespace" \
		-o jsonpath='{.data.kubeconfig\.conf}' | base64 --decode > "${file_path}"

	# Update cluster server URL, if user has requested to.
	if [ -n "$__apiserver_url" ]; then
		yq -i ".clusters[].cluster.server = \"${__apiserver_url}\"" "${file_path}"
	fi

	# Change context name to be more verbose.
	context_name="${context_name}-${__namespace}-${__secret_name}"
	yq -i \
		".contexts[].name = \"$context_name\", .current-context = \"$context_name\"" \
		"${file_path}"

	# Check if kubectl-switch is present and use to switch to this kubeconfig.
	if hash kubectl-switch 2>/dev/null; then
		kubectl-switch "${file_name}"
	fi
}

function main() {
	local __namespace='' __secret_name='' __apiserver_url=''
	local positional=()

	while [ $# -gt 0 ]; do
		case "$1" in
		--url) shift; __apiserver_url="$1";;
		-l|--list) list_kubeconfigs; exit;;
		-h|--help) usage; exit;;
		-*) echo "Warning, unrecognized option ${1}" >&2; exit 1;;
		*) positional+=("${1}");;
		esac
		shift
	done
	set -- "${positional[@]}"

	__namespace="${1:-}"
	__secret_name="${2:-}"

	if [ -z "$__namespace" ]; then
		__namespace="$(select_namespace)"
		if [ -z "$__namespace" ]; then
			echo >&2 'No namespace selected, aborting.'
			exit 2
		fi
	fi

	if [ -z "$__secret_name" ]; then
		__secret_name="$(select_secret)"
		if [ -z "$__secret_name" ]; then
			echo >&2 'No secret selected, aborting.'
			exit 2
		fi
	fi

	validate_secret
	save_secret_as_kubeconfig
}

main "$@"

# vim: set ts=2 sw=0 tw=80 noet :
