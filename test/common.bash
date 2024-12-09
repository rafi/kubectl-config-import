#!/usr/bin/env bats

# bats setup function
setup() {
	TEMP_HOME="$(mktemp -d)"
	export TEMP_HOME
	export HOME=$TEMP_HOME
	export KUBECONFIG="${TEMP_HOME}/config"

	if hash kubectl 2>/dev/null; then
		export KUBECTL=kubectl
	elif hash kubectl.exe 2>/dev/null; then
		export KUBECTL=kubectl.exe
	else
		echo >&2 "kubectl is not installed"
		exit 1
	fi
}

# bats teardown function
teardown() {
	rm -rf "$TEMP_HOME"
}

use_config() {
	cp "$BATS_TEST_DIRNAME/testdata/$1" "$KUBECONFIG"
}
