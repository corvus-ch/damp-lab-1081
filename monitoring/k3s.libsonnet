{
  _config+:: {
    versions+:: {
      kubeStateMetrics: '1.9.6',
    },
    imageRepos+:: {
      kubeStateMetrics: 'carlosedp/kube-state-metrics',
    },
  },
  prometheus+:: {
    serviceMonitorKubelet+: {
      spec+: {
        selector: {
          matchLabels: {
            'k8s-app': 'kubelet',
          },
        },
      },
    },
  },
}
