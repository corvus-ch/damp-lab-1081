local k = import 'ksonnet/ksonnet.beta.4/k.libsonnet';
local pvc = k.core.v1.persistentVolumeClaim;
local kIngress = k.extensions.v1beta1.ingress;
local ingressTls = kIngress.mixin.spec.tlsType;
local ingressRule = kIngress.mixin.spec.rulesType;
local httpIngressPath = ingressRule.mixin.http.pathsType;

local baseDomain = '.apps.damp-lab-1081.corvus-ch.xyz';

local ingress(namespace, name, port) =
  local host = name + baseDomain;
  kIngress.new() +
  kIngress.mixin.metadata.withName(name) +
  kIngress.mixin.metadata.withNamespace(namespace) +
  kIngress.mixin.metadata.withAnnotations({
    'cert-manager.io/cluster-issuer': 'cloudflare',
    'ingress.kubernetes.io/ssl-redirect': 'true',
  }) +
  kIngress.mixin.spec.withRules(
    ingressRule.new() +
    ingressRule.withHost(host) +
    ingressRule.mixin.http.withPaths(
      httpIngressPath.new() +
      httpIngressPath.mixin.backend.withServiceName(name) +
      httpIngressPath.mixin.backend.withServicePort(port)
    ),
  ) +
  kIngress.mixin.spec.withTls(
    ingressTls.new() +
    ingressTls.withHosts(host) +
    ingressTls.withSecretName(name + '-ingress-cert')
  );

local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import 'k3s.libsonnet') +

  {
    _config+:: {
      namespace: 'monitoring',
      versions+:: {
        kubeStateMetrics: '1.9.6',
      },
      imageRepos+:: {
        kubeStateMetrics: 'carlosedp/kube-state-metrics',
      },
      alertmanager+:: {
        replicas: 1,
      },
      grafana+:: {
        config+: {
          sections+: {
            server+: {
              root_url: 'https://grafana' + baseDomain,
            },
          },
        },
      },
      prometheus+:: {
        replicas: 1,
      },
    },
    alertmanager+:: {
      alertmanager+: {
        spec+: {
          externalUrl: 'https://alertmanager-main' + baseDomain,
        },
      },
    },
    prometheus+:: {
      prometheus+: {
        spec+: {
          externalUrl: 'https://prometheus-k8s' + baseDomain,
          storage: {
            volumeClaimTemplate:
              pvc.new() +
              pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
              pvc.mixin.spec.resources.withRequests({ storage: '10Gi' }) +
              pvc.mixin.spec.withStorageClassName('longhorn'),
          },
        },
      },
    },
    ingress+:: {
      alertmanager: ingress($._config.namespace, 'alertmanager-main', 'web'),
      grafana: ingress($._config.namespace, 'grafana', 'http'),
      prometheus: ingress($._config.namespace, 'prometheus-k8s', 'web'),
    },
  };

{ ['setup/0namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor is separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ [name + '-ingress']: kp.ingress[name] for name in std.objectFields(kp.ingress) }
