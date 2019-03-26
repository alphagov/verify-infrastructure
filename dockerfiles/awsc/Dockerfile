FROM golang:1.12

ENV AWSC_VERSION b49b1b43a091d1f722ad25da3841e720eae4fb5e
ENV GO111MODULE  on

RUN go get github.com/alphagov/awsc@$AWSC_VERSION

ENTRYPOINT ["bash"]
