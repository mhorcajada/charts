name: 🐛 Bug Report
description: Report a reproducible problem in the chart.
labels: [bug]
body:
  - type: markdown
    attributes:
      value: |
        Please ensure your issue hasn't been reported already and that it follows the contributing guidelines.

  - type: textarea
    id: description
    attributes:
      label: Describe the bug
      description: A clear and concise description of what the bug is.
    validations:
      required: true

  - type: input
    id: chart_version
    attributes:
      label: Chart version
      placeholder: ex. 0.2.3
    validations:
      required: true

  - type: input
    id: helm_version
    attributes:
      label: Helm version
      placeholder: ex. v3.13.0
    validations:
      required: false

  - type: textarea
    id: values_used
    attributes:
      label: `values.yaml` or overrides used
      description: Paste any custom values applied during installation
    validations:
      required: false

  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      description: Please provide steps to reproduce the behavior.
      placeholder: |
        1. helm install ...
        2. Observe logs...
        3. ...
    validations:
      required: true

  - type: textarea
    id: logs
    attributes:
      label: Relevant logs or output
      description: If applicable, paste logs or output from `helm` or Kubernetes
    validations:
      required: false
