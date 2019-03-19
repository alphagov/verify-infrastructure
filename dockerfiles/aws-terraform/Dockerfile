FROM ubuntu:18.04

ENV TF_VERSION 0.11.13

LABEL ubuntu="18.04"
LABEL terraform="$TF_VERSION"
LABEL user="gdsre"
LABEL repo="aws-terraform"

RUN apt-get update  --yes && \
    apt-get install --yes awscli jq curl dnsutils unzip

WORKDIR /tmp

RUN curl https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip > terraform.zip && \
    echo '5925cd4d81e7d8f42a0054df2aafd66e2ab7408dbed2bd748f0022cfe592f8d2  terraform.zip'  > terraform.sha && \
    sha256sum -c terraform.sha && unzip terraform.zip && mv terraform /usr/bin/terraform                    && \
    rm terraform.zip && rm terraform.sha

ENTRYPOINT ["bash"]
