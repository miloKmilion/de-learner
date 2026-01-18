# Terraform

The software focuses in cloud platform like GCP or AWS and sets the infrastructure needed for the code can live and software runs.

> Definition:
> It is an infrastructure as code tool that lets you define both cloud and on-prem resources in human readable configuration files that you can version, reuse and share.
> You can then use a consistent workflow to provision and manage all of your infgrastructure throughout its lifecycle.

## Why Terraform?

- Keeps track of the infrastructure while keeping the simplicity of the process.
- Easy collaboration, since is a file. It is easy to keep track of changes and the software development process.
- Reproducibility, since we can create environments to modify the software before its release in production
- Ensure resources are remove, since the it is easy to build and remove once the process is complete without expending extra resources.

### Important

- Terraform does not manage and update code on infrastructure.
- Does not gives the ability to change immutable resources. Like modifying virtual machines, or buckets.
- Not used to manage resources not defined in your terraform files.

### Terraform map

Having the project in the local machine with terraform in it --> A provider is needed, with different services that allows you to connect with the cloud.

Terraform will use that provider to connect. However, it is necessary to perform certain verifications to allow such connection.

### What are providers

Code that allows terraform to communicate to manage resources on:

    * AWS
    * GCP
    * AZURE
    * Kubernetes
    * ETC.

### Key Terraform Commands

- init: Get the providers needed.
- plan: Will tell you what I do and the resources that will be created.
- Apply: Do what is in the tf files. And build the tf space
- Destroy: Remove everything defined in the tf files.

## Terraform Basics

Initially, we need to set up a way to communicate the local machine with our provider (AWS, GCP) and be able to create resources. To do this we need to create a service account, which is similar to a user account but it doesn't need to log in to.

For example, the user account has a series of permissions such as open a document, run python, whereas a service account will be used solely by the software to run programs and code.

## Cloud Service Account Setup

### GCP — Create a Service Account

1. Go to the **Google Cloud Console** → **IAM & Admin** → **Service Accounts**.
2. Click **Create Service Account**.
3. Give it a **Name** and **Description** (e.g., `svc-myapp`).
4. Assign the **roles** it needs (e.g., `Storage Object Viewer`, `Pub/Sub Publisher`).
5. Click **Continue → Done**.
6. On the service account list, click your new account → **Keys** → **Add Key** → **Create new key**.
7. Select **JSON** and download the file.
8. Store the key file securely — **do not commit it to version control**.

---

### AWS — Create a Service Account (IAM User)

> In AWS, a “service account” is usually an **IAM user** (for external systems) or an **IAM role** (for AWS services).

#### Option 1: IAM User (for external services, scripts, CI/CD)

1. Sign in to the **AWS Management Console** → **IAM** → **Users**.
2. Click **Create user** and enter a name (e.g., `svc-myapp`).
3. **Uncheck** console access unless you need to log in via browser.
4. Click **Next** and attach the necessary policies (e.g., `AmazonS3ReadOnlyAccess`).
5. Finish creating the user.
6. Open the user’s **Security credentials** tab → **Create access key** → **Application running outside AWS**.
7. Download the `.csv` file with `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
8. Store these securely (e.g., environment variables, AWS Secrets Manager).

#### Option 2: IAM Role (for AWS Lambda, EC2, Step Functions)

1. Go to **IAM** → **Roles** → **Create role**.
2. Select **AWS service** as the trusted entity and choose the service (e.g., Lambda).
3. Attach the required policies.
4. Name the role (e.g., `lambda-svc-myapp`) and create it.
5. Assign this role when creating or updating your AWS resource.

---

## Cost Safety & Free Tier Usage

### GCP Free Tier Highlights

- **Cloud Functions**: 2M invocations/month free.
- **Cloud Storage**: 5 GB/month free (US regions).
- **BigQuery**: 1 TB query & 10 GB storage/month free.
- **Firestore**: 50,000 reads/writes & 1 GB storage free.

**Tips to Avoid Charges:**

- Always select **free tier-eligible regions**.
- Delete unused resources.
- Enable **Budgets & Alerts** in **Billing → Budgets & alerts**.

---

### AWS Free Tier Highlights

- **AWS Lambda**: 1M requests/month free + 400,000 GB-seconds compute.
- **Amazon S3**: 5 GB standard storage free.
- **Amazon EC2**: 750 hours/month for `t2.micro`/`t3.micro` (12 months only).
- **DynamoDB**: 25 GB storage & 25M reads/writes/month free.
- **Step Functions**: 4,000 state transitions/month free.

**Tips to Avoid Charges:**

- Use **AWS Budgets** to alert at $1 spend.
- Prefer **Roles** over IAM users with keys for AWS services.
- Delete EC2, RDS, or S3 buckets when not in use.
- Stay within **free tier quotas** — check the [AWS Free Tier Dashboard](https://console.aws.amazon.com/billing/home?#/freetier).

---

## AWS Service Account for Terraform

This creates a dedicated IAM user that Terraform will use to deploy AWS resources.

---

### Step 1 — Create an IAM User for Terraform

1. Sign in to the **AWS Management Console** as an administrator.
2. Go to **IAM → Users → Create user**.
3. **User name**: `terraform-deployer` (or similar).
4. **Access type**: Uncheck console access (Terraform doesn't need to log in to the console).
5. Click **Next** and attach permissions:
   - Option 1 (simple): Attach the AWS managed policy **AdministratorAccess** _(not recommended for production)_.
   - Option 2 (secure): Attach only the specific policies Terraform needs (e.g., `AmazonS3FullAccess`, `AmazonEC2FullAccess`).
6. Click **Next → Create user**.

---

### Step 2 — Generate Access Keys

1. Open the new user's page → **Security credentials**.
2. Under **Access keys**, click **Create access key**.
3. Select **Command Line Interface (CLI)** as the use case.
4. Download the `.csv` file containing:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

---

### Step 3 — Configure Terraform to Use This Account

#### Option 1: Local Environment Variables

```bash
    export AWS_ACCESS_KEY_ID=your_access_key_id
    export AWS_SECRET_ACCESS_KEY=your_secret_access_key
    export AWS_DEFAULT_REGION=us-east-1
```

It is necessary to be mindful of the permissions since they can intertwine. Example a bucket permission should be isolated from the terraform.

For AWS:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3FullAccess",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    },
    {
      "Sid": "EC2FullAccess",
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    },
    {
      "Sid": "AthenaGlueAccess",
      "Effect": "Allow",
      "Action": ["athena:*", "glue:*"],
      "Resource": "*"
    }
  ]
}
```

One important thing is never to show the credentials. Since it can be used to run processes that will be charged. One comparison to this is an API key for an app or an SSH key.

The next step is to connect our provider with the lcoal machine, In GCP we export the JSON file that will be parsed in our project however, in AWS:

## AWS Credentials for Terraform

Terraform needs AWS credentials to deploy resources.
In AWS, this is done using an **IAM user’s Access Key ID** and **Secret Access Key**.

---

### 1. Create an Access Key in AWS

1. Sign in to the [AWS Console](https://console.aws.amazon.com/).
2. Go to **IAM → Users** and select your Terraform user (e.g., `terraform-deployer`).
3. Open the **Security credentials** tab.
4. Scroll to **Access keys** → **Create access key**.
5. Choose **Application running outside AWS**.
6. Copy or download the:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
     > ⚠️ The secret key is shown only once — download the `.csv` or save it securely.

---

### 2. Provide Keys to Terraform

#### Option A — Environment Variables (Recommended)

```bash
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
export AWS_DEFAULT_REGION=us-east-1
```

A good practice is to use tools to manage the AWS keys, such as aws-sso-util and creating the folder:
`~/.aws/config` and adding the following:

```ini
[profile terraform]
sso_start_url = https://d-c3677a0f48.awsapps.com/start
sso_region = eu-north-1
sso_account_id = 836901249007
sso_role_name = AdministratorAccess
region = eu-north-1
output = json
```

## Extensions

From the widget panel, the terraform package has all the highlights and required syntax needed to complete and catch errors.

## Main.tf

This fail is the main entrypoint to our terraform service. It contains all the provider and services that we require to run our code.

### Provider configuration

```tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "eu-north-1"   # change to your preferred region
  profile = "terraform"   # this must match your AWS SSO profile in ~/.aws/config
}
```

### GCP vs AWS: Project / Account Mapping

- **GCP**

  - All resources live inside a **Project** (identified by `project_id`).
  - The project defines **billing, IAM roles, and resource boundaries**.

- **AWS**
  - All resources live inside an **Account** (identified by a 12-digit `account_id`).
  - AWS doesn’t have a "project" object — the **account** is the main boundary for billing, IAM, and resources.
  - Resources are additionally scoped by **Region** (e.g., `eu-north-1`).
  - Terraform usually references a **profile** (from `~/.aws/config`) that contains credentials tied to that account.

✅ In practice:

- **GCP `project_id` ≈ AWS `account_id`**
- **GCP region/zone ≈ AWS region**

### Terraform init

This will read the providers information and create a set of extra files and folders such as the `lock.hcl` and the terraform subfolder will the provider hash.

### Adding a Bucket

AWS behaves different to GCP. While in GCP we need to add a provider for the bucket creation in AWS it is not needed since everything is linked to the IAM role created before

wWe can create the bucket directly in the AWS dashboard or:

```main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region  = "eu-north-1"   # Change to your preferred region
  profile = "terraform"    # Must match your AWS SSO profile
}

# ------------------------
# S3 Bucket
# ------------------------
resource "aws_s3_bucket" "data_lake_bucket" {
  bucket = "data-lake-dev-milokmilo"  # Must be globally unique
  force_destroy = true  # Allows bucket deletion even if objects exist

  tags = {
    Environment = "dev"
    Project     = "de-learner"
  }
}

# ------------------------
# S3 Versioning (separate resource)
# ------------------------
resource "aws_s3_bucket_versioning" "data_lake_bucket_versioning" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------
# S3 Lifecycle Rules
# ------------------------
resource "aws_s3_bucket_lifecycle_configuration" "data_lake_bucket_lifecycle" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  rule {
    id     = "delete-old-objects"
    status = "Enabled"

    filter {}  # Applies to all objects

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ---------------------------
# Athena database (BigQuery dataset equivalent)
# ---------------------------
resource "aws_athena_database" "dataset" {
  name   = "demo_dataset"
  bucket = aws_s3_bucket.data_lake_bucket.bucket
}
```
