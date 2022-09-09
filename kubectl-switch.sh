#!/usr/bin/env bash
#
# kubectl-switch - switch between kubeconfig collections using a symlink.
#
# Requires fzf, see https://github.com/junegunn/fzf
#
# 2023-08-09 - add delete/edit
# 2022-09-09 - initial version
set -eu

KUBECONFIG="${KUBECONFIG:=$HOME/.kube/config}"
KUBECONFIG_EXTRA_DIR="$HOME/.kube/configs"

function usage() {
	cat <<EOF
USAGE: kubectl switch [-hlcde] | [<name>]

KUBECONFIG="~${KUBECONFIG#"$HOME"}"
KUBECONFIG_EXTRA_DIR="~${KUBECONFIG_EXTRA_DIR#"$HOME"}"

[options]
	-l, --list:      show all available kubeconfigs
	-c, --contexts:  show all available contexts
	-d, --delete:    delete selected kubeconfig
	-e, --edit:      edit selected kubeconfig
	-h, --help:      this help overview

Notice: You should create an initial kubeconfig in your '$KUBECONFIG_EXTRA_DIR' directory before running this command.
EOF
}

function list_contexts() {
	echo -n "Current kubeconfig: "
	current_kubeconfig
	echo
	kubectl config get-contexts
}

function list_kubeconfigs() {
	echo -n "Current kubeconfig: "
	current_kubeconfig
	echo
	get_all_kubeconfigs
}

function current_kubeconfig() {
	basename "$(readlink -f "$KUBECONFIG")" | sed 's,%,/,g;s/.yaml//g'
}

function get_all_kubeconfigs() {
	local cur cfgs yellow normal

	yellow=$(tput setaf 3 || true)
	normal=$(tput sgr0 || true)
	cur="$(current_kubeconfig)"
	cfgs="$(find -s "$KUBECONFIG_EXTRA_DIR" -type f -execdir echo '{}' ';' \
		| sed 's,%,/,g;s/.yaml//g')"

	for cfg in $cfgs; do
		if [[ "$cfg" == "$cur" ]]; then
			echo "$yellow$cfg$normal"
		else
			echo "$cfg"
		fi
	done
}

function main() {
	local header=''
	local is_delete=0 is_edit=0

	while [ $# -gt 0 ]; do
		case "$1" in
		-d|--delete) is_delete=1;;
		-e|--edit) is_edit=1;;
		-l|--list) list_kubeconfigs; exit;;
		-c|--contexts) list_contexts; exit;;
		-h|--help) usage; exit;;
		-*) echo "Warning, unrecognized option ${1}" >&2; exit 1;;
		*) positional+=("${1}");;
		esac
		shift
	done
	set -- "${positional[@]}"

	local user_config="${1:-}"
	[ -d "$KUBECONFIG_EXTRA_DIR" ] || mkdir -p "$KUBECONFIG_EXTRA_DIR"

	header='Select kubeconfig to activate:'
	if [ "${is_edit}" = 1 ]; then
		header='Select kubeconfig to edit:'
	elif [ "${is_delete}" = 1 ]; then
		header='Select kubeconfig to DELETE:'
	fi

	if [ -z "$user_config" ]; then
		if [ -h "$KUBECONFIG" ]; then
			user_config="$(get_all_kubeconfigs \
				| fzf --exit-0 --ansi --info=right --height=50% --no-preview \
						--header "$header" --header-first --margin=1,3,0,3 --scrollbar=▏▕)"
		else
			if [ -f "$KUBECONFIG" ]; then
				echo "ERROR: Configuration file '$KUBECONFIG' exists but it's not symbolic link"
				echo "Notice: If it's your first time, backup and move your current"
				echo "'$KUBECONFIG' file to '$KUBECONFIG_EXTRA_DIR/main'"
				echo 'Then you can use it by: kubectl switch main'
			else
				echo "ERROR: '$KUBECONFIG' symbolic link doesn't exist."
				echo "Notice: If it's your first time, create '$KUBECONFIG_EXTRA_DIR/main' file"
				echo "and invoke: kubectl switch main"
			fi
			exit 1
		fi
	fi

	if [ -z "$user_config" ]; then
		echo 'None selected, aborting.'
		exit 1
	fi

	# If argument is an absolute path, don't change it at all.
	if [[ ! "${user_config}" =~ ^/ ]]; then
		# Translate / to %
		user_config="${KUBECONFIG_EXTRA_DIR}/${user_config//\//%}"
		if [[ ! "${user_config##*.}" =~ ^ya?ml$ ]]; then
			# Append default .yaml extension.
			user_config="${user_config}.yaml"
		fi
	fi

	if [ -f "${user_config}" ]; then
		if [ "${is_edit}" = 1 ]; then
			# Edit selected kubeconfig.
			"${EDITOR:-vi}" "${user_config}"
		elif [ "${is_delete}" = 1 ]; then
			# Delete selected kubeconfig.
			echo 'Deleting kubeconfig:'
			rm -v "${user_config}"
		else
			# Create symlink to the selected kubeconfig.
			ln -sf "${user_config}" "$KUBECONFIG"
			echo "Activated '$(current_kubeconfig)' kubeconfig"
		fi
	else
		echo "ERROR: Config file '${user_config}' doesn't exist in your directory."
		echo "Nothing has changed."
		exit 1
	fi
}

main "$@"

#  vim: set ts=2 sw=0 tw=80 noet :
