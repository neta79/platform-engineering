#####################################################
# VERSION SPECIFICATIONS
#####################################################
TOOLCHAIN_PREFIX 		?= /opt/toolchain
TOOLCHAIN_PROMPT 		?= pe
TOOLCHAIN_IMAGE_NAME 	?= platform-engineering
TOOLCHAIN_IMAGE_TAG 	?= latest
PYTHON 					?= python3
AWS_CLI_VERSION 		?= 2.25.14
AWSCDK_VERSION 			?= 2.1010.0
NODEJS_VERSION 			?= 20.18.2
NPM_VERSION				?= 11.3.0
TERRAFORM_VERSION 		?= 1.11.4
TERRAFORMCDK_VERSION 	?= 0.20.11
TERRAFORMCDK_PY_VERSION ?= 0.20.11
TERRAFORMCDK_PY_AWS_PROVIDER_VERSION ?= 19.50.0
TYPESCRIPT_VERSION      ?= 5.8.3
ANSIBLE_VERSION			?= 11.4.0
AWS_BOTO3_VERSION		?= 1.37.37

PIP_PACKAGES			= \
	ansible==${ANSIBLE_VERSION} \
	boto3==${AWS_BOTO3_VERSION} \
	cdktf==${TERRAFORMCDK_VERSION} \
	cdktf-cdktf-provider-aws==${TERRAFORMCDK_PY_AWS_PROVIDER_VERSION} \
	jmespath==1.0.1 \
	pipenv==2024.4.1 

NPM_PACKAGES = \
	typescript@${TYPESCRIPT_VERSION} \
	aws-cdk@${AWSCDK_VERSION} \
	cdktf-cli@${TERRAFORMCDK_VERSION}

ALL_TARGETS = \
	venv \
	nodejs \
	terraform \
	aws-cli \
	pip_packages

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


# Parse the PIP_PACKAGES list to generate dependency targets
PIP_PACKAGE_TARGETS = $(foreach pkg,$(PIP_PACKAGES),\
	${TOOLCHAIN_PREFIX}/.pip_$(shell echo $(pkg) | sed 's/==/_/g'))

# Target to install all pip packages
pip_packages: $(PIP_PACKAGE_TARGETS)


${TOOLCHAIN_PREFIX}/.pip_%: # format: ${TOOLCHAIN_PREFIX}/.pip_<package_name>_<version>
	@_PIP_PACKAGE_NAME=$$(echo $@ | sed 's|${TOOLCHAIN_PREFIX}/.pip_||' | cut -d '_' -f 1) && \
	 _PIP_PACKAGE_VERSION=$$(echo $@ | sed 's|${TOOLCHAIN_PREFIX}/.pip_||' | cut -d '_' -f 2) && \
	 _CHECK_FILE=${TOOLCHAIN_PREFIX}/.pip_$${_PIP_PACKAGE_NAME}-$${_PIP_PACKAGE_VERSION} && \
	 test -f $${_CHECK_FILE} || \
 	 $(MAKE) _pip_package_install _PIP_PACKAGE=$${_PIP_PACKAGE_NAME}==$${_PIP_PACKAGE_VERSION} _CHECK_FILE=$${_CHECK_FILE} 

_pip_package_install:
	@echo "installing ${_PIP_PACKAGE}"
	$(MAKE) ${_VENV_check}
	${ENV} pip3 install ${_PIP_PACKAGE}
	${ENV} pip3 freeze | grep "^${_PIP_PACKAGE}"
	touch ${_CHECK_FILE}


# Individual component targets
venv: ${_VENV_check}

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

# Parse the PIP_PACKAGES list to generate dependency targets
NPM_PACKAGE_TARGETS = $(foreach pkg,$(NPM_PACKAGES),\
	${TOOLCHAIN_PREFIX}/.npm_$(shell echo $(pkg) | sed 's/@/_/g'))

# Target to install all pip packages
npm_packages: $(NPM_PACKAGE_TARGETS)


${TOOLCHAIN_PREFIX}/.npm_%: # format: ${TOOLCHAIN_PREFIX}/.npm_<package_name>_<version>
	@_NPM_PACKAGE_NAME=$$(echo $@ | sed 's|${TOOLCHAIN_PREFIX}/.npm_||' | cut -d '_' -f 1) && \
	 _NPM_PACKAGE_VERSION=$$(echo $@ | sed 's|${TOOLCHAIN_PREFIX}/.npm_||' | cut -d '_' -f 2) && \
	 _CHECK_FILE=${TOOLCHAIN_PREFIX}/.npm_$${_NPM_PACKAGE_NAME}-$${_NPM_PACKAGE_VERSION} && \
	 test -f $${_CHECK_FILE} || \
 	 $(MAKE) _npm_package_install _NPM_PACKAGE=$${_NPM_PACKAGE_NAME}@$${_NPM_PACKAGE_VERSION} _CHECK_FILE=$${_CHECK_FILE} 

_npm_package_install:
	@echo "installing ${_NPM_PACKAGE}"
	$(MAKE) ${_NPM_check}
	${ENV} npm install --global ${_NPM_PACKAGE}
	${ENV} npm ls --global | grep "${_NPM_PACKAGE}"
	touch ${_CHECK_FILE}


${_NPM_check}:
	$(MAKE) ${_NODEJS_check}
	${ENV} npm install --global npm@${NPM_VERSION}
	test -x ${_NPM_exe}
	touch ${_NPM_check}

# Individual component target
nodejs: ${_NODEJS_check} ${_NPM_check}


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
