# 📦 Helm Charts Repository - mhorcajada

Este repositorio alberga charts de Helm listos para su despliegue en Kubernetes. El primer chart publicado es [`storj-gateway`](./storj-gateway), diseñado para desplegar el Gateway oficial de Storj compatible S3, con soporte flexible para configuración vía `env`, `configMap`, `Secret`, `initContainers` y HashiCorp Vault con WebUI para la gestión de ficheros en los Buckets.

---

## 📚 Índice

- [Repositorio Helm](#📁-repositorio-helm)
- [Chart disponible](#🚀-chart-disponible)
- [Comandos Helm](#🔧-comandos-helm)
- [Ejemplos de instalación](#🧪-ejemplos-de-instalación)
- [Desinstalación](#🧹-desinstalación)
- [Contribuir](#🤝-contribuir)

---

## 📁 Repositorio Helm

URL del repositorio:

```
https://mhorcajada.github.io/charts
```

---

## 🚀 Chart disponible

| Chart           | Versión | App Version | Descripción                               |
|----------------|---------|-------------|-------------------------------------------|
| storj-gateway  | [![Chart Version](https://img.shields.io/badge/dynamic/regex.svg?label=helm--chart&color=blue&logo=helm&url=https%3A%2F%2Fraw.githubusercontent.com%2Fmhorcajada%2Fcharts%2Fmain%2Fstorj-gateway%2FChart.yaml&regex=version%3A%5Cs*(%3F<version>%5B%5E%5Cn%5D%2B)&replace=%24version)](https://github.com/mhorcajada/charts)  | 1.10.0      | Despliegue flexible del Gateway oficial de Storj con webUI |

---

## 🔧 Comandos Helm

### 1️⃣ Añadir el repositorio

```bash
helm repo add mhorcajada https://mhorcajada.github.io/charts
```

### 2️⃣ Actualizar el repositorio local

```bash
helm repo update
```

### 3️⃣ Buscar charts disponibles y ver versiones de un Chart

```bash
helm search repo mhorcajada
```
```bash
helm search repo mhorcajada/storj-gateway --versions
```

---

## 🧪 Ejemplos de instalación

### Instalación con configuración por defecto:

```bash
helm install mi-release mhorcajada/storj-gateway
```

### Instalación con valores personalizados:

```bash
helm install mi-release mhorcajada/storj-gateway -f values.yaml
```

> Se incluyen varios archivos `values-*.yaml` en el directorio `storj-gateway/` para distintos escenarios:  
> - `values-envFrom-Secret.yaml`  
> - `values-envFrom-configMap.yaml`  
> - `values-initContainer-configMap.yaml`  
> - `values-vault.yaml`

---

## 🧹 Desinstalación

```bash
helm uninstall mi-release
```

---

## 🤝 Contribuir

Si deseas contribuir con nuevos charts o mejoras:

1. Haz un fork del repositorio.
2. Añade tu nuevo chart en un subdirectorio.
3. Abre un Pull Request a `main`.

---

## 🔐 Seguridad

Este repositorio utiliza GitHub Pages como backend para servir `index.yaml` y los `.tgz` de charts empaquetados. No se almacena información sensible.

---

## 📬 Contacto

Miguel Horcajada  
[mhorcajada.github.io](https://mhorcajada.github.io/charts)
