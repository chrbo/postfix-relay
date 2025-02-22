# Postfix relay for Docker and Kubernetes
This project integrates parts of the code of
[eldada/postfix-relay-kubernetes](https://github.com/eldada/postfix-relay-kubernetes) and
[instrumentisto/opendkim-docker-image](https://github.com/instrumentisto/opendkim-docker-image). Many thanks
for their great work! It implements a postfix based mail relay, that can be run on Docker or Kubernetes with
different common configurations.

The configuration can be done via environment variables or a .env file for Docker or Kubernetes and by an
additional helm chart for Kubernetes.

Check the sections [Build Docker images](#build-docker-images),
[Run locally with Docker](#run-locally-with-docker) and [Deploy to Kubernetes with the Helm Chart](#deploy-to-kubernetes-with-the-helm-chart) to run the
different configuration options locally or deploy them.

Use the test container to check your configuration. Please see the
[Test container](#test-container) section.
## Postfix basic configuration
With these options you can configure the postfix basics:
* Hostname (hostname; default: my.local)
* Networks (string; default 10.0.0.0/8,127.0.0.0/8,172.17.0.0/16,192.0.0.0/8)
* Custom config (string of any valid postfix configuration directive)

Important: the custom config is executed as the last directive, so you are able to overwrite other defaults
by that directive.
### Environment variables:
```shell
POSTFIX_RELAY_HOSTNAME=
POSTFIX_RELAY_NETWORKS=
POSTFIX_RELAY_CUSTOM_CONFIG=
```
### Helm values:
```yaml
postfixRelay:
  hostname: 
  networks: 
  customConfig: 
```
## Configuration options
You can configure the following common configuration options and combine them:
* [Simple mail relay](#simple-mail-relay)
* [Inbound mail transport via TLS](#inbound-mail-transport-via-tls)
* [Outbound mail transport via TLS](#outbound-mail-transport-via-tls)
* [Sender based routing](#sender-based-routing)
* [Define the transport by recipient](#define-the-transport-by-recipient)
* [DKIM](#dkim)

For each scenario a .env and values dist file is provided. The .env dist files are located in the projects root
folder and the values dist files can be found in the helm folder.
### Simple mail relay
This configuration option handles the local mail forwarding for one sender domain to their official
outbound SMTP server. To achieve this you have to configure the following values:
* Default outbound relay host (ip address or hostname)
* Default outbound relay username (string)
* Default outbound relay password (string)
#### Environment variables:
```shell
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST=
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_USERNAME=
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_PASSWORD=
```
#### Helm values:
```yaml
postfixRelay:
  defaultOutboundRelay:
    host:
    username:
    password:
```
To configure this scenario, please use the [.env-01-simple-mailrelay.dist](.env-01-simple-mailrelay.dist) and the
[helm/values-01-simple-mailrelay.yaml](helm/values-01-simple-mailrelay.yaml) dist files.
### Inbound mail transport via TLS
This configuration options handles inbound TLS encrypted mail transport. 
#### Prerequisites
You can create a certificate request  with a new key without a passphrase by the following command:
```shell
openssl req -new -newkey rsa:2048 -nodes -keyout foo-key.pem -out foo-req.pem
```
You can self-sign the certificate by the following command:
```shell
openssl ca -out foo-cert.pem -days 365 -infiles foo-req.pem
```
And get the base64 encoded values of the certificate and the key by these commands:
```shell
cat foo-cert.pem | base64
cat foo-key.pem | base64
```
Please keep in mind, that the certificate has to be trusted!
#### Configuration options
* Inbound TLS (false, may or encrypt)
* Inbound TLS certificate (base64 encoded certificate string; append a trailing newline before encoding)
* Inbound TLS key (base64 encoded key string; append a trailing newline before encoding)
* Inbound TLS settings (string)
#### Environment variables:
```
POSTFIX_RELAY_INBOUND_TLS=
POSTFIX_RELAY_INBOUND_TLS_CERTIFICATE=
POSTFIX_RELAY_INBOUND_TLS_KEY=
POSTFIX_RELAY_INBOUND_TLS_SETTINGS=
```
#### Helm values:
Important: the helm properties for certificate and key accept multiline values without base64 encoding
```yaml
postfixRelay:
  inboundTls:
  inboundTlsCertificate:
  inboundTlsKey:
  inboundTlsSettings:
```
You can find additional information about inbound TLS at the
[postfix TLS readme](https://www.postfix.org/TLS_README.html).

To configure this scenario, please use the [.env-02-simple-mailrelay-inbound-tls.dist](.env-02-simple-mailrelay-inbound-tls.dist) and the
[helm/values-02-simple-mailrelay-inbound-tls.yaml.dist](helm/values-02-simple-mailrelay-inbound-tls.yaml.dist)
dist files.
### Outbound mail transport via TLS
This configuration option handles outbound TLS encrypted mail transport.
* Outbound TLS (false, may or encrypt)
* Outbound TLS settings (string)
#### Environment variables:
```
POSTFIX_RELAY_OUTBOUND_TLS=
POSTFIX_RELAY_OUTBOUND_TLS_SETTINGS=
```
#### Helm values:
```yaml
postfixRelay:
  outboundTls:
  outboundTlsSettings:
```
You can find additional information about outbound TLS at the
[postfix TLS readme](https://www.postfix.org/TLS_README.html).

To configure this scenario, you can use the [.env-03-simple-mailrelay-inbound-outbound-tls.dist](.env-03-simple-mailrelay-inbound-outbound-tls.dist)
and the [helm/values-03-simple-mailrelay-inbound-outbound-tls.yaml.dist](helm/values-03-simple-mailrelay-inbound-outbound-tls.yaml.dist)
dist files.
### Sender based routing
This configuration option handles the local mail forwarding for a default sender domain to their official
outbound SMTP server and multiple additional sender domains. To achieve this you have to configure the
following values:
* Multiple additional outbound senders (email address)
* Multiple additional outbound relay hosts (ip address or hostname)
* Multiple additional outbound relay usernames
* Multiple additional outbound relay passwords
#### Environment variables:
```
POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_0_SENDER=
POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_0_HOST=
POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_0_USERNAME=
POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_0_PASSWORD=
```
#### Helm values:
```yaml
postfixRelay:
  additionalOutBoundRelay:
    - sender:
      host:
      username:
      password:
```
To configure this scenario, you can use the [.env-04-simple-mailrelay-inbound-outbound-tls-sender-based-routing.dist](.env-04-simple-mailrelay-inbound-outbound-tls-sender-based-routing.dist)
and the [helm/values-04-sender-based-routing-inbound-outbound-tls.yaml.dist](helm/values-04-sender-based-routing-inbound-outbound-tls.yaml.dist)
dist files.
### Define the transport by recipient
With this configuration you are able to define the next hop for a mail by the recipient. To
achieve this you have to configure the following values:
* Multiple patterns for the transport configuration
* Multiple targets for the transport configuration
#### Environment variables:
```
POSTFIX_RELAY_TRANSPORT_0_PATTERN=
POSTFIX_RELAY_TRANSPORT_0_TARGET=
```
#### Helm values:
```yaml
postfixRelay:
  transport:
    - pattern:
      target:
```
You can find additional information about transport at the [postfix transport readme](https://www.postfix.org/transport.5.html).

To configure this scenario, you can use the [.env-05-simple-mailrelay-transport.dist](.env-05-simple-mailrelay-transport.dist)
and the [helm/values-05-simple-mailrelay-transport.yaml.dist](helm/values-05-simple-mailrelay-transport.yaml.dist)
dist files.
### DKIM
This configuration option handles the signing of forwarded mails via the
[DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail) pattern.
* Milter host (ip address or hostname; e.g. localhost)
* Trusted hosts (cldr string; e.g. 0.0.0.0/0)
* Default outbound relay dkim domain (string; e.g. test.de)
* Default outbound relay dkim selector (string; e.g. s1)
* Default outbound relay dkim key (base64 encoded key string; append a trailing newline before encoding)
* Default outbound relay dkim filter (string; e.g. *@test.de)
* Multiple additional outbound dkim domains (string; e.g. test.de)
* Multiple additional outbound dkim selectors (string; e.g. s1)
* Multiple additional outbound dkim keys (base64 encoded key string; append a trailing newline before
  encoding)
* Multiple additional outbound dkim filters (string; e.g. *@test.de)
#### Environment variables:
```
POSTFIX_RELAY_DKIM_MILTER_HOST=
POSTFIX_RELAY_DKIM_TRUSTED_HOSTS=
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN=
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR=
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_KEY=
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_FILTER=
POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_0_DKIM_DOMAIN=
POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_0_DKIM_SELECTOR=
POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_0_DKIM_KEY=
POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_0_DKIM_FILTER=
```
#### Helm values:
```yaml
postfixRelay:
  relayDkim:
  relayDkimMilterHost:
  defaultOutboundRelay:
    dkimDomain:
    dkimSelector:
    dkimKey:
    dkimFilter:
  additionalOutBoundRelay:
    - dkimDomain:
      dkimSelector:
      dkimKey:
      dkimFilter:
```
To configure this scenario, you can use the [.env-06-simple-mailrelay-inbound-outbound-tls-sender-based-routing-dkim.dist](.env-06-simple-mailrelay-inbound-outbound-tls-sender-based-routing-dkim.dist)
and the [helm/values-06-sender-based-routing-inbound-outbound-tls-dkim.yaml.dist](helm/values-06-sender-based-routing-inbound-outbound-tls-dkim.yaml.dist)
dist files.
## Build Docker images
You can build the postfix Docker image locally by executing:
```shell
# For local build
cd docker/postfix
docker build .
```
You can build the opendkim Docker image locally by executing:
```shell
# For local build
cd docker/opendkim
docker build .
```
You can build the test Docker image locally by executing:
```shell
# For local build
cd docker/test
docker build .
```
## Run locally with Docker
There are dist env files for common scenarios in the projects root folder. The first block of variables in the dist
files is used to define the test scenario. The other blocks are used to define the configuration of the services.
### 1. Prepare configuration
Copy the .env-*.dist files to .env-* and add your values
### 2. Local DNS resolution
Add postfix-relay to /etc/hosts
### 3.Run the scenario
Run the container with the variables defined in the env file by executing
```shell
docker run --env-file <env-file> -p 1025:25 chrb0/postfix:latest
```
### 4. DKIM
To check out the examples with dkim you have to run the opendkim container additionally
```shell
docker run --env-file <env-file> -p <exposed port>:8891 chrb0/opendkim:latest
```
### 5. Test
To test the configuration you can use the test container with the predefined environment 
variables in the environment file.
#### Build the postfix-relay-test image
```shell
cd docker/test
docker build . -t postfix-relay-test:latest
```
#### Run the test
```shell
docker run --rm -ti --env-file <env-file> postfix-relay-test:latest
```
## Deploy to Kubernetes with the Helm Chart
The Helm Chart in [helm/postfix](helm/postfix-relay) directory can be used to deploy the postfix-relay into your
Kubernetes cluster.
### 1. Prepare configuration
Create a `custom-values.yaml` with the configuration details. There are dist files for common scenarios in the
helm folder. For all supported values see the [values.yaml](helm/postfix-relay/values.yaml) file in the chart
folder.
### 2. Deploy
Deploy the relay to Kubernetes by executing
```shell
helm upgrade --install postfix-relay helm/postfix -f example-values-simple-mailrelay.yaml
```
or
```shell
cd helm
helm template postfix-relay postfix-relay -f custom-values.yaml | kubectl apply -f -
```
### 3. Postfix Metrics exporter
An optional postfix-exporter sidecar can be deployed for exposing postfix metrics. This is using the work
from https://github.com/kumina/postfix_exporter.

To enable the exporter sidecar, update your `custom-values.yaml` file and **add**
```yaml
# Enable the postfix-exporter sidecar
exporter:
  enabled: true

# Enable a ServiceMonitor object for Prometheus scraping
serviceMonitor:
  enabled: true
```
### 3. Test
To test the configuration you can use the test container with the predefined environment
variables in the environment file.
#### Build the postfix-relay-test image
```shell
cd docker/test
docker build . -t postfix-relay-test:latest
```
#### Run the test
```shell
kubectl create secret generic test --from-env-file <env-file> && \
kubectl run test --attach --rm --overrides='{"spec":{"containers":[{"name":"test","image":"postfix-relay-test:latest","args":["bash","-c","sleep 5;test.sh"],"envFrom":[{"secretRef":{"name":"test"}}]}]}}' --image=postfix-relay-test:latest && \
kubectl delete secret test
```
## Test container
The test container brings a test script, that can be configured by environment
variables. All env dist files includes the environment variable for a complete
test in the first block. It connects to a smtp server and sends emails.
* Host (ip address or hostname of the smtp server to connect to; e.g. localhost)
* Port (port of the smtp server to connect to; e.g. 1025)
* Multiple email senders (email address; e.g. sender@test.de)
* Multiple email recipients (email address; e.g. recipient@test.de)
* Config option if the test script should ask for additional senders and recipients (max 3 additional; boolean; e.g. false)
* Config option if the test script should connect plain (unencrypted) to the smtp server (string; e.g. yes or no)
* Config option if the test script should connect encrypted to the smtp server (string; e.g. yes or no)
### Environment variables:
```
POSTFIX_RELAY_TEST_POSTFIX_HOST=
POSTFIX_RELAY_TEST_POSTFIX_PORT=
POSTFIX_RELAY_TEST_0_SENDER=
POSTFIX_RELAY_TEST_0_RECIPIENT=
POSTFIX_RELAY_TEST_1_SENDER=
POSTFIX_RELAY_TEST_1_RECIPIENT=
POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL=
POSTFIX_RELAY_TEST_EXECUTE_PLAIN=
POSTFIX_RELAY_TEST_EXECUTE_TLS=
```
### Build the postfix-relay-test image
```shell
cd docker/test
docker build . -t postfix-relay-test:latest
```
### Run tests
On Docker:
```shell
docker run --rm -ti --env-file <env-file> postfix-relay-test:latest
```
On Kubernetes:
```shell
kubectl create secret generic test --from-env-file <env-file> && \
kubectl run test --attach --rm --overrides='{"spec":{"containers":[{"name":"test","image":"postfix-relay-test:latest","args":["bash","-c","sleep 5;test.sh"],"envFrom":[{"secretRef":{"name":"test"}}]}]}}' --image=postfix-relay-test:latest && \
kubectl delete secret test
```
## Thanks
The work in this repository is based on
- https://github.com/eldada/postfix-relay-kubernetes
- https://github.com/instrumentisto/opendkim-docker-image
- https://github.com/applariat/kubernetes-postfix-relay-host
- https://github.com/kumina/postfix_exporter
- My pains
