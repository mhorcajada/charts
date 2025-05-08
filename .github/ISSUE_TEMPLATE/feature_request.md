name: ✨ Feature Request
description: Propose an enhancement or new feature for this Helm chart.
labels: [enhancement]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for suggesting an idea to improve this chart!

  - type: textarea
    id: problem
    attributes:
      label: Is your feature request related to a problem?
      description: Please describe the problem you’re trying to solve.
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Describe the solution you'd like
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Describe alternatives you've considered
    validations:
      required: false

  - type: textarea
    id: context
    attributes:
      label: Additional context
      description: Add any other context or screenshots
    validations:
      required: false
