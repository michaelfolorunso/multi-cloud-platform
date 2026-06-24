# NexCloud — Multi-Cloud Enterprise Infrastructure Platform

A production-grade infrastructure platform that deploys a real SaaS application, TaskFlow Pro, simultaneously across AWS (EKS) and GCP (GKE). Everything is provisioned through Terraform, with full CI/CD automation and live observability.

The goal of this project was to actually run the same application on two clouds at once, not just talk about doing it. That meant solving real problems: networking that differs between AWS and GCP, IAM models that work completely differently, a CI/CD pipeline that has to push images to two separate registries, and a monitoring stack that needs to come up cleanly no matter which cluster it's pointed at.

**Live demo:** http://136.111.52.102 (GKE deployment). Infrastructure gets torn down between work sessions to manage cloud costs, so this may not always be live. Screenshots further down show the app and dashboards running.

**Monitoring dashboard:** http://130.211.231.20 (Grafana, same availability caveat as above)

## What's actually in here

- Terraform for both AWS and GCP, written as separate modules rather than one shared abstraction, because the two clouds don't map onto each other cleanly enough for that to be worth it
- A real three-service app: a FastAPI backend, a React frontend, and a background worker that processes jobs off a Redis queue
- A GitHub Actions pipeline that detects which service actually changed, builds only what's needed, and pushes to ECR and Artifact Registry in the same run
- Prometheus and Grafana running against both clusters, with Alertmanager wired up to actual alert rules, not just a dashboard for show
- Security choices that are explained in the code itself rather than just applied silently: least-privilege IAM, secrets that never touch the codebase, private database networking, non-root containers

## Architecture

```
                          GitHub Actions
                       (build, scan, push, deploy)
                                |
              -----------------------------------
              |                                 |
         AWS (EKS)                         GCP (GKE)
         VPC, 3 AZs                         VPC, regional subnet
         public + private subnets          GKE cluster (auto multi-zone)
         EKS nodes in private subnets      Cloud SQL (private IP only)
         RDS (private IP only)             Secret Manager
         NAT gateway                       Artifact Registry
         ECR
         Secrets Manager
         IRSA / OIDC for pod auth
              |                                 |
              -----------------------------------
                                |
                    Same app, both clouds
              React -> FastAPI -> Postgres + Redis
                       Background worker
                                |
                      Prometheus -> Grafana
                       Alertmanager -> Slack
```

Both clouds run the same container images, built once per pipeline run and pushed to both registries, then deployed independently. If one cloud's deploy step fails, the other still goes through. More on why that matters below.

## Stack

| Layer | What's used |
|---|---|
| Infrastructure as Code | Terraform, separate AWS and GCP configurations |
| Container orchestration | Amazon EKS, Google GKE |
| Application | FastAPI, React, PostgreSQL, Redis |
| Registries | Amazon ECR, GCP Artifact Registry |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus 2.51.2, Grafana 10.4.2, Alertmanager 0.27.0 |
| Secrets | AWS Secrets Manager, GCP Secret Manager |

## Repo layout

```
terraform/
  aws/        VPC, EKS, RDS, ECR, IAM/IRSA, Secrets Manager
  gcp/        VPC, GKE, Cloud SQL, Artifact Registry, Secret Manager
kubernetes/
  manifests/  Deployments, services, configmaps shared across both clouds
app/
  backend/    FastAPI service
  frontend/   React app
  worker/     Background job processor
monitoring/
  prometheus/        Scrape config and alert rules
  grafana/           Dashboard provisioning
  alertmanager.yaml  Alert routing and Slack notifications
.github/workflows/
  deploy.yml  Build, scan, push, deploy to both clouds
```

## How the pipeline actually works

Every push to main kicks off four stages. First it checks which services changed using a git diff against the previous commit, so a frontend-only change doesn't trigger a backend rebuild. Then it builds and pushes images to both ECR and GCP Artifact Registry, tagged with the git commit SHA rather than just `latest`. Then it deploys to GKE and EKS as two separate jobs that don't depend on each other succeeding.

That last part isn't a design choice I made up front. It came out of a real problem: at one point the AWS account behind this project got closed, and the original pipeline treated AWS and GCP as one combined job. That meant a dead AWS credential was blocking GCP deployments too, even though GCP had nothing to do with the problem. I rewrote the pipeline so each cloud's job can fail on its own without taking the other one down with it.

## Monitoring

Prometheus finds pods and nodes through Kubernetes service discovery rather than a static list of targets, so anything new that comes up with the right annotation gets picked up automatically. There are six alert rules covering pod crash loops, HTTP error rate, memory pressure, CPU throttling, node health, and disk space on persistent volumes. Alertmanager groups related alerts together and routes them to Slack, and there's an inhibition rule so that if a node goes down, you don't also get paged separately for every pod that was running on it.

Grafana's Prometheus connection is set up automatically through a provisioning file mounted at startup, not clicked together through the UI. That means if the whole monitoring stack got deleted and redeployed from this repo right now, it would come back up fully wired without anyone touching a browser.

## Security choices

Both databases sit on private IPs only and are never reachable from the public internet. IAM is scoped tightly: Prometheus can only read cluster metadata, the app's service account can only read its one specific secret, and nodes only have read access to the registries they pull from. AWS pods authenticate through IRSA and OIDC, so there are no long-lived AWS keys sitting inside any pod. Container images run as a non-root user. ECR repositories use immutable tags, so once an image is pushed under a given tag it can't quietly be overwritten by a later push. Storage buckets on both clouds block public access, encrypt data at rest, and keep version history in case something gets deleted by mistake.

## What actually went wrong, and what I learned from it

Switching ECR to immutable tags was a deliberate security fix from an internal audit, but it broke the CI/CD pipeline immediately because the pipeline had been pushing every build under the same `latest` tag. Fixing one thing exposed a dependency I hadn't fully thought through. The two changes had to be made together, not separately.

The AWS account used for this project closed partway through, most likely related to free tier usage, and the original CI/CD setup didn't handle that gracefully at all. Instead of waiting on AWS support, I rewrote the pipeline so a dead AWS credential doesn't stop GCP from deploying. It's a more honest design anyway. A real multi-cloud setup shouldn't have one provider's billing issue take down deployments to a completely separate provider.

Mounting a single file into a directory using subPath broke on GKE with a "not a directory" error, because Kubernetes was trying to overlay a file where it expected a directory structure. The fix was to mount the whole ConfigMap as its own subdirectory instead of trying to inject one file into an existing one.

Kubernetes manifests get applied in the order they appear in the file. Putting a Namespace resource anywhere but first in a multi-document YAML file means anything that references that namespace fails before the namespace even exists.

## Running this yourself

```bash
git clone https://github.com/michaelfolorunso/multi-cloud-platform.git
cd multi-cloud-platform

cd terraform/gcp
terraform init
terraform apply -var-file="terraform.tfvars"

gcloud container clusters get-credentials nexcloud-gke-dev --region us-central1 --project nexcloud-platform

kubectl apply -f kubernetes/manifests/
kubectl apply -f monitoring/prometheus/
kubectl apply -f monitoring/alertmanager.yaml
kubectl apply -f monitoring/grafana/
```

The AWS side under terraform/aws/ follows the same pattern.

## Author

Michael Folorunso, Cloud and Platform Engineer
[LinkedIn](https://www.linkedin.com/in/michael-folorunso-a08a9316b) · [GitHub](https://github.com/michaelfolorunso)
