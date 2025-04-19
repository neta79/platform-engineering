FROM python:3.12 AS builder

RUN apt update && apt -y install \
	python3 \
	build-essential \
	python3-pip \
	python3-venv

RUN apt -y install wget unzip
COPY Makefile .
RUN make toolchain TOOLCHAIN_PREFIX=/toolchain
RUN echo 'PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /root/.bashrc
RUN echo ". /toolchain/bin/activate" >> /root/.bashrc

FROM python:3.12 AS base
COPY --from=builder /toolchain /toolchain
COPY --from=builder /root/.bashrc /root/.bashrc
RUN apt update && apt -y install vim less groff && echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
WORKDIR /src
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV TOOLCHAIN_PREFIX=/toolchain
ENV PATH=/toolchain/bin:$PATH
COPY entrypoint.sh /toolchain/entrypoint.sh
RUN chmod +x /toolchain/entrypoint.sh
ENTRYPOINT [ "/toolchain/entrypoint.sh" ]
CMD ["bash", "-i"]