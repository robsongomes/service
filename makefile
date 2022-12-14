SHELL := /bin/bash

# ==============================================================================
# Testing running system

# expvarmon -ports=":4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"
# hey -m GET -c 100 -n 10000 -H "Authorization: Bearer ${TOKEN}" http://localhost:3000/v1/users/1/2

# ==============================================================================


run:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go

# ==============================================================================
# Building containers

VERSION := 1.0

admin:
	go run app/tooling/admin/main.go

all: sales-api

sales-api:
	docker build \
		-f zarf/docker/dockerfile.sales-api \
		-t sales-api-amd64:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# ==============================================================================
# Running tests within the local computer

test:
	go test ./... -count=1
	staticcheck -checks=all ./...


tidy:
	go mod tidy
	go mod vendor

# ==============================================================================
# Running from within k8s/kind

KIND_CLUSTER := sales-starter-cluster

kind-apply:
	kustomize build zarf/k8s/kind/database-pod | kubectl apply -f -
	kubectl wait --namespace=database-system --timeout=120s --for=condition=Available deployment/database-pod
	kustomize build zarf/k8s/kind/sales-pod | kubectl apply -f -

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)

kind-describe:
	kubectl describe nodes
	kubectl describe svc
	kubectl describe pod -l app=sales	

kind-load:
	cd zarf/k8s/kind/sales-pod; kustomize edit set image sales-api-image=sales-api-amd64:$(VERSION)
	kind load docker-image sales-api-amd64:$(VERSION) --name $(KIND_CLUSTER)

kind-logs:
	kubectl logs -l app=sales --all-containers=true -f --tail=100 | go run app/tooling/logfmt/main.go

kind-restart:
	kubectl rollout restart deployment sales-pod 	

kind-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide	
	kubectl get pods -o wide --watch --all-namespaces

kind-status-db:
	kubectl get pods -o wide --watch --namespace=database-system	

kind-status-sales:
	kubectl get pods -o wide --watch	

kind-up:
	kind create cluster \
		--image kindest/node:v1.21.1 \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/kind/kind-config.yaml
	kubectl config set-context --current --namespace=sales-system

kind-update: all kind-load kind-restart

kind-update-apply: all kind-load kind-apply
	