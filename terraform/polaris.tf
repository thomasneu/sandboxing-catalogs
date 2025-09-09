# ===============================
# POLARIS ICEBERG CATALOG SETUP
# ===============================

# Enable required APIs
resource "google_project_service" "sqladmin_api" {
  service = "sqladmin.googleapis.com"
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
}

# Service Account for Polaris to access GCS and Cloud SQL
resource "google_service_account" "polaris_sa" {
  account_id   = "${var.prefix}-polaris-sa-${random_string.suffix.result}"
  display_name = "Service Account for Polaris Catalog"
}

# IAM permissions for Polaris service account on unmanaged bucket workspace-1
resource "google_storage_bucket_iam_member" "polaris_bucket_admin" {
  bucket = google_storage_bucket.unmanaged_buckets["workspace-1"].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.polaris_sa.email}"
}

resource "google_storage_bucket_iam_member" "polaris_bucket_reader" {
  bucket = google_storage_bucket.unmanaged_buckets["workspace-1"].name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.polaris_sa.email}"
}

# NEW: Project-level permission to create buckets
resource "google_project_iam_member" "polaris_storage_admin" {
  project = var.project
  role    = "roles/storage.admin"    # ← Includes storage.buckets.create
  member  = "serviceAccount:${google_service_account.polaris_sa.email}"
}

# Cloud SQL Admin role - required for deploy-gcp.sh script
resource "google_project_iam_member" "polaris_sql_admin" {
  project = var.project
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.polaris_sa.email}"
}

# Compute Engine permissions - required for deploy-gcp.sh script
resource "google_project_iam_member" "polaris_compute_viewer" {
  project = var.project
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.polaris_sa.email}"
}

# IAM role to assume itself (required by deploy-gcp.sh)
resource "google_service_account_iam_member" "polaris_sa_token_creator" {
  service_account_id = google_service_account.polaris_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.polaris_sa.email}"
}

# VM Instance for Polaris
resource "google_compute_instance" "polaris_vm" {
  name         = "${var.prefix}-polaris-vm-${random_string.suffix.result}"
  machine_type = "e2-standard-2"  # Increased for better performance with Cloud SQL + Docker
  zone         = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.dbx_subnets["workspace-1"].self_link
    
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${file("~/.ssh/id_rsa.pub")}"
  }

  # Enhanced startup script with proper environment setup
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e  # Exit on any error
    
    # Logging function
    log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/polaris-prereqs.log
    }
    
    log "=== Installing Polaris Prerequisites ==="
    
    # Update system
    log "Updating system packages..."
    apt-get update
    
    # Remove any existing Docker packages to avoid conflicts
    log "Removing any conflicting Docker packages..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
        apt-get remove -y $pkg 2>/dev/null || true
    done
    
    # Install prerequisites
    log "Installing system prerequisites..."
    apt-get install -y \
      curl \
      wget \
      git \
      ca-certificates \
      gnupg \
      lsb-release \
      apt-transport-https \
      software-properties-common \
      vim \
      htop \
      unzip
    
    # Install Java 21 (required for Polaris)
    log "Installing OpenJDK 21 (required for Polaris)..."
    apt-get install -y openjdk-21-jdk
    
    # Set up Java environment using profile.d (best practice)
    log "Setting up Java environment using profile.d..."
    cat > /etc/profile.d/java.sh << 'JAVA_EOF'
#!/bin/bash
# Java environment for Polaris
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export PATH="$PATH:$JAVA_HOME/bin"
JAVA_EOF
    
    chmod +x /etc/profile.d/java.sh
    
    # Set up alternatives (Ubuntu way)
    log "Setting up Java alternatives..."
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-21-openjdk-amd64/bin/java 1
    update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-21-openjdk-amd64/bin/javac 1
    
    # Clean up any broken /etc/environment entries from previous runs
    log "Cleaning up any broken environment entries..."
    if [ -f /etc/environment ]; then
        sed -i '/export.*JAVA_HOME/d' /etc/environment
        sed -i '/export.*PATH.*JAVA_HOME/d' /etc/environment
        sed -i '/export.*PATH.*\$JAVA_HOME/d' /etc/environment
    fi
    
    # Source the Java environment for current session
    source /etc/profile.d/java.sh
    
    # Verify Java installation
    log "Java version: $(java -version 2>&1 | head -1)"
    
    # Create user 'thomas' if it doesn't exist
    if ! id thomas &>/dev/null; then
        log "Creating user 'thomas'..."
        useradd -m -s /bin/bash thomas
        # Set up home directory
        mkdir -p /home/thomas
        chown thomas:thomas /home/thomas
        
        # Add thomas to sudo group for convenience
        usermod -aG sudo thomas
        log "User 'thomas' created and added to sudo group"
    else
        log "User 'thomas' already exists"
    fi
    
    # Install Docker using official repository (ensure latest version 27+)
    log "Setting up Docker repository..."
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index and install Docker
    log "Installing Docker (latest version)..."
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Verify Docker version (should be 27+ for Polaris)
    docker_version=$(docker --version)
    log "Docker installed: $docker_version"
    
    # Start and enable Docker service
    log "Starting Docker service..."
    systemctl start docker
    systemctl enable docker
    
    # Wait for Docker to be ready
    sleep 5
    
    # Add users to docker group
    log "Adding users to docker group..."
    usermod -aG docker ubuntu 2>/dev/null || true
    usermod -aG docker thomas 2>/dev/null || true
    
    # Install Google Cloud SDK if not present
    if ! command -v gcloud &> /dev/null; then
        log "Installing Google Cloud SDK..."
        # Use the package manager method for better reliability
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        apt-get update
        apt-get install -y google-cloud-sdk
    fi
    
    # Test Docker installation
    log "Testing Docker installation..."
    if docker run --rm hello-world > /tmp/docker-test.log 2>&1; then
        log "Docker test successful"
    else
        log "Docker test failed - check /tmp/docker-test.log"
    fi
    
  EOF

  service_account {
    email  = google_service_account.polaris_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["polaris-server"]

  depends_on = [
    google_storage_bucket.unmanaged_buckets,
    google_service_account.polaris_sa,
    google_project_service.sqladmin_api,
    google_project_service.compute_api
  ]
}

# Firewall rule to allow access to Polaris (port 8181) and management (8182)
resource "google_compute_firewall" "polaris_firewall" {
  name    = "${var.prefix}-polaris-firewall-${random_string.suffix.result}"
  network = google_compute_network.dbx_private_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8181", "8182", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["polaris-server"]
}