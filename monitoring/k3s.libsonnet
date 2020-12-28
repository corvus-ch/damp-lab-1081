{
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
