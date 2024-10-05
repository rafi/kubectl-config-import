# config-import justfile

VERSION := `git describe --tags $(git rev-list --tags --max-count=1)`
SHELLCHECK := env("SHELLCHECK", x"${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/bin/shellcheck")
KREW_BOT_VERSION := "v0.0.46"

_default:
	@just --list

changelog:
	git-cliff

test: test-bats test-shell test-krew

test-bats:
	COMMAND=./kubectl-config_import bats test/config-import.bats

test-shell:
	"{{ SHELLCHECK }}" ./kubectl-config_import

test-krew:
	docker run --rm -v ./.krew.yaml:/tmp/.krew.yaml \
		ghcr.io/rajatjindal/krew-release-bot:{{ KREW_BOT_VERSION }} \
		krew-release-bot template --tag {{ VERSION }} --template-file /tmp/.krew.yaml

test-krew-ci:
	APP=krew-release-bot; \
	FILE=${APP}_{{ KREW_BOT_VERSION }}_linux_amd64.tar.gz; \
	BASE_URL=https://github.com/rajatjindal/$APP/releases/download/{{ KREW_BOT_VERSION }}; \
	curl -L "$BASE_URL/$FILE" | tar xzvf - $APP && \
	chmod ug+x $APP; \
	./$APP template --tag {{ VERSION }} --template-file .krew.yaml; \
	rm $APP
