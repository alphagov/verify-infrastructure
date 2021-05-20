ARG base_image=ruby:2.6.6
FROM ${base_image}

LABEL ruby="2.6.6"
LABEL aws="3.0.1"
LABEL user="gdsre"
LABEL repo="aws-ruby"

RUN gem install aws-sdk:3.0.1

ENTRYPOINT ["ruby"]
