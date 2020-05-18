#!/bin/bash


export BOOKINFO_NS=bookinfo
export SM_CP_NS=bookretail-istio-system
export SUBDOMAIN_BASE=cluster-3df0.3df0.example.opentlc.com

BookInfo_Deployments="
            details-v1 \
            productpage-v1 \
            ratings-v1 \
            reviews-v1 \
            reviews-v2 \
            reviews-v3"

BookInfo_Services="
            details \
            productpage \
            ratings \
            reviews"


# Responsible for creating the ServiceMeshMemberRoll for the project bookinfo

function createServiceMeshMemberRoll() {

  echo -en "\n\nCreating ServiceMeshMemberRoll for project: $BOOKINFO_NS\n"

  echo "apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
spec:
  members:
    - $BOOKINFO_NS" \
  | oc apply -n $SM_CP_NS -f -

}

# Responsible for injecting the istio annotation in a deployment for auto injection of the envoy sidecar
function injectAndResume() {

  echo -en "\n\nInjecting istio sidecar annotation into Deployment: $DEP_NAME\n"

  oc patch deployment $DEP_NAME -n $BOOKINFO_NS -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"'true'"}}}}}'

  # 2)  Loop until envoy enabled pod starts up
  replicas=1
  readyReplicas=0 
  counter=1
  while (( $replicas != $readyReplicas && $counter != 20 ))
  do
    sleep 1 
    oc get deployments $DEP_NAME -o json -n $BOOKINFO_NS > /tmp/$DEP_NAME.json
    replicas=$(cat /tmp/$DEP_NAME.json | jq .status.replicas)
    readyReplicas=$(cat /tmp/$DEP_NAME.json | jq .status.readyReplicas)
    echo -en "\n$counter    $DEP_NAME    $replicas   $readyReplicas\n"
    let counter=counter+1
  done
} 


# Responsible for configuring liveness & readiness probes
# Only ratings pod has curl installed, so for the other pods it doesn't configure the probes

function configureProbes(){

  echo -en "\n\nConfiguring liveness & readiness probes....\n"

  # oc patch deployment details-v1 --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/details/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/details/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $BOOKINFO_NS

  # oc patch deployment productpage-v1 --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/productpage?u=normal"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/productpage?u=normal"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $BOOKINFO_NS

  oc patch deployment ratings-v1 --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/ratings/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/ratings/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $BOOKINFO_NS

  # oc patch deployment reviews-v1 --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/reviews/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/reviews/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $BOOKINFO_NS

  # oc patch deployment reviews-v2 --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/reviews/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/reviews/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $BOOKINFO_NS

  # oc patch deployment reviews-v3 --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/reviews/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:9080/reviews/0"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $BOOKINFO_NS

}

# Responsible for creating the cert 

function createCertificateSecret(){

  echo -en "\n\nCreating certificate....\n"

cat <<EOF | tee ./cert.cfg
[ req ]
req_extensions     = req_ext
distinguished_name = req_distinguished_name
prompt             = no

[req_distinguished_name]
commonName=bookinfo.apps.$SUBDOMAIN_BASE

[req_ext]
subjectAltName   = @alt_names

[alt_names]
DNS.1  = bookinfo.apps.$SUBDOMAIN_BASE
DNS.2  = *.bookinfo.apps.$SUBDOMAIN_BASE
EOF

  openssl req -x509 -config cert.cfg -extensions req_ext -nodes -days 730 -newkey rsa:2048 -sha256 -keyout tls.key -out tls.crt 

  oc create secret tls istio-ingressgateway-certs --cert tls.crt --key tls.key -n $SM_CP_NS

  oc patch deployment istio-ingressgateway -p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'`date +%Y-%m-%dT%H:%M:%S%z`'"}}}}}' -n $SM_CP_NS
}


# Responsible for creating the Wildcard Gateway
function createWildcardGateway(){

  echo -en "\n\nCreating wildcard gateway....\n"

  echo "---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-wildcard-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      privateKey: /etc/istio/ingressgateway-certs/tls.key
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
    hosts:
    - \"*.bookinfo.apps.$SUBDOMAIN_BASE\"
" > wildcard-gateway.yml

  oc create -f wildcard-gateway.yml -n $SM_CP_NS
}


# Responsible for creating mTLS policies
function createMTLSPolicy(){
  echo -en "\n\nCreating mTLS policy into Service: $SVC_NAME\n"

  echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: $SVC_NAME-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: $SVC_NAME
" > $SVC_NAME-policy.yml

  oc create -f $SVC_NAME-policy.yml -n $BOOKINFO_NS
}

# Responsible for creating Destination Rules
function createDestinationRule(){
  echo -en "\n\nCreating Destination Rule for Service: $SVC_NAME\n"

  echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: $SVC_NAME-client-mtls
spec:
  host: $SVC_NAME.$BOOKINFO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > $SVC_NAME-mtls-destinationrule.yml

  oc create -f $SVC_NAME-mtls-destinationrule.yml -n $BOOKINFO_NS
}

# Responsible for creating Virtual Services
function createVirtualService(){
  echo -en "\n\nCreating Virtual Service for Service: $SVC_NAME\n"

  
  echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: $SVC_NAME-virtualservice
spec:
  hosts:
  - \"$SVC_NAME-service.$BOOKINFO_NS.apps.$SUBDOMAIN_BASE\"
  gateways:
  - bookinfo-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 9080
        host: $SVC_NAME.$BOOKINFO_NS.svc.cluster.local
" > $SVC_NAME-virtualservice.yml
 
  oc create -f $SVC_NAME-virtualservice.yml -n $BOOKINFO_NS
}


# Responsible for creating Route for Productpage service
function createProductpageGateway(){
  echo -en "\n\nCreating Route for Service: Productpage \n"

  echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: 'true'
  labels:
    app: productpage
  name: productpage-service-gateway
spec:
  host: "productpage-service.$BOOKINFO_NS.apps.$SUBDOMAIN_BASE"
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > productpage-service-gateway.yml

  oc create -f productpage-service-gateway.yml -n $SM_CP_NS

  oc delete route productpage -n $BOOKINFO_NS
}

# Create ServiceMeshMemberRoll for the project bookinfo
createServiceMeshMemberRoll

# Enable bookinfo DeploymentConfigs for Envoy auto-injection
for DEP_NAME in $BookInfo_Deployments;
do
  injectAndResume
done

# Configure Liveness & Readiness Probes
# Bookinfo pods don't have curl installed, except for the ratings pod.
configureProbes

# Create certificate and configure secret
createCertificateSecret

# Create wildcard Gateway
createWildcardGateway

# Create mTLS Policies
for SVC_NAME in $BookInfo_Services;
do
  createMTLSPolicy
done

# Create mTLS Policies
for SVC_NAME in $BookInfo_Services;
do
  createDestinationRule
done


# Create Virtual Services
for SVC_NAME in $BookInfo_Services;
do
  createVirtualService
done

# Create Route for Productpage service
createProductpageGateway

