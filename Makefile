-include .env

POSTGRES_USER ?= postgres
POSTGRES_PASSWORD ?= postgres
POSTGRES_DB ?= postgres
POSTGRES_IP ?= localhost
POSTGRES_PORT ?= 5432

TABLE ?= dummy

.DEFAULT_GOAL := help

.PHONY: help migration migrate-inicial migrate-normal run-migrate run-migrate-drop run-sqlc run-swagger run-devtools run-testes run-infra run-go

MIGRATE_DSN := postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_IP):$(POSTGRES_PORT)/$(POSTGRES_DB)?sslmode=disable

##@ Migrations

migration: ## Cria uma migration (use TABLE=nome). Ex: make migration TABLE=users
	@echo "Criando migration: create_$(TABLE)_table"
	migrate create -ext sql -dir ./sql/migrations -seq $(TABLE)

migrate-inicial: ## Executa apenas a primeira migration (up 1)
	@echo "Executando migration inicial..."
	migrate -path ./sql/migrations -database "$(MIGRATE_DSN)" up 1

migrate-normal: ## Executa todas as migrations pendentes (up)
	@echo "Executando migrations..."
	migrate -path ./sql/migrations -database "$(MIGRATE_DSN)" up

run-migrate: migrate-normal ## Alias para migrate-normal

run-migrate-drop: ## Dropa o banco via migrate (cuidado!)
	@echo "Executando migrations..."
	migrate -path ./sql/migrations -database "$(MIGRATE_DSN)" drop

##@ Codegen / Docs

run-sqlc: ## Gera código do sqlc
	@echo "Executando sqlc..."
	sqlc generate

run-swagger: ## Atualiza docs do Swagger (swag init)
	@echo "Executando swagger update"
	swag init -g ./cmd/server/main.go -o ./docs

run-devtools: ## Roda sqlc + migrations (combo)
	@echo "Executando devtools..."
	$(MAKE) run-sqlc
	$(MAKE) migrate-normal

##@ Run / Infra / Tests

run-testes: ## Roda testes Go
	@echo "Executando testes..."
	go test -v ./...

run-infra: ## Sobe a infra (docker-compose)
	@echo "Subindo infraestrutura..."
	docker-compose -f ./infra/docker-compose.yml up -d

run-go: ## Roda a aplicação (go run)
	@echo "Executando aplicação..."
	go run ./cmd/server/main.go

##@ Help

help: ## Mostra esta ajuda
	@awk 'BEGIN {FS=":.*##"; \
		printf "\nUso:\n  make \033[36m<alvo>\033[0m [VAR=valor]\n\n"; \
		printf "Variáveis:\n"; \
		printf "  \033[36mTABLE\033[0m=%s\n  \033[36mPOSTGRES_USER\033[0m=%s\n  \033[36mPOSTGRES_PASSWORD\033[0m=%s\n  \033[36mPOSTGRES_DB\033[0m=%s\n  \033[36mPOSTGRES_IP\033[0m=%s\n  \033[36mPOSTGRES_PORT\033[0m=%s\n\n", \
			"$(TABLE)","$(POSTGRES_USER)","$(POSTGRES_PASSWORD)","$(POSTGRES_DB)","$(POSTGRES_IP)","$(POSTGRES_PORT)"; \
		printf "Alvos:\n"} \
		/^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)} \
		/^[a-zA-Z0-9_.-]+:.*##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2} \
		END {printf "\n"}' $(MAKEFILE_LIST)
