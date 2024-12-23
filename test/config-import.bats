#!/usr/bin/env bats

COMMAND="${COMMAND:-$BATS_TEST_DIRNAME/../kubectl-config_import}"

load common

@test "--help should not fail" {
	run ${COMMAND} --help
	echo "$output"
	[ "$status" -eq 0 ]
}

@test "-h should not fail" {
	run ${COMMAND} -h
	echo "$output"
	[ "$status" -eq 0 ]
}

@test "should fail if file not found" {
	use_config config1
	run ${COMMAND} -f "$BATS_TEST_DIRNAME"/testdata/nonexistent
	echo "$output"
	[ "$status" -eq 1 ]
}

@test "should fail if stdin is malformed" {
	use_config config1
	run bash -c "echo '' | ${COMMAND}"
	echo "$output"
	[ "$status" -eq 1 ]
}

@test "merge two config files and ensure backup" {
	use_config config1
	run ${COMMAND} -f "$BATS_TEST_DIRNAME"/testdata/config3
	echo "$output"
	[ "$status" -eq 0 ]

	run ${COMMAND} -l
	echo "$output"
	[ -f "$KUBECONFIG".bak.0 ]
	[[ "$output" = *'user3@cluster3'* ]]
}

@test "merge from stdin" {
	use_config config2
	run bash -c "${COMMAND} < '$BATS_TEST_DIRNAME'/testdata/config3"
	echo "$output"
	[ "$status" -eq 0 ]

	run kubectl config get-contexts -o name
	echo "$output"
	[ "$status" -eq 0 ]
	[[ "$output" = *'user3@cluster3'* ]]

	run kubectl config current-context
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$output" = 'user3@cluster3' ]
}

@test "merge from file and ensure overwrite precedence" {
	use_config config2
	run ${COMMAND} -f "$BATS_TEST_DIRNAME"/testdata/config1
	echo "$output"
	[ "$status" -eq 0 ]

	run kubectl config get-contexts -o name
	echo "$output"
	[ "$status" -eq 0 ]
	[[ "$output" = *'user1@cluster1'* ]]
	[[ "$output" = *'user2@cluster1'* ]]

	run kubectl config current-context
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$output" = 'user1@cluster1' ]

	run kubectl config view -o jsonpath='{.users[?(@.name == "user1")].user.username}'
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$output" = 'user1-config1' ]
}

@test "delete context" {
	use_config config1
	run ${COMMAND} -f "$BATS_TEST_DIRNAME"/testdata/config2
	echo "$output"
	[ "$status" -eq 0 ]

	run ${COMMAND} -c
	echo "$output"
	[ "$status" -eq 0 ]
	[[ "$output" = *'user2@cluster1'* ]]

	run ${COMMAND} --delete user2@cluster1
	echo "$output"
	[ "$status" -eq 0 ]

	run ${COMMAND} -l
	echo "$output"
	[ "$status" -eq 0 ]
	[[ ! "$output" = *'user2@cluster1'* ]]
}

@test "edit kubeconfig, support multiple files" {
	EDITOR='echo' KUBECONFIG="${KUBECONFIG}:a:b c" run ${COMMAND} -e
	echo "$output"

	[ "$status" -eq 0 ]
	[ "$output" = "${KUBECONFIG//:/ } a b c" ]
}
