# Terraform

The software focuses in cloud platform like GCP or AWS and sets the infrastructure needed for the code can live and software runs.

> Definition:
It is an infrastructure as code tool that lets you define both cloud and on-prem resources in human readable configuration files that you can version, reuse and share.
You can then use a consistent workflow to provision and manage all of your infgrastructure throughout its lifecycle.

## Why Terraform?

* Keeps track of the infrastructure while keeping the simplicity of the process.
* Easy collaboration, since is a file. It is easy to keep track of changes and the software development process.
* Reproducibility, since we can create environments to modify the software before its release in production
* Ensure resources are remove, since the it is easy to build and remove once the process is complete without expending extra resources.

### Important

* Terraform does not manage and update code on infrastructure.
* Does not gives the ability to change immutable resources. Like modifying virtual machines, or buckets.
* Not used to manage resources not defined in your terraform files.

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

* init: Get the providers needed.
* 