# Project variables
export PROJECT_NAME ?= squid
ORG_NAME ?= dockerproductionaws
REPO_NAME ?= squid
DOCKER_REGISTRY ?= 543279062384.dkr.ecr.us-west-2.amazonaws.com
AWS_ACCOUNT_ID ?= 543279062384
DOCKER_LOGIN_EXPRESSION ?= $$(aws ecr get-login --registry-ids $(AWS_ACCOUNT_ID) --no-include-email)

# Release settings
export SQUID_WHITELIST ?= 
export NO_WHITELIST ?= false

# Common settings
include Makefile.settings

.PHONY: version release clean tag tag%default login logout publish compose all

# Prints version
version:
	@ echo $(APP_VERSION)

# Executes a full workflow
all: clean release tag login publish clean

# Builds release image and runs acceptance tests
# Use 'make release :nopull' to disable default pull behaviour
release:
	${INFO} "Building images..."
	@ docker-compose $(RELEASE_ARGS) build $(NOPULL_FLAG)
	${INFO} "Build complete"
	${INFO} "Starting squid service..."
	@ docker-compose $(RELEASE_ARGS) up -d squid
	@ $(call check_service_health,$(RELEASE_ARGS),squid)
	${INFO} "Release environment created"
	${INFO} "Squid is running at http://$(DOCKER_HOST_IP):$(call get_port_mapping,$(RELEASE_ARGS),squid,3128)"

# Cleans environment
clean:
	${INFO} "Destroying release environment..."
	@ docker-compose $(RELEASE_ARGS) down -v || true
	${INFO} "Removing dangling images..."
	@ $(call clean_dangling_images,$(PROJECT_NAME))
	${INFO} "Clean complete"

# 'make tag [<tag>...]' tags development and/or release image with specified tag(s)
# If no tags are specified, then the following tags will be applied:
#   'latest'
#   <application version>
#   <git commit hash>
#   <git tag> (if a tag exists on the current commit)
tag: TAGS ?= $(if $(ARGS),$(ARGS),latest $(APP_VERSION) $(COMMIT_HASH) $(COMMIT_TAG))
tag: 
	${INFO} "Tagging release image with tags $(TAGS)..."
	@ $(foreach tag,$(TAGS),$(call tag_image,$(RELEASE_ARGS),squid,$(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag));)
	${INFO} "Tagging complete"

# Publishes image(s) tagged using make tag commands
publish:
	${INFO} "Publishing release image to $(DOCKER_REGISTRY)/$(ORG_NAME)/squid..."
	@ $(call publish_image,$(RELEASE_ARGS),squid,$(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME))
	${INFO} "Publish complete"

# Login to Docker registry
login:
	${INFO} "Logging in to Docker registry $$DOCKER_REGISTRY..."
	@ eval $(DOCKER_LOGIN_EXPRESSION)
	${INFO} "Logged in to Docker registry $$DOCKER_REGISTRY"

# Logout of Docker registry
logout:
	${INFO} "Logging out of Docker registry $$DOCKER_REGISTRY..."
	@ docker logout
	${INFO} "Logged out of Docker registry $$DOCKER_REGISTRY"

# Streams logs
log:
	@ docker-compose $(RELEASE_ARGS) logs -f

# Executes docker-compose commands in release environment
#   e.g. 'make compose ps' is the equivalent of docker-compose -f path/to/dockerfile -p <project-name> ps
#   e.g. 'make compose run nginx' is the equivalent of docker-compose -f path/to/dockerfile -p <project-name> run nginx
#
# Use '--'' after make to pass flags/arguments
#   e.g. 'make -- compose run --rm nginx' ensures the '--rm' flag is passed to docker-compose and not interpreted by make
compose:
	${INFO} "Running docker-compose command in release environment..."
	@ docker-compose $(RELEASE_ARGS) $(ARGS)

# IMPORTANT - ensures arguments are not interpreted as make targets
%:
	@: