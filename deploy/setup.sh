#!/usr/bin/env bash

set -euo pipefail

main() {
	# Pre-req for gcloud install
	sudo apt-get update
	sudo apt-get install -y apt-transport-https

	# Copied from the official install instructions on https://cloud.google.com/sdk/downloads#apt-get
	export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
	echo "deb https://packages.cloud.google.com/apt ${CLOUD_SDK_REPO} main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
	curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	sudo apt-get update
	sudo apt-get install -y google-cloud-sdk kubectl

	gcloud --version
	kubectl version --client

	echo "Authenticating gcloud service account"
	gcloud auth activate-service-account \
		--key-file "${GOOGLE_APPLICATION_CREDENTIALS}" \
		--project "${GOOGLE_PROJECT}"

	echo "Authenticating to GCR"
	gcloud docker --authorize-only --project "${GOOGLE_PROJECT}"

	echo "Configuring kubectl"
	gcloud container clusters get-credentials mobius \
		--project "${GOOGLE_PROJECT}" \
		--zone us-central1-b
}

main "$@"
