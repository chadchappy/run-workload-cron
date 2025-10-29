#!/bin/bash

# RunAI Workload Management Daemon
# Executes RunAI commands on schedule

set -e

# Ensure RunAI CLI config path is set
export RUNAI_CLI_CONFIG_PATH=/home/runai/.runai

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${BLUE}[INFO]${NC} $1"; }
success() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${RED}[ERROR]${NC} $1"; }

# Clusters to process
CLUSTERS=("us-demo-west-1759242125" "us-demo-east")

# Function to delete existing workloads for a cluster
delete_workloads() {
    local cluster=$1
    log "Deleting existing workloads from cluster: $cluster"

    # Delete all workloads from all projects
    runai workload delete -p team-a -y train-team-a001 train-team-a002 train-team-a003 2>/dev/null || true
    runai workload delete -p user-b -y train-user-b001 train-user-b002 train-user-b003 train-user-b004 2>/dev/null || true
    runai workload delete -p llm-training1 -y llm-training001 llm-training002 llm-training003 2>/dev/null || true
    runai workload delete -p user-d -y train-user-d001 train-user-d002 train-user-d003 train-user-d004 2>/dev/null || true
    runai workload delete -p user-b -y train-user-b11 train-user-b12 2>/dev/null || true

    success "Completed workload deletion for cluster: $cluster"

    # Wait for deletions to fully process
    log "Waiting 10 seconds for deletions to complete..."
    sleep 10
}

# Function to submit workloads for a cluster
submit_workloads() {
    local cluster=$1
    log "Submitting workloads to cluster: $cluster"

    # Team A Projects (3 workloads, 12 GPUs)
    runai training submit train-team-a001 -i runai.jfrog.io/demo/quickstart-demo:latest -g 4 -p team-a --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-team-a001"
    runai training submit train-team-a002 -i runai.jfrog.io/demo/quickstart-demo:latest -g 4 -p team-a --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-team-a002"
    runai training submit train-team-a003 -i runai.jfrog.io/demo/quickstart-demo:latest -g 4 -p team-a --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-team-a003"

    # User B Projects (6 workloads, 8 GPUs)
    runai training submit train-user-b001 -i runai.jfrog.io/demo/quickstart-demo:latest -g 1 -p user-b --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-b001"
    runai training submit train-user-b002 -i runai.jfrog.io/demo/quickstart-demo:latest -g 1 -p user-b --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-b002"
    runai training submit train-user-b003 -i runai.jfrog.io/demo/quickstart-demo:latest -g 1 -p user-b --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-b003"
    runai training submit train-user-b004 -i runai.jfrog.io/demo/quickstart-demo:latest -g 1 -p user-b --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-b004"
    runai training submit train-user-b11 -i runai.jfrog.io/demo/quickstart-demo:latest -g 2 -p user-b --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-b11"
    runai training submit train-user-b12 -i runai.jfrog.io/demo/quickstart-demo:latest -g 2 -p user-b --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-b12"

    # LLM Training Projects (3 workloads, 8 GPUs)
    runai training submit llm-training001 -i runai.jfrog.io/demo/quickstart-demo:latest -g 3 -p llm-training1 --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit llm-training001"
    runai training submit llm-training002 -i runai.jfrog.io/demo/quickstart-demo:latest -g 3 -p llm-training1 --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit llm-training002"
    runai training submit llm-training003 -i runai.jfrog.io/demo/quickstart-demo:latest -g 2 -p llm-training1 --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit llm-training003"

    # User D Projects (4 workloads, 4 GPUs)
    runai training submit train-user-d001 -i runai.jfrog.io/demo/quickstart-demo:latest -g 1 -p user-d --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-d001"
    runai training submit train-user-d002 -i runai.jfrog.io/demo/quickstart-demo:latest -g 1 -p user-d --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-d002"
    runai training submit train-user-d003 -i runai.jfrog.io/demo/quickstart-demo:latest -g 1 -p user-d --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-d003"
    runai training submit train-user-d004 -i runai.jfrog.io/demo/quickstart-demo:latest -g 1 -p user-d --annotation run.ai/simulated-gpu-utilization="86-96" || warn "Failed to submit train-user-d004"

    success "Completed workload submission for cluster: $cluster"
}

# Main execution
main() {
    log "🚀 Starting RunAI workload management cycle"
    
    # Check if environment variables are set
    if [ -z "$RUNAI_USER" ] || [ -z "$RUNAI_PASSWORD" ]; then
        error "RUNAI_USER and RUNAI_PASSWORD environment variables must be set"
        exit 1
    fi

    # Verify RunAI CLI is available
    if ! command -v runai &> /dev/null; then
        error "RunAI CLI not found in PATH"
        exit 1
    fi

    # Check RunAI CLI version
    log "RunAI CLI version: $(runai version)"
    
    # Login to RunAI
    log "Logging into RunAI..."
    if runai login user -u "$RUNAI_USER" -p "$RUNAI_PASSWORD"; then
        success "Successfully logged into RunAI"
    else
        error "Failed to login to RunAI"
        exit 1
    fi
    
    # Process each cluster
    for cluster in "${CLUSTERS[@]}"; do
        log "Processing cluster: $cluster"

        if runai cluster set "$cluster"; then
            success "Successfully set cluster: $cluster"
            delete_workloads "$cluster"
            submit_workloads "$cluster"
        else
            error "Failed to set cluster: $cluster"
            continue
        fi
    done
    
    success "🎉 RunAI workload management cycle completed successfully!"
    log "Total workloads submitted: 16 per cluster (32 total)"
    log "Total GPUs requested: 30 per cluster (60 total)"
}

# Execute main function
main "$@"
