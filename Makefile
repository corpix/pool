.DEFAULT_GOAL := all

## parameters

name                 = pool 
group                = corpix
remote               = github.com
namespace            = $(remote)/$(group)
version             ?= development
os                  ?=
args                ?=

export GOFLAGS ?=

PARALLEL_JOBS     ?= 8
NIX_OPTS          ?= --show-trace

## bindings

root                := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
nix_dir             := nix
pkg_prefix          := $(namespace)/$(name)
tmux                := tmux -2 -f $(root)/.tmux.conf -S $(root)/.tmux
tmux_session        := $(name)
nix                 := nix $(NIX_OPTS)
shell_volume_nix    := nix

### reusable and long opts for commands inside rules

add_shell_opts ?=
shell_opts = -v $(shell_volume_nix):/nix:rw     \
	-v $(root):/chroot                      \
	-e COLUMNS=$(COLUMNS)                   \
	-e LINES=$(LINES)                       \
	-e TERM=$(TERM)                         \
	-e NIX_BUILD_CORES=$(NIX_BUILD_CORES)   \
	-e HOME=/chroot                         \
	-w /chroot                              \
	--hostname localhost                    \
	$(foreach v,$(ports), -p $(v):$(v) ) $(add_shell_opts)

## helpers

, = ,

## macro

define fail
{ echo "error: "$(1) 1>&2; exit 1; }
endef

## targets

.PHONY: all
all: build # test, check and build all cmds

.PHONY: help
help: # print defined targets and their comments
	@grep -Po '^[a-zA-Z%_/\-\s]+:+(\s.*$$|$$)' Makefile \
		| sort                                      \
		| sed 's|:.*#|#|;s|#\s*|#|'                 \
		| column -t -s '#' -o ' | '

### releases

### development

.PHONY: fmt
fmt: # run go fmt
	go fmt ./...

.PHONY: tidy
tidy: # run go mod tidy
	go mod tidy

#### testing

.PHONY: test
test: # run unit tests
	go test -v ./...

.PHONY: lint
lint: # run linter
	golangci-lint --color=always --timeout=120s run ./...

#### runners

## env

.PHONY: run/shell
run/shell: # enter development environment with nix-shell
	nix-shell

.PHONY: run/cage/shell
run/cage/shell: # enter sandboxed development environment with nix-cage
	nix-cage

.PHONY: run/nix/repl
run/nix/repl: # run nix repl for nixpkgs from env
	nix repl '<nixpkgs>'

## dev session

.PHONY: run/tmux/session
run/tmux/session: # start development environment
	@$(tmux) has-session    -t $(tmux_session) && $(call fail,tmux session $(tmux_session) already exists$(,) use: '$(tmux) attach-session -t $(tmux_session)' to attach) || true
	@$(tmux) new-session    -s $(tmux_session) -n console -d
	@while !$(tmux) select-window  -t $(tmux_session):0; do sleep 0.5; done

	@if [ -f $(root)/.personal.tmux.conf ]; then             \
		$(tmux) source-file $(root)/.personal.tmux.conf; \
	fi

	@$(tmux) attach-session -t $(tmux_session)

.PHONY: run/tmux/attach
run/tmux/attach: # attach to development session if running
	@$(tmux) attach-session -t $(tmux_session)

.PHONY: run/tmux/kill
run/tmux/kill: # kill development environment
	@$(tmux) kill-session -t $(tmux_session)

#### runners

.PHONY: run/docker/shell
run/docker/shell: # run development environment shell
	@docker run --rm -it                   \
		--log-driver=none              \
		$(shell_opts) nixos/nix:latest \
		nix-shell --run 'exec make run/shell'

.PHONY: run/docker/clean
run/docker/clean: # clean development environment artifacts
	docker volume rm nix

##

.PHONY: clean
clean:: # clean state
	rm -rf result*
	rm -rf build main
	rm -rf .cache/* .local/* .config/* || true
