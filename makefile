SHELL := /bin/bash

run:
	go run main.go

# ==============================================================================
# Building containers

VERSION := 1.0

all: service

service:
	docker build \
		-f zarf/docker/dockerfile \
		-t service-amd64:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# ==============================================================================
# Running from within k8s/kind

KIND_CLUSTER := gondor-starter-cluster

kind-apply:
	kustomize build zarf/k8s/kind/service-pod | kubectl apply -f -

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)

kind-describe:
	kubectl describe nodes
	kubectl describe svc
	kubectl describe pod -l app=service	

kind-load:
	kind load docker-image service-amd64:$(VERSION) --name $(KIND_CLUSTER)

kind-logs:
	kubectl logs -l app=service --all-containers=true -f --tail=100

kind-restart:
	kubectl rollout restart deployment service-pod 	

kind-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide	
	kubectl get pods -o wide --watch --all-namespaces

kind-status-service:
	kubectl get pods -o wide --watch

tidy:
	go mod tidy
	go mod vendor	

kind-up:
	kind create cluster \
		--image kindest/node:v1.21.1 \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/kind/kind-config.yaml
	kubectl config set-context --current --namespace=service-system

kind-update: all kind-load kind-restart

kind-update-apply: all kind-load kind-apply
	