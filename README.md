# RunAI Workload Automation

Automated RunAI workload submission using Kubernetes and cron scheduling. This project manages GPU workload submissions across multiple clusters and projects, with simulated GPU utilization for realistic testing and demonstration purposes.

## 🎯 Overview

This solution automatically submits RunAI training workloads to multiple clusters on a scheduled basis, avoiding business hours (8am-4pm Pacific). It's designed for:

- **Demo environments** - Simulate realistic GPU utilization patterns
- **Testing** - Automated workload submission for testing Run:ai features
- **Training** - Demonstrate Run:ai capabilities with consistent workloads

### Key Features

- ✅ **Automated Scheduling** - Runs every hour except 8am-4pm Pacific (business hours)
- ✅ **Multi-Cluster Support** - Submits workloads to multiple Run:ai clusters
- ✅ **Multi-Project Support** - Manages workloads across different projects/teams
- ✅ **Simulated GPU Utilization** - Uses fake-gpu-operator annotations for realistic metrics
- ✅ **Kubernetes Native** - Runs as a deployment with internal cron scheduling
- ✅ **Secure** - Credentials stored in Kubernetes secrets
- ✅ **Production Ready** - Includes logging, monitoring, and error handling

## 📊 Current Workload Configuration

The automation currently submits **16 workloads** requesting **32 GPUs total** per cluster:

| Project | Workloads | GPUs per Workload | Total GPUs |
|---------|-----------|-------------------|------------|
| **team-a** | 3 | 4 | 12 |
| **user-b** | 6 | 1-2 | 8 |
| **llm-training1** | 3 | 2-3 | 8 |
| **user-d** | 4 | 1 | 4 |
| **TOTAL** | **16** | - | **32** |

### Workload Details

**Team A** (12 GPUs):
- `train-team-a001` - 4 GPUs
- `train-team-a002` - 4 GPUs
- `train-team-a003` - 4 GPUs

**User B** (8 GPUs):
- `train-user-b001` - 1 GPU
- `train-user-b002` - 1 GPU
- `train-user-b003` - 1 GPU
- `train-user-b004` - 1 GPU
- `train-user-b11` - 2 GPUs
- `train-user-b12` - 2 GPUs

**LLM Training** (8 GPUs):
- `llm-training001` - 3 GPUs
- `llm-training002` - 3 GPUs
- `llm-training003` - 2 GPUs

**User D** (4 GPUs):
- `train-user-d001` - 1 GPU
- `train-user-d002` - 1 GPU
- `train-user-d003` - 1 GPU
- `train-user-d004` - 1 GPU

## ⏰ Cron Schedule

**Schedule**: `0 0-7,16-23 * * *`

This runs at the **top of every hour** during:
- **00:00 - 07:00** (Midnight to 7am Pacific)
- **16:00 - 23:00** (4pm to 11pm Pacific)

**Avoids**: 8am-4pm Pacific (business hours)

## 🎨 GPU Utilization Simulation

All workloads include the annotation:
```yaml
run.ai/simulated-gpu-utilization: "86-96"
```

This annotation works with the [Run:ai fake-gpu-operator](https://github.com/run-ai/fake-gpu-operator) to simulate GPU utilization between **86-96%** instead of a constant 100%. This creates more realistic metrics for:
- Grafana dashboards
- GPU utilization reports
- Capacity planning demonstrations
- Customer demos

## 🚀 Quick Start

### Prerequisites

1. **Kubernetes cluster** with Run:ai installed
2. **Run:ai credentials** (username and password)
3. **kubectl** configured to access your cluster
4. **Docker** (if building custom images)

### Installation

#### 1. Create Kubernetes Secret

Create a secret with your Run:ai credentials:

```bash
kubectl create secret generic runai-credentials \
  --from-literal=username='your-runai-username' \
  --from-literal=password='your-runai-password' \
  -n default
```

#### 2. Deploy the Workload Manager

```bash
# Clone the repository
git clone https://github.com/chadchappy/run-workload-cron.git
cd run-workload-cron

# Deploy to Kubernetes
kubectl apply -f container/runai-deployment.yaml
```

#### 3. Verify Deployment

```bash
# Check pod status
kubectl get pods -n default -l app=runai-workload-manager

# View logs
kubectl logs -n default -l app=runai-workload-manager --tail=100
```

## 🔧 Configuration

### Changing Clusters and Environments

To configure which clusters receive workload submissions, edit the `CLUSTERS` array in `container/runai-daemon.sh`:

<augment_code_snippet path="container/runai-daemon.sh" mode="EXCERPT">
```bash
# Clusters to process
CLUSTERS=("us-demo-west-1759242125" "us-demo-east")
```
</augment_code_snippet>

**To add/modify clusters:**

1. Edit `container/runai-daemon.sh` and update the `CLUSTERS` array:
   ```bash
   CLUSTERS=("your-cluster-1" "your-cluster-2" "your-cluster-3")
   ```

2. Update the Run:ai control plane URL in `container/docker-entrypoint.sh`:
   ```bash
   # Change these URLs to match your Run:ai control plane
   runai config set --cp-url https://your-runai-control-plane.com
   runai config set --auth-url https://your-runai-control-plane.com
   ```

3. Rebuild and push the container image:
   ```bash
   cd container
   docker buildx build --platform linux/amd64 \
     -f Dockerfile.daemon \
     -t ghcr.io/YOUR_USERNAME/runai-workload-manager:latest \
     --push .
   ```

4. Update the deployment to use your image:
   ```bash
   # Edit container/runai-deployment.yaml
   # Change the image line to:
   image: ghcr.io/YOUR_USERNAME/runai-workload-manager:latest
   ```

5. Redeploy:
   ```bash
   kubectl delete pod -n default -l app=runai-workload-manager
   ```

### Customizing Workloads

To modify which workloads are submitted, edit the `submit_workloads()` function in `container/runai-daemon.sh`:

<augment_code_snippet path="container/runai-daemon.sh" mode="EXCERPT">
```bash
# Team A Projects (3 workloads, 12 GPUs)
runai training submit train-team-a001 -i runai.jfrog.io/demo/quickstart-demo:latest -g 4 -p team-a --annotation run.ai/simulated-gpu-utilization="86-96"
```
</augment_code_snippet>

**Parameters you can customize:**
- **Workload name**: `train-team-a001`
- **Container image**: `-i runai.jfrog.io/demo/quickstart-demo:latest`
- **GPU count**: `-g 4`
- **Project**: `-p team-a`
- **GPU utilization range**: `--annotation run.ai/simulated-gpu-utilization="86-96"`

### Changing the Schedule

To modify when workloads are submitted, edit the cron schedule in `container/docker-entrypoint.sh`:

<augment_code_snippet path="container/docker-entrypoint.sh" mode="EXCERPT">
```bash
# Current: Every hour except 8am-4pm Pacific
echo "0 0-7,16-23 * * * . /etc/environment && /usr/local/bin/runai-daemon.sh >> /var/log/runai-daemon.log 2>&1" | crontab -u runai -
```
</augment_code_snippet>

**Common cron patterns:**
- `0 * * * *` - Every hour (all day)
- `0 0-7,16-23 * * *` - Every hour except 8am-4pm (current)
- `0 */2 * * *` - Every 2 hours
- `0 0 * * *` - Once per day at midnight
- `0 0 * * 0` - Once per week on Sunday

## 🐳 Container Image

**Official Image**: `ghcr.io/chadchappy/runai-workload-manager:latest`

This image includes:
- ✅ Ubuntu 22.04 base
- ✅ Run:ai CLI v2.23.8 (pre-installed)
- ✅ Cron daemon for scheduling
- ✅ Supervisor for process management
- ✅ Automated workload submission scripts

### Building Your Own Image

```bash
cd container

# For AMD64 (most Kubernetes clusters)
docker buildx build --platform linux/amd64 \
  -f Dockerfile.daemon \
  -t ghcr.io/YOUR_USERNAME/runai-workload-manager:latest \
  --push .

# For multi-architecture (AMD64 + ARM64)
docker buildx build --platform linux/amd64,linux/arm64 \
  -f Dockerfile.daemon \
  -t ghcr.io/YOUR_USERNAME/runai-workload-manager:latest \
  --push .
```

**Note**: You'll need the Run:ai CLI binary in the `container/` directory:
- `runai-cli` (AMD64) or `runai-cli-arm64` (ARM64)
- Download from your Run:ai control plane or contact Run:ai support

## 📖 Annotations Reference

### Simulated GPU Utilization

The `run.ai/simulated-gpu-utilization` annotation is used with the [Run:ai fake-gpu-operator](https://github.com/run-ai/fake-gpu-operator) to simulate realistic GPU metrics.

**Syntax:**
```bash
--annotation run.ai/simulated-gpu-utilization="MIN-MAX"
```

**Examples:**
- `"86-96"` - Random utilization between 86% and 96%
- `"70-90"` - Random utilization between 70% and 90%
- `"50-100"` - Random utilization between 50% and 100%

**How it works:**
1. The annotation is added to the workload submission
2. Run:ai propagates it to the pod metadata
3. The fake-gpu-operator reads the annotation
4. GPU metrics are simulated within the specified range
5. Metrics appear in Grafana dashboards and Run:ai UI

**Verification:**
```bash
# Check if annotation is applied to a pod
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.annotations.run\.ai/simulated-gpu-utilization}'
```

### Other Useful Annotations

You can add additional annotations to workloads:

```bash
runai training submit my-workload \
  -i my-image:latest \
  -g 2 \
  -p my-project \
  --annotation run.ai/simulated-gpu-utilization="86-96" \
  --annotation my-custom-annotation="my-value"
```

## 🔍 Monitoring and Troubleshooting

### View Logs

```bash
# View real-time logs
kubectl logs -n default -l app=runai-workload-manager -f

# View last 100 lines
kubectl logs -n default -l app=runai-workload-manager --tail=100

# View logs from specific pod
kubectl logs -n default <pod-name>
```

### Check Workload Status

```bash
# List all workloads across all projects
kubectl get pods -A | grep train-

# Check specific project
kubectl get pods -n runai-team-a

# View workload details with annotations
kubectl get pod <pod-name> -n <namespace> -o yaml
```

### Common Issues

**Issue**: Workloads not being submitted
- **Check**: Pod logs for authentication errors
- **Solution**: Verify `runai-credentials` secret is correct

**Issue**: Wrong cluster being targeted
- **Check**: `CLUSTERS` array in `runai-daemon.sh`
- **Solution**: Update cluster names and rebuild image

**Issue**: Cron not running at expected times
- **Check**: Timezone setting in deployment (should be `America/Los_Angeles`)
- **Solution**: Verify `TZ` environment variable in deployment

**Issue**: GPU utilization not simulated
- **Check**: fake-gpu-operator is installed in the cluster
- **Solution**: Install fake-gpu-operator from https://github.com/run-ai/fake-gpu-operator

### Manual Trigger

To manually trigger a workload submission cycle:

```bash
# Execute the daemon script inside the container
kubectl exec -n default -l app=runai-workload-manager -- /usr/local/bin/runai-daemon.sh
```

## 📁 Project Structure

```
run-workload-cron/
├── container/                          # Kubernetes deployment files
│   ├── Dockerfile.daemon              # Main container image
│   ├── docker-entrypoint.sh           # Container startup script
│   ├── runai-daemon.sh                # Workload submission script
│   ├── runai-deployment.yaml          # Kubernetes deployment manifest
│   ├── supervisord.conf               # Supervisor configuration
│   └── runai-cli                      # Pre-built Run:ai CLI binary
├── src/                               # Legacy TypeScript cron (optional)
│   ├── main.ts
│   ├── jobs/
│   └── utils/
├── config/
│   └── cron.json
└── README.md
```

## 🔐 Security Considerations

1. **Credentials**: Always store Run:ai credentials in Kubernetes secrets, never in code
2. **RBAC**: The deployment uses a service account with minimal permissions
3. **Image Security**: Use specific image tags instead of `latest` in production
4. **Network Policies**: Consider adding network policies to restrict pod communication
5. **Secret Rotation**: Regularly rotate Run:ai credentials

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test in a development cluster
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📝 License

This project is provided as-is for demonstration and testing purposes.

## 🆘 Support

For issues or questions:
- Open an issue on GitHub
- Contact your Run:ai support team
- Check Run:ai documentation: https://docs.run.ai

## 🔗 Related Resources

- [Run:ai Documentation](https://docs.run.ai)
- [Run:ai CLI Reference](https://docs.run.ai/v2.18/admin/researcher-setup/cli-install/)
- [fake-gpu-operator](https://github.com/run-ai/fake-gpu-operator)
- [Kubernetes Cron Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)