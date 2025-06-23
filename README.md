# DevOps CICD Project - Terraform & Jenkins Setup Guide

---

## 1. Create and Configure an EC2 Instance for Terraform

### Connect to the Terraform EC2 Instance

SSH into or use the AWS Console to connect to the EC2 instance provisioned for Terraform. Then enter the commands in the code blocks sequentially.

---

### Install Terraform

Run the following commands to install Terraform:
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y terraform
```

---

### Install AWS CLI
First, manually enter `sudo su`. Then enter in the following commands:
```bash
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
Lastly, `exit` from the root user.

---

### Configure AWS CLI Using IAM Access Keys

```bash
aws configure
```
Then enter:
- AWS Access Key ID: <ENTER YOUR ACCESS KEY HERE>
- AWS Secret Access Key: <ENTER YOUR SECRET KEY HERE>
- Default region: us-west-2
- Default output format: (leave blank)

---

### Get and Run Terraform Scripts
Clone the repo and apply Terraform configurations:
```bash
git clone https://github.com/jeremiahdy55/DevOps-CICDProject.git
cd DevOps-CICDProject/terraform
terraform init -upgrade

# Preview changes
terraform plan

# Apply infrastructure changes automatically
terraform apply -auto-approve
```

---

### Access Jenkins UI

At the end of the Terraform apply, note the Jenkins public IP address output, like
```bash
jenkins_public_ip = "##.###.###.###"
```
Open your browser and access Jenkins at:
```
http://<JENKINS_IP_ADDRESS>:8080/
```

---

## 2. Setup Jenkins Server and Pipeline

### Connect to the Jenkins EC2 Instance

SSH into or use the AWS Console to connect to the Jenkins EC2 instance provisioned by Terraform. Then retrive the initialAdminPassword:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
Use this password to login to the Jenkins UI.

---

### Jenkins Setup Steps

- Either create a new admin user or continue using the default admin user (requires initial admin password on each login)
- Install the **Recommended Plugins** when prompted

---

### Configure Jenkins Credentials

Navigate to:
```
Manage Jenkins > Credentials > System > Gloabl credentials
```
Add credentials for **Docker** and **GitHub**:
- ***Kind***: Username with password
- ***Username***: DockerHub/GitHub USERNAME
- ***Password***: DockerHub/GitHub PERSONAL ACCESS TOKEN
- ***ID***: `docker_hub_credentials` or `github_credentials` (*used in the Jenkinsfile*)
- ***Description*** : `docker_hub_credentials` or `github_credentials` (*used as outward-facing name in credentials list*)

---

### Create Jenkins Pipeline

Navigate to:
```
Jenkins Dashboard > New Item > Pipeline
```
Name your pipeline (used for Jenkins job identification purposes only, no real bearing on infrastructure provisioning)
- In Pipeline Section:
  - ***Definition***: Pipeline script from SCM
  - ***SCM***: Git
  - ***Repository URL***: `https://github.com/jeremiahdy55/DevOps-CICDProject.git`
  - ***Credentials***: `github_credentials`
  - ***Branches to build***: `*/main`
- Configure other stuff as needed (such as triggers, build retention policy, etc.)
- Click **Save**

---

## 3. Build and Deploy Microservices

Trigger the Jenkins pipeline that was just made:
- Manually (*Build Now*)
- Via configured triggers

This will build the Docker images, push them to Docker Hub, then pull those images to deploy to EKS worker nodes.

---

## 4. Access Microservices on EKS

Once deployed, to access microservices running on EKS worker nodes.
- Connect to Jenkins instances (SSH or connect via UI)
- Run: `kubectl get svc`
- Identify the `EXTERNAL-IP` for each microservice service (this is the outward-facing IP the LoadBalancer provides)
- Access the microservice via browser or API client call at: `http://<EXTERNAL-IP>:<SERVICE-PORT>/`
  - Note: each microservice listens on a different port ranging from `8081` to `8084`

---

### Summary

- Terraform provisions EC2 instances and configures Jenkins and Kafka on them
- Terraform provisions EKS cluster and worker nodes
- Terraform provisions VPC, IGW, Route Tables, Subnets, and Security Groups to allow:
  - Public access to Jenkins and Kafka servers
  - EKS cluster and worker node communication
  - EKS worker node-to-node communication
  - EKS cluster to trust Jenkins to run EKS commands (e.g. `kubectl ###`)
- Jenkins pipeline builds Docker images and deploys microservices to EKS
- LoadBalancer type services expost the microservices publicly.