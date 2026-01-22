#!/usr/bin/env bash
set -euo pipefail
# create_zip_bundle.sh
# Genera la estructura completa del repo madre TAMV y la empaqueta en tamv-madre-bundle.zip
# Uso: ./create_zip_bundle.sh
# Requisitos: unzip, zip, bash, coreutils

ROOT_DIR="$(pwd)/tamv-madre-bundle"
ZIP_FILE="$(pwd)/tamv-madre-bundle.zip"

rm -rf "$ROOT_DIR" "$ZIP_FILE"
mkdir -p "$ROOT_DIR"

echo "Creando estructura base..."
mkdir -p "$ROOT_DIR/.github/workflows"
mkdir -p "$ROOT_DIR/charts/render-4d-hypercube/templates"
mkdir -p "$ROOT_DIR/charts/tamv-umbrella"
mkdir -p "$ROOT_DIR/k8s"
mkdir -p "$ROOT_DIR/infra/bootstrap"
mkdir -p "$ROOT_DIR/infra/terraform"
mkdir -p "$ROOT_DIR/runbooks/SCRIPTS"
mkdir -p "$ROOT_DIR/services/render-4d-hypercube/src"
mkdir -p "$ROOT_DIR/docs"
mkdir -p "$ROOT_DIR/templates"

# README_TAMV.md (descripcion completa TAMV Online y resumen)
cat > "$ROOT_DIR/README_TAMV.md" <<'EOF'
# TAMV MD‑X4 — Repo Madre (OsoPanda1/tamv-unify-nexus)

Versión: 2025-12-31

Descripción total — ¿Qué es TAMV ONLINE?
TAMV (Temporal‑Augmented Multisensory Virtuals) MD‑X4 es un ecosistema distribuido de microservicios orientado a experiencias inmersivas y sensoriales 4D a escala global. Su objetivo es ofrecer plataformas, herramientas y pipelines para crear y servir experiencias que integran:
- Renderizado 3D y 4D (proyecciones 4D mapeadas a 3D)
- Efectos multisensoriales: audio espacial, haptics, control de iluminación, efectos hápticos remotos y datos sensoriales de baja latencia
- Integración con WebXR, WebRTC y clientes nativos
- Orquestación IA para personalización y adaptación en tiempo real (IA especializada por "célula")
- Pipelines de inferencia y entrenamiento en GPU, con soporte para cargas experimentales de computación cuántica y señales multisensoriales

Arquitectura en alto nivel
- Células (KnowledgeCell / microservicios): cada célula es un microservicio versionado independiente que expone API REST/gRPC o medios/streaming (WebRTC, WebSocket) y endpoints de validación visual.
- Orquestador y Gateway: un servicio gateway (API Gateway + service mesh) rutea tráfico y aplica políticas.
- Infraestructura: Kubernetes (EKS/GKE/AKS) con node pools CPU / GPU, almacenamiento S3, Postgres HA, Kafka/NATS para eventos, y un stack de observabilidad (Prometheus, Grafana, Loki, Tempo).
- CI/CD y GitOps: pipelines en GitHub Actions, Helm charts, y ArgoCD/Flux para sincronía declarativa.
- Seguridad: Vault/KMS para secretos, TLS everywhere, SCA scans, y políticas RBAC estrictas.

Casos de uso principales
- Streaming inmersivo en tiempo real para aplicaciones XR
- Visualizaciones científicas multidimensionales y cinematográficas
- Plataformas sociales inmersivas con efectos sensoriales personalizados
- Pipelines de IA para adaptación perceptual y optimización de render

Propósito de este repo
Este repo madre consolida charts, pipelines, infra-as-code, plantillas y servicios plantilla para desplegar TAMV ONLINE desde una única fuente de verdad. Está diseñado para:
- Desplegar un entorno staging y producción completo
- Servir como hub para integrar contenidos y datos de repos repositorios del ecosistema
- Proveer runbooks operacionales y automatizaciones reproducibles

Estructura del repo
- .github/workflows: CI / CD
- charts/: Helm charts por célula + umbrella chart
- infra/: Terraform para provisión de cluster + scripts de bootstrap
- k8s/: manifiestos base (namespaces, device plugin)
- runbooks/: procedimientos operativos y scripts
- services/: ejemplos de células (render-4d-hypercube)
- docs/: documentación operativa y manuales
- templates/: plantillas reutilizables para values, secrets, etc.

Licencia y gobernanza
- Reemplaza este bloque con la licencia del proyecto (MIT/Apache/etc.)
- Mantener CODEOWNERS y políticas de revisión estrictas antes de mergear a main.

EOF

# AI-understandable deployment manual (para agentes/IA)
cat > "$ROOT_DIR/docs/AI_DEPLOYMENT_AGENT.md" <<'EOF'
# Manual para Agente IA: Despliegue completo y producción de TAMV ONLINE

Propósito
Este documento está diseñado para que una IA (o agente automatizado) ejecute de forma reproducible el despliegue completo de TAMV ONLINE desde este repo madre. Contiene pasos secuenciales, precondiciones, comprobaciones de seguridad y acciones de rollback.

Resumen del flujo (alto nivel)
1. Preparación del entorno y secrets
2. Provisión de infra (Terraform -> cluster EKS/GKE/AKS)
3. Bootstrap de cluster (cert-manager, ingress, external-secrets, observabilidad)
4. Build y push de imágenes (CI)
5. Despliegue Helm en staging (canary)
6. Smoke tests visuales/perceptuales
7. Aprobación y promoción a producción (canary -> full)
8. Monitoreo y verificación post-deploy
9. Rollback/Recovery si es necesario

Precondiciones (verificar antes de operar)
- Acceso con permisos administrativos al repositorio y al cloud provider.
- Secrets configurados en GitHub (REGISTRY_USERNAME, REGISTRY_TOKEN, KUBECONFIG_STAGING/PROD o credenciales para terraform).
- Dominio y DNS configurado o disponible para certificados TLS.
- Bucket S3 o equivalente para assets y backups.
- Políticas de seguridad cumplidas y owners definidos.

Detalles operativos (paso a paso)

1) Preparación local / credenciales
- Verificar variables de entorno o GitHub secrets:
  - REGISTRY_USERNAME, REGISTRY_TOKEN
  - KUBECONFIG_STAGING (base64), KUBECONFIG_PROD (base64) OR AWS creds
  - AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY (si terraform usa AWS)
- Validar que el agente IA tenga acceso seguro a las claves de despliegue (Vault o secrets manager).

2) Provisión de infraestructura (Terraform)
- Dir: infra/terraform
- Acciones:
  - terraform init
  - terraform plan -out=tfplan -var="aws_region=us-east-1"
  - terraform apply tfplan
- Outputs relevantes:
  - kubeconfig (guardar en secreto KUBECONFIG_PROD)
  - cluster_endpoint

3) Bootstrap cluster
- Ejecutar infra/bootstrap/install_components.sh con kubectl apuntando al cluster
- Verificar pods en namespaces cert-manager, external-secrets, ingress-nginx, monitoring, argocd
- Comprobaciones:
  - kubectl get pods -A | grep cert-manager
  - helm list -n monitoring

4) CI: Build y push de imágenes
- Ejecutar workflow CI o localmente:
  - cd services/render-4d-hypercube
  - npm ci && npm run build
  - docker build -t ghcr.io/YOUR_ORG/render-4d-hypercube:TAG .
  - docker login ghcr.io -u $REGISTRY_USERNAME -p $REGISTRY_TOKEN
  - docker push ghcr.io/YOUR_ORG/render-4d-hypercube:TAG
- Verificación:
  - docker pull ghcr.io/YOUR_ORG/render-4d-hypercube:TAG

5) Despliegue en staging
- Usar helm upgrade --install con namespace tamv-staging
- Parámeteros mínimos:
  - image.repository=ghcr.io/YOUR_ORG/render-4d-hypercube
  - image.tag=TAG
- Verificar:
  - kubectl -n tamv-staging rollout status deployment/render-4d-hypercube
  - Ejecutar runbooks/SCRIPTS/smoke_test.sh tamv-staging render-4d-hypercube
  - Ejecutar prueba visual/perceptual: capturar frame demo y comparar con baseline (PSNR/SSIM threshold)
- Observability:
  - Revisar métricas p95/p99, error rate, pod restarts

6) Promoción a producción (canary -> full)
- Si staging OK, solicitar aprobación humana automática o programada (env protections).
- Desplegar en tamv-prod usando helm (canary con service-mesh o traffic split).
- Monitorizar 15-30 minutos y si los SLO están en verde, promover a 100% tráfico.

7) Post-deploy verifications (0-24h)
- Re-ejecutar smoke tests y pruebas de carga reducida.
- Revisar dashboards Grafana y logs en Loki para errores anómalos.
- Ejecutar script de validación de assets GLTF/gltf-validator para nuevos artefactos.

8) Rollback (si se necesita)
- helm rollback render-4d-hypercube <REV> --namespace tamv-prod
- Si migración de DB destructiva aplicada: restaurar snapshot en staging, validar y restaurar en prod con ventana de mantenimiento.

9) Mantenimiento y retraining de IA
- Monitorizar drift en modelos (latencia, accuracy).
- Activar pipelines de retrain en infra de IA con datasets versionados en model registry.

Verificaciones automáticas por cada step (checks)
- Existencia de secretos en repo
- Helm lint success
- kubectl readiness/liveness
- PSNR/SSIM > threshold para renders
- p95/p99 latency under target
- Error rate < threshold

Logs y observabilidad (recomendado)
- Centralizar logs en Loki con etiquetas: service, environment, pod, request_id
- Tracing con OpenTelemetry: instrumentar endpoints críticos y pipeline de render
- Metrics exportadas a Prometheus con job: service/metrics

Seguridad y cumplimiento
- No exponerse a servicios excepto via Ingress con TLS
- Rotación de keys periódica
- Registro de consentimientos para datos sensoriales (GDPR/CPRA compliance as required)

EOF

# CI workflows (preexistentes: small versions)
cat > "$ROOT_DIR/.github/workflows/ci.yml" <<'EOF'
name: CI - Build, Test, Image
on:
  push:
    branches:
      - main
      - develop
      - 'release/*'
  pull_request:
    branches:
      - main
      - develop

env:
  SERVICE: render-4d-hypercube
  IMAGE_REGISTRY: ghcr.io/YOUR_ORG
  IMAGE_NAME: ${{ env.IMAGE_REGISTRY }}/${{ env.SERVICE }}

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
        working-directory: services/render-4d-hypercube
      - run: npm run build
        working-directory: services/render-4d-hypercube
  push-image:
    needs: build-and-test
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Log in to registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_TOKEN }}
      - name: Build and push image
        uses: docker/build-push-action@v4
        with:
          context: services/render-4d-hypercube
          push: true
          tags: |
            ${{ env.IMAGE_NAME }}:${{ github.sha }}
EOF

cat > "$ROOT_DIR/.github/workflows/cd_canary.yml" <<'EOF'
name: CD - Canary to Staging -> Production
on:
  workflow_dispatch:
    inputs:
      image_tag:
        description: 'Image tag (sha or semver)'
        required: true
        default: 'latest'
      environment:
        description: 'target environment (staging|production)'
        required: true
        default: 'staging'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: '1.27.3'
      - name: Setup helm
        uses: azure/setup-helm@v3
        with:
          version: '3.12.0'
      - name: Deploy via Helm (simple)
        run: |
          echo "Dispatch deploy (see repo docs for usage)"
EOF

# Helm charts (render-4d-hypercube minimal)
cat > "$ROOT_DIR/charts/render-4d-hypercube/Chart.yaml" <<'EOF'
apiVersion: v2
name: render-4d-hypercube
description: Chart para la célula render-4d-hypercube (servicio TypeScript Node/GPU-ready)
type: application
version: 1.0.0
appVersion: "1.0.0"
EOF

cat > "$ROOT_DIR/charts/render-4d-hypercube/values.yaml" <<'EOF'
replicaCount: 2
image:
  repository: ghcr.io/YOUR_ORG/render-4d-hypercube
  tag: "1.0.0"
service:
  type: ClusterIP
  port: 5000
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"
EOF

cat > "$ROOT_DIR/charts/render-4d-hypercube/templates/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: render-4d-hypercube
spec:
  replicas: 2
  selector:
    matchLabels:
      app: render-4d-hypercube
  template:
    metadata:
      labels:
        app: render-4d-hypercube
    spec:
      containers:
      - name: app
        image: "ghcr.io/YOUR_ORG/render-4d-hypercube:1.0.0"
        ports:
        - containerPort: 5000
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 10
EOF

cat > "$ROOT_DIR/charts/tamv-umbrella/Chart.yaml" <<'EOF'
apiVersion: v2
name: tamv-umbrella
description: Umbrella chart para TAMV
type: application
version: 1.0.0
EOF

cat > "$ROOT_DIR/k8s/namespace-tamv.yaml" <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: tamv-prod
---
apiVersion: v1
kind: Namespace
metadata:
  name: tamv-staging
EOF

cat > "$ROOT_DIR/k8s/nvidia-device-plugin-daemonset.yaml" <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvidia-device-plugin-daemonset
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: nvidia-device-plugin-ds
  template:
    metadata:
      labels:
        name: nvidia-device-plugin-ds
    spec:
      containers:
        - image: nvidia/k8s-device-plugin:1.11
          name: nvidia-device-plugin
EOF

# infra bootstrap and terraform (simple)
cat > "$ROOT_DIR/infra/bootstrap/install_components.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Bootstrap: instalar cert-manager, ingress, external-secrets, prometheus"
echo "Sigue las instrucciones en infra/bootstrap README en el repo."
EOF
chmod +x "$ROOT_DIR/infra/bootstrap/install_components.sh"

cat > "$ROOT_DIR/infra/terraform/variables.tf" <<'EOF'
variable "aws_region" {
  type = string
  default = "us-east-1"
}
EOF

# runbooks
cat > "$ROOT_DIR/runbooks/PRODUCTION_RUNBOOK.md" <<'EOF'
# Runbook Operacional (resumen)
Ver runbooks/AI_DEPLOYMENT_AGENT.md y runbooks completos dentro del repo.
EOF

cat > "$ROOT_DIR/runbooks/SCRIPTS/smoke_test.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
NAMESPACE=${1:-tamv-staging}
SERVICE=${2:-render-4d-hypercube}
echo "Chequeo smoke: kubectl get pods -n $NAMESPACE -l app=$SERVICE"
kubectl get pods -n "$NAMESPACE" -l app="$SERVICE"
EOF
chmod +x "$ROOT_DIR/runbooks/SCRIPTS/smoke_test.sh"

# service example files
cat > "$ROOT_DIR/services/render-4d-hypercube/package.json" <<'EOF'
{
  "name": "render-4d-hypercube",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "start": "node dist/index.js",
    "test:unit": "jest --passWithNoTests"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "typescript": "^5.1.6",
    "ts-node": "^10.9.1",
    "jest": "^29.5.0"
  }
}
EOF

cat > "$ROOT_DIR/services/render-4d-hypercube/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true
  },
  "include": ["src/**/*"]
}
EOF

cat > "$ROOT_DIR/services/render-4d-hypercube/src/index.ts" <<'EOF'
import express from 'express';
const app = express();
const PORT = process.env.PORT ? parseInt(process.env.PORT) : 5000;
app.get('/health/ready', (_, res) => res.json({status:'ready'}));
app.get('/health/live', (_, res) => res.json({status:'live'}));
app.post('/api/render/4d/hypercube', express.json(), (req, res) => {
  res.json({id:'hypercube-demo', state4D:'stubbed', message:'demo'});
});
app.listen(PORT, ()=> console.log('listening', PORT));
EOF

cat > "$ROOT_DIR/services/render-4d-hypercube/Dockerfile" <<'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY services/render-4d-hypercube/package.json /app/
RUN npm ci
COPY services/render-4d-hypercube/ /app/
RUN npm run build || true
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app /app
EXPOSE 5000
CMD ["node", "dist/index.js"]
EOF

# CODEOWNERS
cat > "$ROOT_DIR/CODEOWNERS" <<'EOF'
/charts/ @SRETeam @DevTeam
/infra/ @SRETeam
/services/ @DevTeam
/runbooks/ @SRETeam
/docs/ @ProductTeam
EOF

# AI manual is already created in docs/AI_DEPLOYMENT_AGENT.md

# Final: create zip
echo "Empaquetando en $ZIP_FILE ..."
cd "$(dirname "$ROOT_DIR")"
zip -r "$(basename "$ZIP_FILE")" "$(basename "$ROOT_DIR")" >/dev/null

echo "ZIP creado: $ZIP_FILE"
echo "Contenido del ZIP (resumen):"
unzip -l "$ZIP_FILE" | sed -n '1,200p'
echo "Listo. Extrae el ZIP y commitea en la rama tamv/madre-bootstrap."