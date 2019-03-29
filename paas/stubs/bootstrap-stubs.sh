#!/usr/bin/env bash
set -eu

echo "Bootstrapping environment: ${ENVIRONMENT?Must have set ENVIRONMENT environment variable}"
echo "Only allowing access to test-rp web service from: ${TEST_RP_IP_SAFELIST?Must have set TEST_RP_IP_SAFELIST}"
echo "Only allowing access to test-rp private endpoints from: ${TEST_RP_PRIVATE_IP_SAFELIST?Must have set TEST_RP_PRIVATE_IP_SAFELIST}"
echo "Only allowing access to test-rp-msa from: ${TEST_RP_MSA_IP_SAFELIST?Must have set TEST_RP_MSA_IP_SAFELIST}"
echo "Creating 'dummy' apps"
rm -rf /tmp/paas
mkdir -p /tmp/paas
cd /tmp/paas
echo "Placeholder text" > index.html
cat << MANIFEST > manifest.yml
applications:
  - name: $ENVIRONMENT-test-rp
    routes:
      - route: $ENVIRONMENT-test-rp.apps.internal
      - route: $ENVIRONMENT-test-rp.cloudapps.digital
      - route: $ENVIRONMENT-test-rp.cloudapps.digital/private

  - name: $ENVIRONMENT-test-rp-msa
    routes:
      - route: $ENVIRONMENT-test-rp-msa.apps.internal
      - route: $ENVIRONMENT-test-rp-msa.cloudapps.digital

  - name: $ENVIRONMENT-stub-idp
    routes:
      - route: $ENVIRONMENT-stub-idp.cloudapps.digital

MANIFEST
cf v3-create-app "$ENVIRONMENT-test-rp"
cf v3-create-app "$ENVIRONMENT-test-rp-msa"
#cf v3-create-app "$ENVIRONMENT-stub-idp"

# Allow test-rp to access MSA metadata
cf add-network-policy "$ENVIRONMENT-test-rp" --destination-app "$ENVIRONMENT-test-rp-msa" --protocol tcp --port 8080
# Allow MSA to access local matching service in test-rp
cf add-network-policy "$ENVIRONMENT-test-rp-msa" --destination-app "$ENVIRONMENT-test-rp" --protocol tcp --port 8080

git clone git@github.com:alphagov/re-paas-ip-safelist-service.git
cd re-paas-ip-safelist-service
# The templating in re-paas-ip-safelist-service doesn't really work for us so let's override it
cat << MANIFEST > manifest.yml
applications:
  - name: ((app))-ip-safelist-service
    routes:
      - route: ((app))-ip-safelist-service.cloudapps.digital
    buildpacks:
      - staticfile_buildpack
    instances: 1
    memory: 256M
    env:
      ALLOWED_IPS: ((allowed_ips))
MANIFEST

# Set up route service for test-rp web access
SERVICE_NAME="$ENV-test-rp-ip-safelist-service"
cf push --var app=$ENV-test-rp --var allowed_ips=$TEST_RP_IP_SAFELIST
cf create-user-provided-service $SERVICE_NAME -r "https://$SERVICE_NAME.cloudapps.digital"
cf bind-route-service cloudapps.digital --hostname $ENV-test-rp $SERVICE_NAME

# Set up route service for test-rp private access
SERVICE_NAME="$ENV-test-rp-private-ip-safelist-service"
cf push --var app=$ENV-test-rp-private --var allowed_ips=$TEST_RP_PRIVATE_IP_SAFELIST
cf create-user-provided-service $SERVICE_NAME -r "https://$SERVICE_NAME.cloudapps.digital"
cf bind-route-service cloudapps.digital --hostname $ENV-test-rp --path private $SERVICE_NAME

# Set up route service for test-rp MSA access
SERVICE_NAME="$ENV-test-rp-msa-ip-safelist-service"
cf push --var app=$ENV-test-rp-msa --var allowed_ips=$TEST_RP_MSA_IP_SAFELIST
cf create-user-provided-service $SERVICE_NAME -r "https://$SERVICE_NAME.cloudapps.digital"
cf bind-route-service cloudapps.digital --hostname $ENV-test-rp-msa $SERVICE_NAME
