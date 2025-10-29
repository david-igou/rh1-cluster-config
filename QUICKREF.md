# Quick Reference Card - ArgoCD AAP Platform

## 🚀 Bootstrap Commands

```bash
# 1. Install OpenShift GitOps (one time)
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# 2. Deploy everything (one command)
oc apply -f argocd/root-app.yaml
```

## 📊 Status Checks

```bash
# ArgoCD Applications
oc get applications -n openshift-gitops

# AAP Instances
oc get automationcontroller -A

# Tekton Resources
oc get tasks,pipelines,eventlisteners -n dev-tools

# All Pods
oc get pods -n aap-dev
oc get pods -n aap-qa
oc get pods -n aap-prod
oc get pods -n dev-tools
```

## 🔗 Important URLs

```bash
# ArgoCD UI
echo "https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"

# AAP Instances
echo "Dev:  https://$(oc get route aap-dev -n aap-dev -o jsonpath='{.spec.host}')"
echo "QA:   https://$(oc get route aap-qa -n aap-qa -o jsonpath='{.spec.host}')"
echo "Prod: https://$(oc get route aap-prod -n aap-prod -o jsonpath='{.spec.host}')"

# Webhook URL
echo "https://$(oc get route github-webhook-listener -n dev-tools -o jsonpath='{.spec.host}')"
```

## 🔐 Secrets Management

```bash
# Get auto-generated AAP admin password
oc get secret aap-dev-admin-password -n aap-dev -o jsonpath='{.data.password}' | base64 -d
oc get secret aap-qa-admin-password -n aap-qa -o jsonpath='{.data.password}' | base64 -d
oc get secret aap-prod-admin-password -n aap-prod -o jsonpath='{.data.password}' | base64 -d

# Get webhook secret
oc get secret github-webhook-secret -n dev-tools -o jsonpath='{.data.secretToken}' | base64 -d

# Create AAP API token secret
oc create secret generic aap-dev-api-credentials \
  --from-literal=host="https://aap-dev-url" \
  --from-literal=token="your-token-here" \
  -n dev-tools
```

## 🔄 Common Operations

### Force ArgoCD Sync
```bash
oc patch application <app-name> -n openshift-gitops \
  --type merge \
  --patch '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

### Manual Pipeline Run
```bash
oc create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: manual-cac-
  namespace: dev-tools
spec:
  pipelineRef:
    name: cac-pipeline
  serviceAccountName: tekton-cac-sa
  params:
    - name: git-url
      value: https://github.com/djdanielsson/rh1-aap-config-as-code.git
    - name: git-revision
      value: main
    - name: target-environment
      value: dev
  workspaces:
    - name: source
      volumeClaimTemplate:
        spec:
          accessModes: [ReadWriteOnce]
          resources: {requests: {storage: 1Gi}}
    - name: aap-credentials
      secret: {secretName: aap-dev-api-credentials}
EOF
```

### Watch Pipeline Logs
```bash
tkn pipelinerun logs -f -n dev-tools $(tkn pipelinerun list -n dev-tools -o name | head -1)
```

### Rollback (Git)
```bash
git revert <commit-sha>
git push origin main
# ArgoCD will auto-sync in ~3 minutes
```

## 🐛 Troubleshooting

### Check ArgoCD Logs
```bash
oc logs -n openshift-gitops \
  -l app.kubernetes.io/name=openshift-gitops-application-controller \
  --tail=50
```

### Check AAP Operator
```bash
oc logs -n openshift-operators \
  -l control-plane=controller-manager \
  --tail=50
```

### Check Pipeline Failure
```bash
tkn pipelinerun describe <run-name> -n dev-tools
tkn pipelinerun logs <run-name> -n dev-tools
```

### AAP Not Starting
```bash
oc describe automationcontroller aap-dev -n aap-dev
oc get pods -n aap-dev
oc logs <pod-name> -n aap-dev
```

## 📝 Git Workflow

```bash
# 1. Make changes
vi tekton/pipelines/cac-pipeline.yaml

# 2. Commit & push
git add .
git commit -m "Update CaC pipeline timeout"
git push origin main

# 3. Watch ArgoCD sync (automatic within 3 minutes)
watch oc get applications -n openshift-gitops

# Or force immediate sync
oc patch application tekton-pipelines -n openshift-gitops \
  --type merge \
  --patch '{"operation":{"sync":{}}}'
```

## 📈 Monitoring

### Application Health
```bash
oc get applications -n openshift-gitops \
  -o custom-columns=NAME:.metadata.name,STATUS:.status.sync.status,HEALTH:.status.health.status
```

### Resource Usage
```bash
# AAP pods
oc adm top pods -n aap-dev
oc adm top pods -n aap-qa
oc adm top pods -n aap-prod

# Tekton resources
oc adm top pods -n dev-tools
```

### Pipeline Runs
```bash
# List recent runs
tkn pipelinerun list -n dev-tools --limit 10

# Pipeline success rate
tkn pipelinerun list -n dev-tools -o json | \
  jq '[.items[].status.conditions[0].status] | group_by(.) | map({status: .[0], count: length})'
```

## 🔗 Repository URLs

- **cluster-config**: `https://github.com/djdanielsson/rh1-cluster-config.git`
- **aap-config-as-code**: `https://github.com/djdanielsson/rh1-aap-config-as-code.git`
- **custom-collection**: `https://github.com/djdanielsson/rh1-custom-collection.git`
- **ee**: `https://github.com/djdanielsson/rh1-ee.git`
- **release-manifest**: `https://github.com/djdanielsson/rh1-release-manifest.git`

## 📚 Documentation Links

- **Full Deployment Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Repository Structure**: [STRUCTURE.md](STRUCTURE.md)
- **Architecture Details**: [README.md](README.md)
- **Quickstart**: [../specs/001-cloud-native-ansible-lifecycle/quickstart.md](../specs/001-cloud-native-ansible-lifecycle/quickstart.md)

---

**Tip**: Bookmark this file for quick reference during operations!

