# Platform Engineering

A unified DevOps toolchain solution for infrastructure and deployment automation.

![Platform Engineering](https://img.shields.io/badge/Platform-Engineering-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Overview

Platform Engineering is a comprehensive solution designed to build and manage a consistent DevOps toolchain, combining Terraform, CDK for Terraform, AWS CDK, and Ansible in a controlled and predictable environment. This project addresses the challenge of maintaining consistent tool versions across different environments, streamlining the development and deployment workflows for infrastructure as code.

## Features

- **Unified Toolchain**: Curated set of DevOps tools with compatible versions
- **Containerized Environment**: Reproducible build and execution environment
- **Transparent Integration**: Seamless access to local credentials and SSH agents
- **Customizable Setup**: Configurable tool versions and installation paths
- **Consistent Experience**: Same toolchain across development and CI/CD environments

## Included Tools

The platform engineering toolchain includes:

- **Terraform** - Infrastructure as Code
- **Terraform CDK** - For defining infrastructure using Typescript, Python (With AWS provider)
- **AWS CLI** - Command line interface for AWS services
- **AWS CDK** - Cloud Development Kit for AWS
- **Ansible** - Configuration management and deployment
- **NodeJS & TypeScript** - Runtime and language support
- **Python & Pipenv** - Development environment and dependency management

## Quick Start

### Building the Toolchain

```bash
# Clone the repository
git clone <repository-url>
cd platform-engineering

# Build the toolchain image
make image

# Add an alias to your shell profile for easy access
echo "alias pe=\"sh '$(pwd)/platform-engineering-wrapper.sh'\"" >> ~/.bashrc
source ~/.bashrc
```

### Using the Toolchain

```bash
# Navigate to your infrastructure project
cd my-project

# Run terraform commands
pe terraform plan

# Execute ansible playbooks
pe ansible-playbook -i hosts.ini playbook.yml

# Run AWS CDK commands
pe cdk deploy
```

## Environment Customization

The toolchain can be customized by modifying environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `TOOLCHAIN_PREFIX` | Installation path | `/opt/toolchain` |
| `TOOLCHAIN_PROMPT` | Shell prompt prefix | `pe` |
| `TOOLCHAIN_IMAGE_NAME` | Docker image name | `platform-engineering` |
| `TOOLCHAIN_IMAGE_TAG` | Docker image tag | `latest` |
| `TERRAFORM_VERSION` | Terraform  | `1.11.4` |
| `TERRAFORMCDK_VERSION` | Terraform CDK (TS & Python)  | `0.20.11` |
| `TERRAFORMCDK_PY_AWS_PROVIDER_VERSION` | Terraform CDK Python AWS Provider  | `19.50.0` |
| `AWS_CLI_VERSION` | AWS CLI | `2.25.14` |
| `AWSCDK_VERSION` | AWS CDK | `2.1010.0` |
| `AWS_BOTO3_VERSION` | AWS Boto3 Python lib | `1.37.37` |
| `ANSIBLE_VERSION` | Ansible | `11.4.0` |

Modify the `Makefile` or override the relevant *`_VERSION` variable to customize built-in tool versions.

## Running in Docker

The toolchain can be run in a Docker container for isolated and reproducible environments:

```bash
# Build the Docker image
make image

# Run a command using the wrapper
pe terraform version
```

The wrapper script (`platform-engineering-wrapper.sh`) transparently handles:

- Volume mounting of project files
- SSH agent forwarding
- AWS credentials access
- Environment variable propagation

## Architecture

```
┌───────────────────────────┐
│ Platform Engineering Tool │
├───────────────────────────┤
│  ┌─────────┐  ┌─────────┐ │
│  │Terraform│  │AWS CDK  │ │
│  └─────────┘  └─────────┘ │
│  ┌─────────┐  ┌─────────┐ │
│  │CDKTF    │  │Ansible  │ │
│  └─────────┘  └─────────┘ │
├───────────────────────────┤
│Python/Node.js Environment │
└───────────────────────────┘
```

## Advanced Usage

### Local Development Environment

The toolchain requires the following prerequisites for local installation:

- **Python 3** (3.8 or newer recommended)
- **C/C++ compiler** and development tools for building Python extensions
- **wget** and **unzip** utilities for downloading and extracting components

Instead of using the Docker container, you can set up a local toolchain:

```bash
# Install required system dependencies (Ubuntu/Debian example)
sudo apt update && sudo apt install -y build-essential python3-dev python3-pip wget unzip

# Install toolchain locally
make toolchain TOOLCHAIN_PREFIX=$HOME/.local/toolchain

# Specify a particular Python interpreter (if needed)
make toolchain TOOLCHAIN_PREFIX=$HOME/.local/toolchain PYTHON=/usr/bin/python3.11

# Add the toolchain to your PATH
echo 'export PATH=$HOME/.local/toolchain/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

After installation, you can directly use the tools from your terminal:

```bash
# Use toolchain components directly
terraform --version
ansible --version
aws --version
```

### CI/CD Integration

In CI/CD pipelines, use the Docker image for consistent builds:

```yaml
# Example GitLab CI configuration
build:
  image: platform-engineering:latest
  script:
    - terraform init
    - terraform plan
    - terraform apply -auto-approve
```

## Host system security

**CAUTION:** This image is intended for supervised development environments. Usage in DevOps & GitOps pipelines, host-only or air-gapped development configurations are clearly the best fitting scenarios, however be mindful that using the "pe" Docker wrapper creates a significant security vulnerability in your system's trust chain. 

As it is with any other scenario where Docker is available, __never grant Docker execution credentials to untrusted users__. Doing so essentially provides them with a path to root-equivalent access on the host system, compromising your security posture and potentially leading to a complete security compromise of the host environment.

The wrapper enables root-mounting of arbitrary host paths, effectively circumventing standard user permission boundaries and containment mechanisms. This could lead to privilege escalation and unauthorized data access if misused.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

**Neta** - *Initial work and maintenance*
- GitHub: [Andrea Gronchi](https://github.com/neta79)
- Email: ne<!-- contact -->ta<!-- please don't -->@lo<!-- scrape -->gn<!-- this -->.in<!-- email -->fo

## Acknowledgments

- HashiCorp for Terraform
- AWS for CDK and CDK for Terraform
- Ansible community