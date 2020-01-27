FROM ubuntu:18.04

ENV TF_VERSION 0.12.19

LABEL ubuntu="18.04"
LABEL terraform="$TF_VERSION"
LABEL user="gdsre"
LABEL repo="aws-terraform"

RUN apt-get update  --yes && \
    apt-get install --yes awscli jq curl dnsutils unzip

WORKDIR /tmp

RUN curl https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip > terraform.zip && \
    echo 'a549486112f5350075fb540cfd873deb970a9baf8a028a86ee7b4472fc91e167  terraform.zip'  > terraform.sha && \
    sha256sum -c terraform.sha && unzip terraform.zip && mv terraform /usr/bin/terraform                    && \
    rm terraform.zip && rm terraform.sha

ENTRYPOINT ["bash"]
