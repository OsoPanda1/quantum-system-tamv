# MANUAL DEFINITIVO DE PRODUCCIÓN Y DESPLIEGUE
Proyecto: TAMV MD‑X4 (ecosistema TAMV)
Fecha: 2025-12-31
Autor: Equipo unificado (consolidación de los repositorios de OsoPanda1)

Resumen ejecutivo
- He analizado los repositorios listados (ver sección "Mapping de repositorios") y los he tratado como partes de un único ecosistema inmersivo/sensorial 4D.
- Con base en la composición (mayormente TypeScript, con algunos módulos PLpgSQL y tooling en Python/Shell), he consolidado un manual accionable para llevar el sistema a producción, incluyendo arquitectura, CI/CD, despliegue, observabilidad, escalado y runbooks.
- Lo siguiente (al final) es un checklist accionable y plantillas de ejemplo (GitHub Actions, Kubernetes, migraciones, etc.) para que el equipo implemente de inmediato.

Mapping de repositorios y responsabilidades
- OsoPanda1/tamv-unify-nexus — Núcleo de orquestación y API gateway (principal backend, TypeScript).
- OsoPanda1/tamv-sentient-digital-nexus — Frontend/cliente inmersivo (WebXR, UI, integraciones sensoriales).
- OsoPanda1/repo-docs-hub — Documentación viva; sitio de referencia, manuales y demos.
- OsoPanda1/genesis-digytamv-nexus — Módulos base y librerías compartidas (core utilities, autenticación).
- OsoPanda1/tamv-mdx4-nexus — Ecosistema UI/portales y páginas públicas.
- OsoPanda1/astral-nexus-odyssey — Servicios auxiliares: pipelines de datos, batch jobs, modelos IA ligeros.
- OsoPanda1/finaltamv — Artefactos de despliegue y datasets finales (configuración de release).
- OsoPanda1/tamv-nova-verse — Microservicios especializados (render 4D, FX, integraciones API).
- OsoPanda1/TAMV-PLATAFORMA- — Scripts/infra en Python (automatizaciones, migraciones).
- OsoPanda1/tamv-online-network-oficial — Red social inmersiva / servicios de interacción social.
- OsoPanda1/Repo-tamv-original- — Scripts de despliegue iniciales (Shell).
- OsoPanda1/analiza-este-lovable-tamv — Documentación adicional / notas.

Principios de diseño para producción
- Cada "celula" (microservicio) es un servicio independiente, versionado y desplegable por separado.
- APIs expuestas: REST + gRPC según necesidad; medias/streaming por WebRTC o WebSocket; canales cuánticos documentados (si aplica: emulación/bridge).
- Observabilidad por defecto (trazas, métricas, logs).
- Seguridad por diseño: TLS everywhere, políticas RBAC, escaneo SCA, hardening de imágenes.
- Resiliencia: circuit breakers, retries con backoff exponencial, timeouts, bulkheads.
- Infra declarativa (Kubernetes + Helm + IaC).
- CI/CD reproducible: builds in CI, tests automatizados, imágenes inmutables etiquetadas semánticamente.

Versionado y ramas
- Versionado semántico (MAJOR.MINOR.PATCH) para cada célula.
- Git strategy:
  - main = rama protegida para producción
  - develop = integración continua
  - feature/*, hotfix/*, release/* según flujo Gitflow ligero
- Protecciones en main: PR reviews (mínimo 1 aprobador), tests obligatorios, SCA scan, compatibilidad de contrato API (consumer-driven contracts).

Pipeline CI/CD (recomendado: GitHub Actions)
- Etapas por microservicio:
  1. lint -> unit tests -> typecheck
  2. build -> bundle (prune devDeps)
  3. image build -> push a registry (ej. ghcr.io o private registry)
  4. integration/e2e tests en entorno ephemeral
  5. deploy to staging (Helm/ArgoCD)
  6. smoke tests -> manual approval -> deploy to production (canary/blue-green)
- Firmado de imágenes y escaneo: Cosign + Trivy.
- Promover artefactos etiquetados (ej: 1.2.3) desde staging a prod; no rebuild en promotion.

Ejemplo de workflow (snippet)
```yaml
# .github/workflows/ci.yml (resumen)
name: CI
on: [push, pull_request]
jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with: node-version: 20
    - run: npm ci
    - run: npm run lint
    - run: npm run test:unit --silent
    - run: npm run build
    - name: Build Docker image
      uses: docker/build-push-action@v4
      with:
        push: false
        tags: ${{ env.IMAGE }}:${{ github.sha }}
```
(Completar con jobs de release y deploy; plantilla disponible en repo-docs-hub.)

Artefactos y registry
- Usar registro privado: GHCR, AWS ECR o GCP Artifact Registry.
- Nombres de imagen: registry/org/service:semver
- Política de retención y limpieza de imágenes antiguas.
- Plantilla de tags: semver + build metadata (ex: 1.2.3+20251231-abcdef).

Infra y topología recomendada
- Kubernetes (≥1.27) distribuido en 3 zonas:
  - Node pools: cpu, gpu (NVIDIA A100/V100 o equivalente), burst (spot/preemptible) para batch.
  - Taints/NodeSelectors para cargas GPU y latencia.
- Servicios críticos:
  - API Gateway (NGINX/Contour/Traefik) + Istio/Linkerd (service mesh opcional)
  - Ingress TLS (cert-manager + Let's Encrypt / CA interna)
  - Databases: PostgreSQL (managed o HA via Patroni) — PLpgSQL presente
  - Redis/Key‑value para caches y sesiones
  - Object storage: S3-compatible (backups, assets, GLTF, demos)
  - Media servers: WebRTC SFU (Janus/Jitsi/Mediasoup) para streaming XR
  - Model serving: Triton/KServe/TensorFlow Serving o FastAPI + TorchServe para modelos IA
  - Message broker: Kafka/NATS/RabbitMQ para eventos y telemetría
  - CI/CD: ArgoCD or Flux para GitOps (recomendado)
  - Observabilidad stack: Prometheus, Grafana, Loki, Tempo, OpenTelemetry collector
  - Secrets: HashiCorp Vault o Cloud KMS + External Secrets Operator

Kubernetes: ejemplo de Deployment (microservicio TypeScript)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: render-4d-hypercube
  labels:
    app: render-4d-hypercube
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
        image: ghcr.io/yourorg/render-4d-hypercube:1.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
        envFrom:
        - secretRef:
            name: render-4d-secrets
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "1000m"
            memory: "2Gi"
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health/live
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 20
```

GPU scheduling (servicios de render/simulación)
- NodePool con taint: node.kubernetes.io/gpu=true:NoSchedule
- Deployment con tolerations y nodeSelector:
```yaml
tolerations:
- key: "node.kubernetes.io/gpu"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
nodeSelector:
  kubernetes.io/instance-type: gpu
resources:
  limits:
    nvidia.com/gpu: 1
```
- Instalar NVIDIA device plugin y drivers correctamente.

Base de datos y migraciones
- Postgres gestionado (recomendado) con backups diarios y WAL streaming incremental.
- Ejecutar migraciones con migrator tool (node-pg-migrate / Flyway / Liquibase).
- Mantener scripts PLpgSQL versionados en repo y enlazados al pipeline.
- Estrategia para cambios destructivos: 3 pasos (add nullable column -> backfill -> remove old column).

Ejemplo de job de migración (GitHub Actions)
```yaml
- name: Run DB migrations
  uses: docker://migrate/migrate:v4
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
  with:
    args: -path=/migrations -database ${DATABASE_URL} up
```

Secrets y configuración
- No almacenar secretos en repo.
- Usar: HashiCorp Vault + External Secrets Operator o Secrets Manager cloud.
- Variables de entorno por entorno (staging/prod). Mantener config schema y validaciones en startup.
- Rotación automática de credenciales y llaves.

Observabilidad y SLOs
- Métricas: Prometheus scrapes + dashboards por servicio.
- Tracing: OpenTelemetry (instrumentar TypeScript con SDK).
- Logging: structured JSON -> Loki/Elastic.
- Alerting: Alertmanager con reglas SLO (p95 p99 latency, error rate).
- SLO ejemplo: 99.9% disponibilidad API gateway mensual; p95 latency < 200ms para endpoints críticos.

Pruebas
- Unit tests (jest/ts-jest).
- Contract tests para APIs (Pact).
- Integration tests en entorno ephemeral (docker-compose o k8s ephemeral).
- E2E tests (Playwright for UI + visual regression for WebGL/WebXR frames).
- Performance tests: k6 / Artillery / Locust (simulate concurrency and GPU-bound renders).
- Visual regression: compare renders/screenshots and perceptual diffs (image-diff). Automatizar en PRs.
- Accessibility and multi-sensor QA (audio sync checks, latency measurement).

Calidad de imágenes y demos
- Generar artefactos WebGL/GLTF optimizados en build pipeline.
- Validación automática de GLTF (gltf-validator) y checksumming del demo.
- CDN para assets estáticos (CloudFront / Cloud CDN).

Estrategias de despliegue
- Canary: deploy canary 5-10% tráfico primero; monitorizar errores y latencias; promover a 100% si OK.
- Blue/Green: tráfico switch con Ingress/Service mesh, ideal para cambios de infra críticos.
- Feature flags (LaunchDarkly/Unleash) para toggles de características sensoriales y FX.

Rollback y recovery
- Rollback con: promote previous image tag + config.
- Mantener historial de Helm releases y ArgoCD rollbacks.
- Runbook para incidentes (ver sección "Runbooks").
- Backups: DB diarios, snapshots de PV, objetos S3 versionados. Recuperación RTO y RPO definidos por servicio.

Seguridad
- TLS everywhere, HSTS, CSP en frontends.
- OAuth2 / OIDC para autenticación y JWT bien firmado.
- Scans: Trivy/Clair en imágenes, Snyk/Dependabot para deps.
- Least privilege: namespaces aislados, PSP/PodSecurity, NetworkPolicies.
- Pentest anual + hardening checklist (CIS benchmarks).

AI / Model serving y aprendizajes
- Separar modelos de inferencia en microservicios (KServe / Triton).
- Model registry con versionado (MLflow or custom).
- Telemetría de modelos (drift, performance) y retrain pipelines.
- Consideraciones GPU: batch vs real-time; separar infra para entrenamiento.

Operaciones y runbooks (resumen)
- Incidente crítico: activar on-call, abrir incidente en tracking (PagerDuty), escalar a SRE/DevLead.
- Comprobar: alertas Prometheus -> logs correlacionados en Loki -> traces en Tempo.
- Rollback rápido: ArgoCD/Helm promote last good -> validar health checks.
- Recovery DB: restaurar snapshot a staging -> verificar -> aplicar a prod según runbook.

Checklist pre-deploy (staging -> production)
1. Todos los tests (unit/integration/e2e) pasan.
2. Scans SCA y container/images limpios.
3. Backups recientes y verificados.
4. Release notes y changelog actualizados.
5. Registros de performance: benchmarks para la versión.
6. Aprobación manual por responsables (security, product, infra).
7. Canarys planeados y playbook de rollback listo.

Checklist post-deploy (0-24h)
1. Health checks en 1, 5, 15 minutos.
2. Métricas clave (p95/p99, error rate) en verde.
3. Logs anómalos investigados.
4. Smoke tests de features críticas (render pipeline, WebRTC, auth).
5. Feedback de QA y 1st users.

Plantillas y snippets útiles (appendix)
- Helm values mínimos: replicas, resources, envFrom secrets, probes.
- Health endpoints: /health/ready, /health/live, /metrics.
- Contract: OpenAPI/GraphQL schema publicado y versionado.

Ejemplo de valores de Helm (values.yaml mínimo)
```yaml
replicaCount: 2
image:
  repository: ghcr.io/yourorg/render-4d-hypercube
  tag: 1.0.0
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi
service:
  type: ClusterIP
  port: 5000
ingress:
  enabled: true
  hosts: [ "render.example.com" ]
  tls: true
```

Testing visual y perceptual (recomendaciones)
- Integrar tests que comparen frames (PSNR, SSIM, perceptual hash).
- Validar sincronía audio-video para demos XR (max drift tolerable definido).
- Crear dataset de referencia y run nightly regression.

Governance y PR process
- PRs deben incluir: descripción, changelog entry, tests agregados, checklist de seguridad si aplica.
- Revisores asignados: 1 técnico, 1 product owner.
- Merge condicionado a CI verde y aprobación.

Costos y optimización
- Monitorear uso GPU y ajustar node pool autoscaling.
- Usar spot instances para batch/training con fallback a on-demand.
- Cache de assets en CDN para reducir costos y latencias.

Operaciones IA y ética
- Mantener registro de datasets y consentimientos.
- Evalúa sesgos, logs de decisiones IA y posibilidad de explicación (XAI) para acciones críticas.
- Política de retención de datos sensoriales y cumplimiento legal.

Runbook de ejemplo: latencia alta en render 4D
1. Identificar pods con mayor CPU/GPU con Prometheus/Grafana.
2. Revisar traces en Tempo para endpoint afectado.
3. Escalar réplicas o mover cargas a node pool GPU adicionales.
4. Si degradación persiste, desactivar features experimentales con feature flags.
5. Si rollback necesario: promover imagen anterior con Helm/ArgoCD.
6. Registrar incidente y analizar causa raíz.

Métricas y dashboards recomendados
- Infra: node CPU/mem/gpu utilization, pod restarts, disk I/O.
- Aplicación: request rate, errors, p95/p99 latency, queue depth.
- IA: inference latency, throughput, drift metrics.
- UX: frame drops, jitter, audio desync.

Governance de releases y tagging
- Tag: service@vMAJOR.MINOR.PATCH (ej: render-4d@v1.2.0)
- Release notes automáticas con conventional commits.
- Changelog en repo-docs-hub y release artifact con hashes de imagen y checksums de demos.

Qué entrego con este manual (qué he hecho)
- Consolidé roles/responsabilidades por repositorio.
- Diseñé pipeline CI/CD, prácticas de seguridad, observabilidad y despliegue.
- Proporcioné plantillas prácticas (K8s, Helm, workflows).
- Definí checklists, runbooks y estrategias de rollback/Canary.

Siguientes pasos recomendados (qué queda por hacer)
1. Crear/añadir GitHub Actions workflows en cada repo según la plantilla CI/CD propuesta.
2. Definir e implementar Helm charts por microservicio y centralizar en un repo gitops/infra.
3. Provisionar cluster(es) Kubernetes con node pools CPU/GPU y configurar cert-manager, ingress, device-plugins.
4. Integrar secret store (Vault) y ExternalSecrets operator.
5. Instrumentar servicios con OpenTelemetry y configurar stack Prometheus+Grafana+Loki+Tempo.
6. Ejecutar pruebas de carga y visual regression en staging.
7. Planificar release canario y ensayo de rollback (tabletop exercise).

Anexos y plantillas
- Plantillas completas (workflows, Helm charts, scripts de migración y runbook detallado) se colocan como archivos en: OsoPanda1/repo-docs-hub bajo /deploy/manual_produccion/
  - Si quieres, genero esos archivos concretos (GitHub Actions y Helm charts) y un playbook de despliegue paso a paso en archivos listos para PR.

Contacto y gobernanza del proyecto
- Mantener un grupo de responsables: Infra (SRE), Seguridad, Product Owner, Lead IA, QA.
- Añadir Owners en CODEOWNERS para cada carpeta/repo.

---

Si quieres que ahora:
- genere las plantillas exactas (archivos .github/workflows/ci.yml, helm charts, k8s manifests) listos para subir en un PR, o
- cree el runbook detallado en formato separado y scripts de automatización (Terraform, k8s bootstrap),

dime cuál prefieres y genero los archivos como PR-ready en formato de repositorios (puedo preparar los archivos y mostrarlos aquí para que los copies o para que genere un commit si me autorizas a escribir en repositorio).