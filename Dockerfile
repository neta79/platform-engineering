FROM python:3.12 AS builder

RUN apt update && apt -y install \
	python3 \
	build-essential \
	python3-pip \
	python3-venv

RUN apt -y install wget unzip
COPY Makefile .
RUN make toolchain TOOLCHAIN_PREFIX=/toolchain
RUN echo ". /toolchain/bin/activate" >> /etc/bash.bashrc
RUN echo "PS1='\h:\w\$ '" >> /etc/bash.bashrc
RUN echo "PS1='\[\033[01;31m\]  **** WATCH OUT ****  \[\033[00m\]YOU ARE root@\h:\w\$ '" >> /root/.bashrc
COPY entrypoint.sh /toolchain/entrypoint.sh
RUN chmod +x /toolchain/entrypoint.sh

FROM python:3.12 AS base
COPY --from=builder /toolchain /toolchain
COPY --from=builder /root/.bashrc /root/.bashrc
COPY --from=builder /etc/bash.bashrc /etc/bash.bashrc
RUN apt update && apt -y install vim less groff && echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
WORKDIR /src
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV TOOLCHAIN_PREFIX=/toolchain
ENV PATH=/toolchain/bin:$PATH
ENTRYPOINT [ "/toolchain/entrypoint.sh" ]
CMD ["bash", "-i"]