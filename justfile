# config-import justfile

VERSION := "v0.5.1"
SHELLCHECK := env("SHELLCHECK", x"${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/bin/shellcheck")
KREW_BOT_VERSION := "v0.0.46"

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
		krew-release-bot template --tag {{ VERSION }} --template-file /tmp/.krew.yaml

test-krew-ci:
	FILE=krew-release-bot_{{ KREW_BOT_VERSION }}_linux_amd64.tar.gz; \
	BASE_URL=https://github.com/rajatjindal/krew-release-bot/releases/download/{{ KREW_BOT_VERSION }}; \
	curl -L "$BASE_URL/$FILE" | tar xzvf - krew-release-bot && \
	chmod ug+x krew-release-bot; \
	./krew-release-bot template --tag {{ VERSION }} --template-file .krew.yaml; \
	rm krew-release-bot
