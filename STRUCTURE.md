# Cluster Config Repository Structure

This document shows the complete structure of the cluster-config repository.

## Directory Tree

```
cluster-config/
├── README.md                           # Repository overview and links
├── DEPLOYMENT.md                       # Step-by-step deployment guide
├── STRUCTURE.md                        # This file
├── .gitignore                          # Git ignore patterns
│
├── argocd/                             # ArgoCD Bootstrap (Wave -10)
│   ├── root-app.yaml                   # Root Application (apply this manually)
│   └── applications/                   # Child Applications (managed by root)
│       ├── namespaces-app.yaml         # Manages namespaces/
│       ├── operators-app.yaml          # Manages operators/
│       ├── rbac-app.yaml               # Manages rbac/
│       ├── aap-instances-app.yaml      # Manages aap-instances/
│       ├── tekton-tasks-app.yaml       # Manages tekton/tasks/
│       ├── tekton-pipelines-app.yaml   # Manages tekton/pipelines/
│       └── tekton-triggers-app.yaml    # Manages tekton/triggers/
│
├── namespaces/                         # Namespace Definitions (Wave -3)
│   ├── aap-dev.yaml                    # Dev AAP namespace
│   ├── aap-qa.yaml                     # QA AAP namespace
│   ├── aap-prod.yaml                   # Prod AAP namespace
│   └── dev-tools.yaml                  # Tekton pipelines namespace
│
├── operators/                          # Operator Subscriptions (Wave -2)
│   ├── aap-operator.yaml               # 3 AAP Operators (namespace-scoped)
│   ├── aap-operatorgroups.yaml         # OperatorGroups for AAP namespaces
│   └── pipelines-operator.yaml         # OpenShift Pipelines Operator
│
├── rbac/                               # RBAC Configuration (Wave -1)
│   ├── tekton-serviceaccounts.yaml     # 4 ServiceAccounts for pipelines
│   └── tekton-roles.yaml               # Roles and RoleBindings
│
├── aap-instances/                      # AAP Controllers (Wave 0)
│   ├── automation-controller-dev.yaml  # Dev AAP (1 replica, embedded DB)
│   ├── automation-controller-qa.yaml   # QA AAP (2 replicas, external DB option)
│   └── automation-controller-prod.yaml # Prod AAP (3 replicas, HA)
│
├── tekton/                             # Tekton CI/CD Resources
│   ├── tasks/                          # Reusable Tasks (Wave 1)
│   │   ├── git-clone-task.yaml         # Clone Git repositories
│   │   ├── ansible-lint-task.yaml      # Run ansible-lint
│   │   ├── molecule-test-task.yaml     # Run Molecule tests
│   │   ├── buildah-build-task.yaml     # Build EE with ansible-builder
│   │   ├── buildah-push-task.yaml      # Push images to registry
│   │   ├── aap-api-task.yaml           # Generic AAP API calls
│   │   ├── ansible-playbook-task.yaml  # Run CaC playbooks
│   │   └── manifest-parser-task.yaml   # Parse release manifests
│   │
│   ├── pipelines/                      # Pipeline Definitions (Wave 2)
│   │   ├── cac-pipeline.yaml           # Configuration-as-Code pipeline
│   │   ├── pr-validation-pipeline.yaml # PR quality checks
│   │   ├── inner-loop-pipeline.yaml    # Developer feedback loop
│   │   └── promotion-pipeline.yaml     # Atomic release promotion
│   │
│   └── triggers/                       # Webhook Triggers (Wave 3)
│       ├── github-eventlistener.yaml   # EventListener + Route
│       ├── cac-trigger.yaml            # CaC TriggerBinding/Template
│       ├── pr-trigger.yaml             # PR TriggerBinding/Template
│       └── promotion-trigger.yaml      # Promotion TriggerBinding/Template
│
└── dev-spaces/                         # Developer Workspaces (Wave 4)
    └── (future - not yet implemented)
```

## Resource Counts

| Category | Count | Purpose |
|----------|-------|---------|
| ArgoCD Applications | 8 | Bootstrap + 7 child apps |
| Namespaces | 4 | aap-dev, aap-qa, aap-prod, dev-tools |
| Operator Subscriptions | 4 | 3x AAP (namespace-scoped), 1x Pipelines (cluster-scoped) |
| OperatorGroups | 3 | One per AAP namespace |
| ServiceAccounts | 4 | tekton-cac-sa, tekton-promotion-sa, tekton-pr-sa, tekton-inner-loop-sa |
| Roles & RoleBindings | 8 | 4 roles + 4 bindings |
| AutomationController CRs | 3 | dev, qa, prod |
| Tekton Tasks | 8 | Reusable building blocks |
| Tekton Pipelines | 4 | CaC, PR, Inner Loop, Promotion |
| EventListeners | 1 | GitHub webhook listener |
| TriggerBindings/Templates | 6 | 3 bindings + 3 templates |
| Routes | 1 | EventListener exposure |

**Total Kubernetes Resources**: ~43 resources managed by ArgoCD

## Sync Wave Strategy

Resources deploy in this order automatically:

```
Wave -10: root-app.yaml (manually applied)
    ↓
Wave -3:  4 Namespaces created
    ↓
Wave -2:  3 OperatorGroups + 4 Operator Subscriptions installed
          (AAP: namespace-scoped in aap-dev/qa/prod, Pipelines: cluster-scoped)
    ↓
Wave -1:  4 ServiceAccounts + 4 Roles + 4 RoleBindings
    ↓
Wave 0:   3 AutomationController CRs deployed
    ↓
Wave 1:   8 Tekton Tasks created
    ↓
Wave 2:   4 Tekton Pipelines created
    ↓
Wave 3:   Tekton Triggers (EventListeners) created + Route
    ↓
Wave 4:   (Future: Dev Spaces configuration)
```

**Total Sync Time**: ~10-15 minutes from root-app.yaml to fully operational

## GitOps Compliance

### Constitution Article I: Law of GitOps ✓

- **Single Source of Truth**: All cluster state in this repository
- **No Manual Changes**: ArgoCD auto-sync enabled on all Applications
- **Auditability**: Git log provides complete audit trail

### Managed by ArgoCD

✅ All YAML files in this repository are managed by ArgoCD  
✅ Changes pushed to Git are automatically synced to cluster  
✅ Manual cluster changes are detected and reverted (self-heal)  
✅ Deletions in Git trigger resource pruning in cluster

### Not Managed by ArgoCD

❌ OpenShift GitOps Operator installation (manual prerequisite)  
❌ Initial secrets (created before bootstrap)  
❌ AAP API tokens (generated after AAP instances running)

## File Naming Conventions

- **Applications**: `*-app.yaml` - ArgoCD Applications
- **Resources**: `{resource-name}.yaml` - Single or grouped resources
- **Triggers**: `{pipeline}-trigger.yaml` - TriggerBinding + TriggerTemplate pairs
- **Tasks**: `{task-name}-task.yaml` - Reusable Tekton Tasks
- **Pipelines**: `{pipeline-name}-pipeline.yaml` - Complete pipeline definitions

## Labels

All resources include standardized labels:

```yaml
labels:
  app: tekton                    # Component: tekton, aap, argocd
  environment: dev               # Environment: dev, qa, prod (where applicable)
  managed-by: argocd             # All resources managed by ArgoCD
  pipeline-type: quality-gate    # Pipeline classification
```

## Annotations

Sync waves control deployment order:

```yaml
annotations:
  argocd.argoproj.io/sync-wave: "0"  # Range: -10 to 4
```

## Next Steps

1. ✅ **Completed**: Repository structure created
2. 🔄 **Next**: Push to Git (`git@github.com:djdanielsson/rh1-cluster-config.git`)
3. 🔄 **Next**: Follow DEPLOYMENT.md to bootstrap platform
4. 🔄 **Next**: Populate other 4 repositories (aap-config-as-code, etc.)

---

**Repository Type**: GitOps Platform Configuration  
**Pattern**: Application of Applications  
**Tool**: OpenShift GitOps (ArgoCD)  
**Automation Level**: 95% (only 2 manual commands required)

