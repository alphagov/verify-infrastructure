FROM ubuntu:18.04

ENV TF_VERSION 0.11.11

LABEL ubuntu="18.04"
LABEL terraform="$TF_VERSION"
LABEL user="gdsre"
LABEL repo="aws-terraform"

RUN apt-get update  --yes && \
    apt-get install --yes awscli jq curl dnsutils unzip

WORKDIR /tmp

RUN curl https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip > terraform.zip && \
    echo '94504f4a67bad612b5c8e3a4b7ce6ca2772b3c1559630dfd71e9c519e3d6149c  terraform.zip'  > terraform.sha && \
    sha256sum -c terraform.sha && unzip terraform.zip && mv terraform /usr/bin/terraform                    && \
    rm terraform.zip && rm terraform.sha

ENTRYPOINT ["bash"]
