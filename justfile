# config-import justfile

SHELLCHECK := env("SHELLCHECK", x"${XDG_DATA_HOME}/nvim/mason/bin/shellcheck")

changelog:
	git-cliff

test: test-bats test-shell test-krew

test-bats:
	COMMAND=./kubectl-config_import bats test/config-import.bats

test-shell:
	"{{ SHELLCHECK }}" ./kubectl-config_import

test-krew:
	docker run --rm -v ./.krew.yaml:/tmp/.krew.yaml \
		ghcr.io/rajatjindal/krew-release-bot:v0.0.46 \
		krew-release-bot template --tag v0.5.1 --template-file /tmp/.krew.yaml
