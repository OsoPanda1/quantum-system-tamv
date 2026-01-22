```markdown
# TAMV MD‑X4 — Repo Madre (OsoPanda1/tamv-unify-nexus)

Versión: 2025-12-31
Propósito: Repositorio consolidado "madre" que contiene la información, datos, charts, pipelines y scripts necesarios para desplegar y operar TAMV ONLINE (ecosistema inmersivo y sensorial 4D).

Qué incluye este repo
- charts/: Helm charts por célula + umbrella chart
- .github/workflows/: CI (build/test/image) y CD (canary/promote)
- infra/terraform/: IaC para provisión de infraestructura (AWS EKS por defecto)
- infra/bootstrap/: scripts para bootstrap de cluster y componentes (cert-manager, ArgoCD, ingress)
- k8s/: manifests base (namespaces, device plugin)
- runbooks/: runbooks operacionales, migraciones y scripts
- services/: ejemplos de microservicios (render-4d-hypercube) con Dockerfile, tests y endpoints health
- docs/: documentación viva, SLOs, checklist
- templates/: plantillas de values, secrets placeholders

Antes de ejecutar
1. Sustituye todos los placeholders (YOUR_ORG, YOUR_DOMAIN, emails, account ids).
2. Configura secrets GitHub: REGISTRY_USERNAME, REGISTRY_TOKEN, KUBECONFIG_STAGING, KUBECONFIG_PROD, COSIGN_KEY (opcional), AWS_* si usas Terraform con credenciales.
3. Revisa y adapta terraform/variables.tf a tu cuenta/región.

Resumen del flujo de despliegue
1. CI -> build, tests, image build -> push a registry (ghcr.io/YOUR_ORG por defecto).
2. CD -> Deploy canary a staging (helm upgrade --install), smoke tests automáticos.
3. Manual approval -> Promoción a producción (canary/blue-green).
4. Observabilidad y rollback: Prometheus/Grafana/Tempo/Loki + ArgoCD/Helm rollbacks.

Contacto y governance
- Equipo TAMV: tamv-core@yourdomain (placeholder)
- CODEOWNERS en /CODEOWNERS

Licencia: (coloca aquí la licencia del proyecto)
```