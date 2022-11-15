#gitleaks check

.PHONY : all protect detect

.ONESHELL:
.SHELLFLAGS = -ec

SHELL = /bin/bash

.DEFAULT_GOAL := all

# make the default of `make` run `make protect`
all: protect

# `make protect` will check all files staged in git (with `git add`) for secrets
protect:
	docker pull zricethezav/gitleaks:latest
	docker run -v $(shell pwd):/repo zricethezav/gitleaks:latest protect --source="/repo" --verbose --redact --staged

# `make detect` will review the entire git history to check if there were any secrets committed previously
detect:
	docker pull zricethezav/gitleaks:latest
	docker run -v $(shell pwd):/repo zricethezav/gitleaks:latest detect --source="/repo" --verbose --redact

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
