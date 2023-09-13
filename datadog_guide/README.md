# Datadog Integration Guide

Install Datadog Agent Helm Chart [values-datadog.yaml](./values-datadog.yaml). Modify the [values-datadog.yaml](./values-datadog.yaml) file, adjusting to your environment

```bash
helm upgrade --install -f values-datadog.yaml datadog datadog/datadog
```

Use deck to configure Kong Gateway. In [kong.yaml](./kong.yaml), change `plugins[0].config.host` to the Datadog agent service FQDN. For example, if Datadog agent is deployed in `datadog` namespace, the FQDN is `datadog.datadog.svc.cluster.local`

```bash
deck sync --tls-skip-verify --headers "Kong-Admin-Token:<INSERT KONG MANAGER TOKEN>" -w test --kong-addr https://<KONG-MANAGER-URL> -s kong.yaml
```

Issue a request against the Kong proxy endpoint and observe the logs and metrics shown in Datadog

```bash
http http:/<KONG-PROXY-ADDRESS>/echo/anything "apikey: consumer1key"
```