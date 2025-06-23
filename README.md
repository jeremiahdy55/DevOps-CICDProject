# DevOps CICD Project - Terraform & Jenkins Setup Guide
---
## 1. Create and Configure an EC2 Instance for Terraform

### Connect to the Terraform EC2 Instance
Use the AWS Console to connect to the EC2 instance provisioned for Terraform. Then enter the commands in the code blocks sequentially.
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
```bash
sudo su
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
exit
```
---
### Configure AWS CLI Using IAM Access Keys
```bash
aws configure
```
Then enter:
AWS Access Key ID: <ENTER YOUR ACCESS KEY HERE>
AWS Secret Access Key: <ENTER YOUR SECRET KEY HERE>
Default region: us-west-2
Default output format: (leave blank)
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

## 1. Create and Configure an EC2 Instance for Terraform
