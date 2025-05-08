# 🤝 Contributing to the `charts` repository

Thank you for considering contributing to the `mhorcajada/charts` repository. This project provides a Helm chart for deploying the official Storj Gateway and related services.

We welcome contributions in the form of code, documentation, or issues. Please follow the guidelines below to help maintain consistency and quality across contributions.

---

## 📦 Repository structure

- `storj-gateway/`: The main Helm chart directory.
- `gh-pages`: GitHub Pages branch for serving packaged charts and index.
- `Makefile`: Automates release and packaging processes.

---

## 🧪 Local testing before PR

Please validate your changes locally:

```bash
make lint             # Validate chart syntax
make template         # Generate Kubernetes manifests
make install          # Dry-run install with Helm
```

---

## ✅ Pull Request process

1. Fork this repository or create a branch from `main`.
2. Branch naming: `fix/<name>`, `feat/<feature>`, or `docs/<topic>`.
3. Use clear and conventional commit messages (`fix`, `feat`, `chore`, etc).
4. Push your changes and create a pull request (PR) into `main`.
5. PRs should reference issues where applicable.

Example:

```bash
git checkout -b fix/chart-validation
# apply your changes
git commit -m "fix(chart): validate configMap handling"
git push origin fix/chart-validation
gh pr create --base main --head fix/chart-validation
```

---

## 🧾 Commit message format

Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format:

- `fix(chart): corrected envFrom template`
- `feat(values): add support for vault integration`
- `docs(readme): update chart usage instructions`

---

## 🚀 Releasing a new chart version

All releases are automated with `make release`:

```bash
make release CHART_VERSION=0.2.3
```

This will:
- Lint and test the chart
- Package it
- Update `index.yaml`
- Publish to `gh-pages`
- Tag the release

Ensure your `Chart.yaml` has the correct version.

---

## 🛠️ Issues and feature requests

Please open issues in GitHub for:
- Reporting bugs
- Requesting features
- Discussing enhancements

Use proper templates and provide as much detail as possible.

---

## 📫 Contact

If you need help, open an [issue](https://github.com/mhorcajada/charts/issues) or reach out via GitHub.

Thanks again for contributing!

