#!/usr/bin/env bash
set -eu

echo "Bootstrapping environment: ${ENVIRONMENT?Must have set ENVIRONMENT environment variable}"
echo "Only allowing access to test-rp web service from: ${TEST_RP_IP_SAFELIST?Must have set TEST_RP_IP_SAFELIST}"
echo "Only allowing access to test-rp private endpoints from: ${TEST_RP_PRIVATE_IP_SAFELIST?Must have set TEST_RP_PRIVATE_IP_SAFELIST}"
echo "Only allowing access to test-rp-msa from: ${MSA_IP_SAFELIST?Must have set MSA_IP_SAFELIST}"
echo "Creating 'dummy' apps"
rm -rf /tmp/paas
mkdir -p /tmp/paas
cd /tmp/paas
echo "Placeholder text" > index.html
cat <<MANIFEST > manifest.yml
applications:
  - name: test-rp-$ENVIRONMENT
    routes:
      - route: test-rp-$ENVIRONMENT.apps.internal
      - route: test-rp-$ENVIRONMENT.cloudapps.digital
      - route: test-rp-$ENVIRONMENT.cloudapps.digital/private
    buildpacks:
      - staticfile_buildpack

  - name: test-rp-msa-$ENVIRONMENT
    routes:
      - route: test-rp-msa-$ENVIRONMENT.apps.internal
      - route: test-rp-msa-$ENVIRONMENT.cloudapps.digital
    buildpacks:
      - staticfile_buildpack

  - name: stub-idp-$ENVIRONMENT
    routes:
      - route: stub-idp-$ENVIRONMENT.cloudapps.digital
    buildpacks:
      - staticfile_buildpack
MANIFEST
cf push "test-rp-$ENVIRONMENT"
cf push "test-rp-msa-$ENVIRONMENT"
cf push "stub-idp-$ENVIRONMENT"

# Allow test-rp to access MSA metadata
cf add-network-policy "test-rp-$ENVIRONMENT" --destination-app "test-rp-msa-$ENVIRONMENT" --protocol tcp --port 8080
# Allow MSA to access local matching service in test-rp
cf add-network-policy "test-rp-msa-$ENVIRONMENT" --destination-app "test-rp-$ENVIRONMENT" --protocol tcp --port 8080

git clone https://github.com/alphagov/paas-ip-authentication-route-service
cd paas-ip-authentication-route-service
# The templating in re-paas-ip-safelist-service doesn't really work for us so let's override it
cat << MANIFEST > manifest.yml
applications:
  - name: ((app))-ip-safelist-service
    instances: 2
    memory: 256M
    routes:
      - route: ((app))-ip-safelist-service.cloudapps.digital
    buildpacks:
      - nginx_buildpack
    health-check-type: http
    health-check-http-endpoint: /_route-service-health
    env:
      APP_NAME: ((app))-ip-safelist-service
      ALLOWED_IPS: ((allowed_ips))
MANIFEST

# Set up route service for test-rp web access
SERVICE_NAME="test-rp-$ENVIRONMENT-ip-safelist-service"
cf push --var app=test-rp-$ENVIRONMENT --var allowed_ips=$TEST_RP_IP_SAFELIST
cf create-user-provided-service $SERVICE_NAME -r "https://$SERVICE_NAME.cloudapps.digital"
cf bind-route-service cloudapps.digital --hostname test-rp-$ENVIRONMENT $SERVICE_NAME

# Set up route service for test-rp private access
SERVICE_NAME="test-rp-$ENVIRONMENT-private-ip-safelist-service"
cf push --var app=test-rp-$ENVIRONMENT-private --var allowed_ips=$TEST_RP_PRIVATE_IP_SAFELIST
cf create-user-provided-service $SERVICE_NAME -r "https://$SERVICE_NAME.cloudapps.digital"
cf bind-route-service cloudapps.digital --hostname test-rp-$ENVIRONMENT --path private $SERVICE_NAME

# Set up route service for MSA access
SERVICE_NAME="test-rp-msa-$ENVIRONMENT-ip-safelist-service"
cf push --var app=test-rp-msa-$ENVIRONMENT --var allowed_ips=$MSA_IP_SAFELIST
cf create-user-provided-service $SERVICE_NAME -r "https://$SERVICE_NAME.cloudapps.digital"
cf bind-route-service cloudapps.digital --hostname test-rp-msa-$ENVIRONMENT $SERVICE_NAME
