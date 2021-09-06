MAKEFLAGS += --warn-undefined-variables -j1
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
.PHONY:

# Environment switches
MAKE_ENV ?= docker
IMAGE_VENDOR ?= hausgold
PROJECT_NAME ?= jabbermam2sidekiq
START ?= foreground
START_CONTAINERS ?= jabber
BUNDLE_FLAGS ?=
COMPOSE_RUN_COMMAND ?= run
COMPOSE_RUN_SHELL_FLAGS ?= --rm
BASH_RUN_SHELL_FLAGS ?=
BASH_RUN_SHELL_USER ?= app
BASH_RUN_SHELL_CONTAINER ?= jabber
MODULE ?= mod_mam2sidekiq
DOMAIN ?= jabber.local
DATABASE ?= jabber

# Directories
APP_DIR ?= /app
LOG_DIR ?= log
TMP_DIR ?= tmp
VENDOR_DIR ?= vendor/bundle
VENDOR_CACHE_DIR ?= vendor/cache

# Host binaries
AWK ?= awk
BASH ?= bash
CHMOD ?= chmod
COMPOSE ?= docker-compose
CUT ?= cut
CP ?= cp
DOCKER ?= docker
ECHO ?= echo
FIND ?= find
GREP ?= grep
HEAD ?= head
INOTIFYWAIT ?= inotifywait
LS ?= ls
MKDIR ?= mkdir
MV ?= mv
NODE ?= node
NPM ?= npm
NPROC ?= nproc
PRINTF ?= printf
RM ?= rm
SED ?= sed
SLEEP ?= sleep
TAIL ?= tail
TEE ?= tee
TEST ?= test
TOUCH ?= touch
WC ?= wc
XARGS ?= xargs

# Container binaries
EJABBERDCTL ?= ejabberdctl
REDIS_CLI ?= redis-cli
PSQL ?= psql
WAITFORSTART ?= config/docker/wait-for-start

ifeq ($(MAKE_ENV),docker)
# Check also the docker binaries
CHECK_BINS += COMPOSE DOCKER
else ifeq ($(MAKE_ENV),baremetal)
# Nothing to do here - just a env check
else
$(error MAKE_ENV got an invalid value. Use `docker` or `baremetal`)
endif

all:
	# Jabber Message Bridge
	#
	# install                 Install the application
	# start                   Start the application
	# stop                    Stop all running containers
	#
	# logs                    Monitor the started application
	# relevant-logs           Show only relevant logs (with [RM] prefix)
	#
	# shell                   Attach an interactive shell session (jabber)
	#
	# reload                  Uninstall, check and build, install at once
	# uninstall-module        Uninstall the $(MODULE) module
	# build                   Check and build the $(MODULE) module
	# install-module          Install the $(MODULE) module
	#
	# watch                   Watch for file changes and reload the module and
	#                         run the test suite against it
	#
	# test                    Run the test suite
	#
	# clean                   Clean all temporary application files
	# clean-containers        Clean the Docker containers (also database data)
	# distclean               Same as clean and cleans Docker images

# Define a generic shell run wrapper
# $1 - The command to run
ifeq ($(MAKE_ENV),docker)
define run-shell
	$(COMPOSE) $(COMPOSE_RUN_COMMAND) $(COMPOSE_RUN_SHELL_FLAGS) \
		-e LANG=en_US.UTF-8 -e LANGUAGE=en_US.UTF-8 -e LC_ALL=en_US.UTF-8 \
		-u $(BASH_RUN_SHELL_USER) $(BASH_RUN_SHELL_CONTAINER) \
			bash $(BASH_RUN_SHELL_FLAGS) -c 'sleep 0.1; echo; $(1)'
endef
else ifeq ($(MAKE_ENV),baremetal)
define run-shell
	$(1)
endef
endif

# Define a retry helper
# $1 - The command to run
define retry
	if eval "$(call run-shell,$(1))"; then exit 0; fi; \
	for i in 1; do sleep 10s; echo "Retrying $$i..."; \
		if eval "$(call run-shell,$(1))"; then exit 0; fi; \
	done; \
	exit 1
endef

COMPOSE := $(COMPOSE) -p $(PROJECT_NAME)

.start: install clean-tmpfiles
	@$(eval BASH_RUN_SHELL_FLAGS = --login)

.jabber:
	@$(eval BASH_RUN_SHELL_CONTAINER = jabber)
	@$(eval COMPOSE_RUN_COMMAND = exec)
	@$(eval BASH_RUN_SHELL_USER = root)
	@$(eval COMPOSE_RUN_SHELL_FLAGS = -T)

.redis:
	@$(eval BASH_RUN_SHELL_CONTAINER = redis)
	@$(eval COMPOSE_RUN_COMMAND = exec)
	@$(eval BASH_RUN_SHELL_USER = root)
	@$(eval COMPOSE_RUN_SHELL_FLAGS = -T)

.database:
	@$(eval BASH_RUN_SHELL_CONTAINER = db)
	@$(eval COMPOSE_RUN_COMMAND = exec)
	@$(eval BASH_RUN_SHELL_USER = root)
	@$(eval COMPOSE_RUN_SHELL_FLAGS = -T)

.test:
	@$(eval BASH_RUN_SHELL_CONTAINER = jabber)
	@$(eval COMPOSE_RUN_COMMAND = exec)
	@$(eval BASH_RUN_SHELL_USER = app)
	@$(eval COMPOSE_RUN_SHELL_FLAGS = -T)

.e2e:
	@$(eval BASH_RUN_SHELL_CONTAINER = e2e)
	@$(eval COMPOSE_RUN_COMMAND = run)
	@$(eval BASH_RUN_SHELL_USER = root)
	@$(eval COMPOSE_RUN_SHELL_FLAGS = )

.disable-module-conf:
	# Disable $(MODULE) configuration
	@$(CP) config/ejabberd.yml config/ejabberd.yml.old
	@$(SED) 's/^\(\s*\)\(mod_mam2sidekiq:.*\)/\1# \2/g' \
		config/ejabberd.yml.old > config/ejabberd.yml
	@$(RM) config/ejabberd.yml.old

.enable-module-conf:
	# Enable $(MODULE) configuration
	@$(CP) config/ejabberd.yml config/ejabberd.yml.old
	@$(SED) 's/^\(\s*\)# \(mod_mam2sidekiq:.*\)/\1\2/g' \
		config/ejabberd.yml.old > config/ejabberd.yml
	@$(RM) config/ejabberd.yml.old

install: .test
	# Install the application
	@$(eval COMPOSE_RUN_COMMAND = run)
	@$(call retry,cd tests && $(NPM) install)

.wait-for-start:
	# Monitor the started application until it is booted
	@COMPOSE='$(COMPOSE)' $(WAITFORSTART)

start: clean-tmpfiles clean-logs .disable-module-conf
	# Start the application
ifeq ($(START),foreground)
	@$(COMPOSE) up $(START_CONTAINERS)
else ifeq ($(START),background)
	@$(COMPOSE) up -d $(START_CONTAINERS)
	@$(MAKE) .wait-for-start
else
	$(error START got an invalid value. Use `foreground` or `background`)
endif

uninstall-module: .jabber
	# Uninstall the $(MODULE) module
	@-$(call run-shell,$(EJABBERDCTL) module_uninstall $(MODULE))

build: .jabber uninstall-module
	# Check and build the $(MODULE) module
	@$(call run-shell,$(EJABBERDCTL) module_check $(MODULE))

.update-build-number:
	@$(eval VERSION = $(shell \
		$(GREP) -oP '\d+\.\d+\.\d+-\d+' include/mod_mam2sidekiq.hrl))
	@$(eval BUILD = $(lastword $(subst -, ,$(VERSION))))
	@$(eval NEXT_BUILD = $(shell $(ECHO) $$(($(BUILD)+1))))
	@$(eval NEXT_VERSION = $(firstword $(subst -, ,$(VERSION)))-$(NEXT_BUILD))
	# Update build number ($(VERSION) -> $(NEXT_VERSION))
	@$(SED) -i 's/$(VERSION)/$(NEXT_VERSION)/g' include/mod_mam2sidekiq.hrl

install-module: .jabber .update-build-number .enable-module-conf
	# Install the $(MODULE) module
	@$(call run-shell,\
		$(MKDIR) -p ebin && $(CHMOD) 777 ebin && \
		$(EJABBERDCTL) module_install $(MODULE))

reload: .update-build-number .enable-module-conf \
	uninstall-module install-module
	@$(SLEEP) 1
	# Reloaded the $(MODULE) module

restart-module: .jabber
	# Reload the module code and restart the module (0 means success)
	@$(call run-shell,$(EJABBERDCTL) restart_module $(DOMAIN) $(MODULE))

watch: .jabber
	# Watch for file changes and reload the $(MODULE) module
	@while true; do \
		$(INOTIFYWAIT) --quiet -r `pwd` -e close_write --format "%e -> %w%f"; \
		$(SHELL) -c "reset; \
			$(MAKE) --no-print-directory reload test || true"; $(ECHO); done

test: \
	test-specs \
	test-e2e

test-specs: .test
	# Run test specs for the $(MODULE) module
	@$(MAKE) clean-database
	@$(call run-shell,$(NODE) tests/index.js)

test-e2e:
	# Run end-to-end tests for the $(MODULE) module
	@$(MAKE) clean-database
	@$(MAKE) .test-e2e-produce .test-e2e-consume

.test-e2e-produce: .test
	# Produce Sidekiq jobs
	@$(call run-shell,$(NODE) tests/index-e2e.js)

.test-e2e-consume: .e2e
	# Consume Sidekiq jobs
	@$(call run-shell,$(MAKE) -C /app start)

restart:
	# Restart the application
	@$(MAKE) stop start

logs:
	# Monitor the started application
	@$(COMPOSE) logs -f --tail='all'

relevant-logs:
	# Monitor all relevant logs
	@$(COMPOSE) logs -f --tail='0' | $(GREP) --line-buffered '\[M2S\]'

stop: clean-containers
stop-containers:
	# Stop all running containers
	@$(COMPOSE) stop -t 5 || true
	@$(DOCKER) ps -a | $(GREP) $(PROJECT_NAME)_ | $(CUT) -d ' ' -f1 \
		| $(XARGS) -rn10 $(DOCKER) stop -t 5 || true

shell-test: shell
shell: .test
	# Start an interactive shell session
	@$(eval BASH_RUN_SHELL_USER = app)
	@$(call run-shell,$(BASH) -i)

shell-redis: .redis
	# Start an interactive database session
	@$(call run-shell,$(REDIS_CLI))

shell-db: .database
	# Start an interactive database session
	@$(call run-shell,PGPASSWORD=postgres $(PSQL) $(DATABASE) postgres)

shell-e2e: .e2e
	# Start an interactive e2e shell session
	@$(call run-shell,$(BASH) -i)

clean-database: \
	clean-redis \
	clean-postgres

clean-redis: .redis
	# Clean the Redis database
	@$(call run-shell,$(REDIS_CLI) FLUSHALL >/dev/null 2>&1)

clean-postgres:  .database
	# Clean the database tables
	@$(call run-shell,PGPASSWORD=postgres $(PSQL) $(DATABASE) postgres -c \
		"TRUNCATE TABLE archive CASCADE; \
		 TRUNCATE TABLE archive_prefs CASCADE; \
		 TRUNCATE TABLE muc_online_room CASCADE; \
		 TRUNCATE TABLE muc_online_users CASCADE; \
		 TRUNCATE TABLE muc_registered CASCADE; \
		 TRUNCATE TABLE muc_room CASCADE; \
		 TRUNCATE TABLE muc_room_subscribers CASCADE; \
		 TRUNCATE TABLE sm CASCADE; \
		 TRUNCATE TABLE spool CASCADE; \
		 TRUNCATE TABLE vcard_search CASCADE; \
		 TRUNCATE TABLE vcard CASCADE; \
		 TRUNCATE TABLE sr_user CASCADE;" \
		 >/dev/null 2>&1)

clean-vendors:
	# Clean vendors
	@$(RM) -rf $(VENDOR_DIR) || true
	@$(RM) -rf .bundle

clean-logs:
	# Clean logs
	@$(MKDIR) -p $(LOG_DIR)
	@$(FIND) $(LOG_DIR) -type f -name *.log \
		| $(XARGS) -rn1 -I{} $(BASH) -c '$(PRINTF) "\n" > {}'
	@$(TOUCH) $(LOG_DIR)/ejabberd.log

clean-tmpfiles:
	# Clean temporary files
	@$(MKDIR) -p $(TMP_DIR)
	@$(RM) -rf $(TMP_DIR)/build || true
	@$(FIND) $(TMP_DIR) -type f \
		| $(XARGS) -rn1 -I{} $(BASH) -c "$(RM) '{}'"
	@$(RM) -rf ebin

clean-containers: stop-containers
	# Stop and kill all containers
	@$(COMPOSE) rm -vf || true
	@$(DOCKER) ps -a | $(GREP) $(PROJECT_NAME)_ | $(CUT) -d ' ' -f1 \
		| $(XARGS) -rn10 $(DOCKER) rm -vf || true

clean-images: clean-containers
	# Remove all docker images
	$(eval EMPTY = ) $(eval CLEAN_IMAGES = $(PROJECT_NAME)_)
	$(eval CLEAN_IMAGES += $(IMAGE_VENDOR)/app:$(PROJECT_NAME))
	$(eval CLEAN_IMAGES += <none>)
	@$(DOCKER) images -a --format '{{.ID}} {{.Repository}}:{{.Tag}}' \
		| $(GREP) -P "$(subst $(EMPTY) $(EMPTY),|,$(CLEAN_IMAGES))" \
		| $(AWK) '{print $$0}' \
		| $(XARGS) -rn1 $(DOCKER) rmi -f || true

clean-test-results:
	# Clean test results
	@$(RM) -rf coverage || true
	@$(RM) -rf snapshots || true

clean-vendor-cache:
	# Clean the vendor cache
	@$(RM) -rf $(VENDOR_CACHE_DIR) || true

clean: clean-vendors clean-logs clean-tmpfiles clean-containers
distclean: clean clean-vendor-cache clean-images
