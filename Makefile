#####################################################
# VERSION SPECIFICATIONS
#####################################################
TOOLCHAIN_PREFIX 		?= /opt/toolchain
TOOLCHAIN_PROMPT 		?= pe
TOOLCHAIN_IMAGE_NAME 	?= platform-engineering
TOOLCHAIN_IMAGE_TAG 	?= latest
PYTHON 					?= python3
AWS_CLI_VERSION 		?= 2.25.14
AWSCDK_VERSION 			?= 2.1007.0
NODEJS_VERSION 			?= 20.18.2
NPM_VERSION				?= 11.3.0
TERRAFORM_VERSION 		?= 1.11.4
TERRAFORMCDK_VERSION 	?= 0.20.11
TERRAFORMCDK_PY_VERSION 	?= 0.20.11
TERRAFORMCDK_PY_AWS_PROVIDER_VERSION 	?= 19.50.0
TYPESCRIPT_VERSION      = 5.8.3
AWS_CDK_VERSION 		?= 2.1007.0
ANSIBLE_VERSION 		?= 11.4.0
PIPENV_VERSION 			?= 2024.4.1

ALL_TARGETS = \
	venv \
	pipenv \
	nodejs \
	typescript \
	terraform \
	terraform-cdk \
	aws-cli \
	aws-cdk \
	ansible

.PHONY: ${ALL_TARGETS} 

#####################################################
# COMMON DIRECTORIES AND SETTINGS
#####################################################
ARC_DIR=archives
BUILD_DIR=build

_TOOLCHAIN_PREFIX_check=${TOOLCHAIN_PREFIX}/.check
_TOOLCHAIN_IMAGE = ${TOOLCHAIN_IMAGE_NAME}:${TOOLCHAIN_IMAGE_TAG}
_PYTHON_VERSION_MAJOR_MINOR = $$(echo $$(${PYTHON} --version) | cut -d ' ' -f 2 | cut -d '.' -f 1-2)
ENV = PATH=${TOOLCHAIN_PREFIX}/bin:$$PATH . ${_VENV_activate};

# Common directory targets
${ARC_DIR}: 
	mkdir -p ${ARC_DIR}

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}

${_TOOLCHAIN_PREFIX_check}:
	mkdir -p ${TOOLCHAIN_PREFIX}
	touch ${_TOOLCHAIN_PREFIX_check}

#####################################################
# PYTHON ENVIRONMENT SETUP
#####################################################
_VENV_python = ${TOOLCHAIN_PREFIX}/bin/python3
_VENV_check = ${TOOLCHAIN_PREFIX}/.python
_VENV_activate = ${TOOLCHAIN_PREFIX}/bin/activate

${_VENV_check}:
	${PYTHON} -m venv --prompt "${TOOLCHAIN_PROMPT}" ${TOOLCHAIN_PREFIX}
	${_VENV_python} -m pip install --upgrade pip
	test -x ${_VENV_python}
	touch ${_VENV_check}

_PIPENV_check = ${TOOLCHAIN_PREFIX}/.pipenv-${PIPENV_VERSION}
_PIPENV_exe = ${TOOLCHAIN_PREFIX}/bin/pipenv

${_PIPENV_check}: 
	$(MAKE) ${_VENV_check}
	${ENV} pip3 install pipenv==${PIPENV_VERSION}
	test -x ${_PIPENV_exe}
	touch ${_PIPENV_check}

# Individual component targets
venv: ${_VENV_check}
pipenv: ${_PIPENV_check}

#####################################################
# NODEJS AND TYPESCRIPT SETUP
#####################################################
_NODEJS_archive=${ARC_DIR}/node-v${NODEJS_VERSION}-linux-x64.tar.xz
_NODEJS_url=https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.xz
_NODEJS_check = ${TOOLCHAIN_PREFIX}/.nodejs-${NODEJS_VERSION}
_NODEJS_exe = ${TOOLCHAIN_PREFIX}/bin/node
_NPM_check = ${TOOLCHAIN_PREFIX}/.npm-${NPM_VERSION}
_NPM_exe = ${TOOLCHAIN_PREFIX}/bin/npm

${_NODEJS_archive}: ${ARC_DIR}
	wget ${_NODEJS_url} -O ${_NODEJS_archive}
	test -f ${_NODEJS_archive}
	touch ${_NODEJS_archive}

${_NODEJS_check}: 
	$(MAKE) ${_TOOLCHAIN_PREFIX_check} ${_NODEJS_archive}
	tar xvJf ${_NODEJS_archive} --strip-components=1 -C ${TOOLCHAIN_PREFIX}
	test -x ${_NODEJS_exe}
	touch ${_NODEJS_check}

${_NPM_check}:
	$(MAKE) ${_NODEJS_check}
	${ENV} npm install --global npm@${NPM_VERSION}
	test -x ${_NPM_exe}
	touch ${_NPM_check}

# Individual component target
nodejs: ${_NODEJS_check} ${_NPM_check}

#####################################################
# TYPESCRIPT SETUP
#####################################################
_TYPESCRIPT_check = ${TOOLCHAIN_PREFIX}/.typescript-${TYPESCRIPT_VERSION}
_TYPESCRIPT_exe = ${TOOLCHAIN_PREFIX}/lib/node_modules/typescript/bin/tsc

${_TYPESCRIPT_check}: 
	$(MAKE) ${_NODEJS_check}
	${ENV} npm install --global typescript@${TYPESCRIPT_VERSION}
	test -x ${_TYPESCRIPT_exe}
	touch ${_TYPESCRIPT_check}

# Individual component target
typescript: ${_TYPESCRIPT_check}

#####################################################
# TERRAFORM SETUP
#####################################################
_TERRAFORM_archive=${ARC_DIR}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
_TERRAFORM_check=${TOOLCHAIN_PREFIX}/.terraform-${TERRAFORM_VERSION}
_TERRAFORM_url=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
_TERRAFORM_exe = ${TOOLCHAIN_PREFIX}/bin/terraform

${_TERRAFORM_archive}: ${ARC_DIR}
	wget ${_TERRAFORM_url} -O ${_TERRAFORM_archive}
	test -f ${_TERRAFORM_archive}
	touch ${_TERRAFORM_archive}

${_TERRAFORM_check}: 
	$(MAKE) ${_TERRAFORM_archive} ${BUILD_DIR}
	cd ${BUILD_DIR} \
		&& unzip -o ../${_TERRAFORM_archive} terraform \
		&& install -m 755 terraform ${_TERRAFORM_exe}
	test -x ${_TERRAFORM_exe}
	touch ${_TERRAFORM_check}

# Individual component target
terraform: ${_TERRAFORM_check}

#####################################################
# TERRAFORM CDK SETUP
#####################################################
_TERRACDK_check = ${TOOLCHAIN_PREFIX}/.cdktf-${TERRAFORMCDK_VERSION}
_TERRACDK_exe = ${TOOLCHAIN_PREFIX}/lib/node_modules/cdktf-cli/bundle/bin/cdktf
_TERRACDK_PY_check = ${TOOLCHAIN_PREFIX}/.cdktf_py-${TERRAFORMCDK_PY_VERSION}
_TERRACDK_PY_dir = ${TOOLCHAIN_PREFIX}/lib/python${_PYTHON_VERSION_MAJOR_MINOR}/site-packages/cdktf
_TERRACDK_PY_AWS_PROVIDER_check = ${TOOLCHAIN_PREFIX}/.cdktf_py_aws_provider-${TERRAFORMCDK_PY_AWS_PROVIDER_VERSION}
_TERRACDK_PY_AWS_PROVIDER_dir = ${TOOLCHAIN_PREFIX}/lib/python${_PYTHON_VERSION_MAJOR_MINOR}/site-packages/cdktf_cdktf_provider_aws

${_TERRACDK_check}: 
	$(MAKE) ${_NODEJS_check} ${_TERRAFORM_check} ${_VENV_check}
	${ENV} npm install --global cdktf-cli@${TERRAFORMCDK_VERSION}
	test -x ${_TERRACDK_exe}
	touch ${_TERRACDK_check}

${_TERRACDK_PY_check}: 
	$(MAKE) ${_VENV_check}
	${ENV} pip3 install cdktf==${TERRAFORMCDK_PY_VERSION}
	test -d ${_TERRACDK_PY_dir}
	touch ${_TERRACDK_PY_check}

${_TERRACDK_PY_AWS_PROVIDER_check}:
	$(MAKE) ${_VENV_check}
	${ENV} pip3 install cdktf-cdktf-provider-aws==${TERRAFORMCDK_PY_AWS_PROVIDER_VERSION}
	test -d ${_TERRACDK_PY_AWS_PROVIDER_dir}
	touch ${_TERRACDK_PY_AWS_PROVIDER_check}

# Individual component target
terraform-cdk: ${_TERRACDK_check} ${_TERRACDK_PY_check} ${_TERRACDK_PY_AWS_PROVIDER_check}

#####################################################
# AWS TOOLS SETUP
#####################################################
_AWS_CLI_url=https://github.com/aws/aws-cli/archive/refs/tags/${AWS_CLI_VERSION}.tar.gz
_AWS_CLI_srcdir=${BUILD_DIR}/aws-cli-${AWS_CLI_VERSION}
_AWS_CLI_exe = ${TOOLCHAIN_PREFIX}/lib/aws-cli/bin/aws
_AWS_CLI_check = ${TOOLCHAIN_PREFIX}/.aws-cli-${AWS_CLI_VERSION}
_AWS_CLI_archive=${ARC_DIR}/aws-cli-${AWS_CLI_VERSION}.tar.gz

${_AWS_CLI_archive}: ${ARC_DIR}
	wget ${_AWS_CLI_url} -O ${_AWS_CLI_archive}
	test -f ${_AWS_CLI_archive}
	touch ${_AWS_CLI_archive}

${_AWS_CLI_srcdir}: ${_AWS_CLI_archive} ${BUILD_DIR}
	tar xvzf ${_AWS_CLI_archive} -C ${BUILD_DIR}

${_AWS_CLI_check}: 
	$(MAKE) ${_VENV_check} ${_AWS_CLI_srcdir} 
	${ENV} \
	cd ${_AWS_CLI_srcdir} \
		&& PYTHON=python3 ./configure --prefix=${TOOLCHAIN_PREFIX} --with-download-deps \
		&& make \
		&& make install \
		&& test -x ${_AWS_CLI_exe} \
		&& touch ${_AWS_CLI_check}

# Individual component target
aws-cli: ${_AWS_CLI_check}

#####################################################
# AWS CDK SETUP
#####################################################
_AWSCDK_check = ${TOOLCHAIN_PREFIX}/.awscdk-${AWSCDK_VERSION}
_AWSCDK_exe = ${TOOLCHAIN_PREFIX}/lib/node_modules/aws-cdk/bin/cdk

${_AWSCDK_check}: 
	$(MAKE) ${_NODEJS_check} ${_AWS_CLI_check}
	${ENV} npm install --global aws-cdk@${AWSCDK_VERSION}
	test -x ${_AWSCDK_exe}
	touch ${_AWSCDK_check}

# Individual component target
aws-cdk: ${_AWSCDK_check}

#####################################################
# ANSIBLE SETUP
#####################################################
_ANSIBLE_check = ${TOOLCHAIN_PREFIX}/.ansible-${ANSIBLE_VERSION}
_ANSIBLE_exe = ${TOOLCHAIN_PREFIX}/bin/ansible

${_ANSIBLE_check}: 
	$(MAKE) ${_VENV_check}
	${ENV} pip3 install ansible==${ANSIBLE_VERSION}
	${ENV} pip3 install jmespath
	test -x ${_ANSIBLE_exe}
	touch ${_ANSIBLE_check}

# Individual component target
ansible: ${_ANSIBLE_check}

#####################################################
# MAIN TARGETS FOR HUMAN USE
#####################################################
# Primary targets
toolchain: ${ALL_TARGETS}


_dirs: ${ARC_DIR} ${BUILD_DIR}


image:
	docker build . -t ${_TOOLCHAIN_IMAGE}
	@echo "add an easy runner alias to your .bashrc:"
	@echo "  alias pe=\"sh '$(shell pwd)/platform-engineering-wrapper.sh'\""

#####################################################
# CLEANUP
#####################################################
clean:
	- rm -fr \
		${_AWS_CLI_srcdir} \
		${_AWS_CLI_archive} \
		${_NODEJS_archive} \
		${_TERRAFORM_archive} ${BUILD_DIR}/terraform
	- rmdir ${BUILD_DIR}
	- rmdir ${ARC_DIR}
