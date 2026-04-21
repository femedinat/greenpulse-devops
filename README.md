# Projeto - Cidades ESGInteligentes

**GreenPulse** — aplicação Java Spring Boot com tema ESG (monitoramento inteligente de consumo de energia, indicadores e visão de integração com sensores). Este repositório entrega a camada DevOps: CI/CD com GitHub Actions, imagem Docker publicada em registry, Docker Compose com PostgreSQL, perfis `staging` e `prod`, e documentação para execução local e evidências.

## Integrantes

- Preencher nome completo do aluno ou dos integrantes do grupo antes da entrega (o mesmo deve constar no PDF/PPT).

## Como executar localmente com Docker

### 1. Obter o código

```bash
git clone <url-do-repositorio>
cd <nome-da-pasta-do-projeto>
```

Use o nome real da pasta após o clone (por exemplo `greenpulse-devops`).

### 2. Variáveis de ambiente

```bash
cp .env.example .env
```

Edite o `.env` se precisar alterar porta, banco ou credenciais. **Não envie o arquivo `.env` no ZIP da atividade** — apenas o `.env.example`.

### 3. Subir aplicação e banco

```bash
docker compose up --build
```

O Compose sobe:

- build da imagem da aplicação Spring Boot;
- PostgreSQL com healthcheck;
- rede `greenpulse-network`;
- volume persistente `greenpulse-db-data` para dados do banco;
- `depends_on` com condição de saúde do banco antes da app.

### 4. Acessos úteis

- Aplicação: `http://localhost:8080`
- Status simulado de energia: `http://localhost:8080/api/energy/status`
- Actuator health: `http://localhost:8080/actuator/health`

### 5. Banco e ciclo de vida

```bash
docker exec -it greenpulse-db psql -U greenpulse -d greenpulse
docker compose ps
docker compose down
docker compose down -v
```

O último comando remove também o volume do banco.

## Pipeline CI/CD

**Ferramenta:** GitHub Actions (`.github/workflows/ci-cd.yml`).

### Disparo (triggers)

- **Push** e **pull request** nas branches `main` e `develop`.

### Etapas

1. **CI — Build e testes** (`ci`): checkout, Java 17 (Temurin), cache Maven, `mvn clean verify` (compilação + testes automatizados do projeto).
2. **CD — Staging** (`deploy-staging`): executa apenas em **push** na branch `develop`. Usa o **GitHub Environment** `staging`, faz build da imagem com Docker Buildx, autentica no **GitHub Container Registry (GHCR)** e faz **push** das tags `staging-<sha>` e `staging-latest`. Corresponde ao ambiente de staging e ao profile Spring `staging`.
3. **CD — Produção** (`deploy-production`): executa apenas em **push** na branch `main`. Usa o **GitHub Environment** `production` (onde você pode configurar **aprovação manual** antes do deploy), build e **push** no GHCR com tags `prod-<sha>`, `prod-latest` e `latest`. Corresponde ao ambiente de produção e ao profile Spring `prod`.

### Pacotes no GitHub (imagens)

Após o primeiro deploy bem-sucedido, as imagens ficam em **Packages** do repositório ou da organização, no formato:

`ghcr.io/<usuario-ou-org-em-minusc>/<repositorio-em-minusc>:<tag>`

**Permissões:** o workflow usa `GITHUB_TOKEN` com `packages: write` nos jobs de deploy. Em repositório privado, configure a visibilidade do pacote se o professor precisar acessar a imagem.

**Branches:** mantenha `develop` para fluxo de staging e `main` para produção, conforme o workflow.

## Containerização

### Estratégia

- **Multi-stage build:** estágio Maven (JDK 17) compila o `.jar`; estágio final só com **JRE 17 Alpine** (imagem menor).
- **Cache de dependências:** `pom.xml` copiado primeiro e `mvn dependency:go-offline` para aproveitar cache de camadas.
- **Segurança:** aplicação roda como usuário sem privilégios (`greenpulse`).
- **Testes:** executados no **CI** (`mvn verify`). O build da imagem usa `package -DskipTests` para não duplicar testes na camada Docker (já validados no pipeline).

### Conteúdo do Dockerfile

```dockerfile
# Etapa 1: compila a aplicacao usando Maven e gera o arquivo .jar.
FROM maven:3.9.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copia primeiro o pom.xml para aproveitar cache de dependencias entre builds.
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copia o codigo-fonte e executa o empacotamento.
COPY src ./src
RUN mvn clean package -DskipTests

# Etapa 2: imagem final menor, contendo apenas o JRE e o .jar compilado.
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Usuario sem privilegios para executar a aplicacao com mais seguranca.
RUN addgroup -S greenpulse && adduser -S greenpulse -G greenpulse

COPY --from=build /app/target/*.jar app.jar

RUN chown -R greenpulse:greenpulse /app
USER greenpulse

EXPOSE 8080

# Executa a aplicacao Spring Boot.
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Em caso de qualquer divergência, prevalece o arquivo `Dockerfile` na raiz do repositório (atualize este bloco se o Dockerfile mudar).

### Docker Compose

Arquivo `docker-compose.yml`: serviços `app` e `db` (PostgreSQL 16), **rede** dedicada, **volume** nomeado, **variáveis de ambiente** alinhadas ao Spring e ao Postgres, **healthcheck** no banco e `depends_on` com `condition: service_healthy`.

## Tecnologias utilizadas

- Java 17
- Spring Boot 3
- Maven
- Spring Web, Spring Data JPA, Spring Boot Actuator
- PostgreSQL
- H2 (testes)
- Docker e Docker Compose
- GitHub Actions
- GitHub Container Registry (GHCR)

## Estrutura mínima da entrega (.zip)

```text
<greenpulse-devops>/
├── Dockerfile
├── docker-compose.yml
├── src/
├── README.md
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── .env.example
├── pom.xml
└── docs/
    └── evidencias.md
```

## Checklist de entrega

| Item | OK |
|------|:--:|
| Projeto compactado em .ZIP com estrutura organizada | ☑️ |
| Dockerfile funcional | ☑️ |
| docker-compose.yml ou arquivos Kubernetes | ☑️ |
| Pipeline com etapas de build, teste e deploy | ☑️ |
| README.md com instruções e prints | ☑️ |
| Documentação técnica com evidências (PDF ou PPT) | ☑️ |
| Deploy realizado nos ambientes staging e produção | ☑️ |