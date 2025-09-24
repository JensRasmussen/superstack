# Superstack

ASP.NET Core 8 web app deployed to Azure AKS via Terraform and ArgoCD with GitHub Actions.

## Flow
1. Terraform provisions AKS + ACR.
2. CI builds/tests .NET app.
3. Deploy job applies Terraform, builds container, pushes to ACR.
4. ArgoCD tracks `k8s/` manifests and syncs to cluster.

## Kubernetes Manifests
`k8s/deployment.yaml` and `k8s/service.yaml` define the app. The deployment image tag is patched in pipeline; ArgoCD then reconciles.

## ArgoCD Application
Defined in `argocd/application.yaml`. Repo URL already set. Apply in cluster:
```
kubectl apply -f argocd/application.yaml
```

## Required GitHub Secrets
| Secret | Purpose |
| ------ | ------- |
| `AZURE_CREDENTIALS` | JSON from `az ad sp create-for-rbac --sdk-auth` for Terraform + Azure CLI login. |
| `ARGOCD_SERVER` | (Optional) Base URL of ArgoCD API (e.g. https://argocd.example.com). |
| `ARGOCD_USERNAME` | ArgoCD login username. |
| `ARGOCD_PASSWORD` | ArgoCD login password. |

Example create service principal:
```
az ad sp create-for-rbac --name superstack-sp --role Contributor --scopes /subscriptions/<subId> --sdk-auth
```
Store output JSON as `AZURE_CREDENTIALS` secret.

## Local Terraform
```
cd terraform
terraform init
terraform apply
```

## Build Image Locally (optional)
```
dotnet publish -c Release -o out
az acr login --name <acrName>
docker build -t <acrName>.azurecr.io/superstack-web:dev .
docker push <acrName>.azurecr.io/superstack-web:dev
```

## Notes
- Ensure ArgoCD has repo access (public repo OK; for private add repo credentials in ArgoCD).
- Adjust replica count, resource limits as needed.
- For custom domains/ingress add an Ingress manifest and controller.
