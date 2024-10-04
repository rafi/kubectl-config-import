#!/usr/bin/env bats

# bats setup function
setup() {
	TEMP_HOME="$(mktemp -d)"
	export TEMP_HOME
	export HOME=$TEMP_HOME
	export KUBECONFIG="${TEMP_HOME}/config"
}

# bats teardown function
teardown() {
	rm -rf "$TEMP_HOME"
}

use_config() {
	cp "$BATS_TEST_DIRNAME/testdata/$1" "$KUBECONFIG"
}
