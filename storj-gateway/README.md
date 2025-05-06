# Storj Gateway Helm Chart con WebUI

[![Helm Chart Version](https://img.shields.io/badge/helm--chart-v0.2.2-blue?logo=helm)](https://github.com/mhorcajada/charts/tree/gh-pages)

Este repositorio contiene un Helm Chart personalizado para desplegar un contenedor **Storj Gateway** configurado dinámicamente mediante varios modos posibles de aprovisionamiento de configuración:

- `Modo 1`: Configuración mediante configMap + initContainer.
- `Modo 2`: Configuración mediante `envFrom` con configMap.
- `Modo 3`: Configuración mediante inyección de secretos desde Hashicorp Vault (Vault Agent Injector).
- `Modo 4`: Configuración mediante `envFrom` con Secret.
- `Modo WebUI`: Configuración `webUi.enabled: true` habilita la interfaz web para gestión de ficheros en Storj.

El diseño de este chart permite seleccionar **exclusivamente** un modo por despliegue, respetando la filosofía _"one responsibility per deployment"_ y asegurando aislamiento de lógica en `values.yaml`.

Cada modo está validado con `helm template` y `helm install --dry-run` para garantizar su correcto renderizado sin errores y cumplimiento del comportamiento esperado.


## 🧩 Modos de configuración disponibles

### 🔹 Modo 1: `initContainer` + `configMap`

**Descripción**:
- Se monta un `configMap` de solo lectura que contiene el `config.yaml` de configuración de Storj.
- Un `initContainer` copia este fichero al volumen persistente (PVC) donde la aplicación lo espera.
- Storj carga automáticamente `config.yaml` sin parámetros adicionales.

**Estructura esperada en `values.yaml`**:
```yaml
configMap:
  enabled: true
  name: storj-gateway-config
  mountPath: /etc/storj-config
  data:
    config.yaml: |
      access: ACCESS_VALUE
      minio.access-key: ACCESS_KEY
      minio.secret-key: SECRET_KEY

initContainer:
  enabled: true
  image: busybox
  args:
    - |
      cp -f /etc/storj-config/config.yaml /root/.local/share/storj/gateway/config.yaml
```

**Args del contenedor principal**:
```yaml
args:
  - exec /entrypoint run
```

---

### 🔹 Modo 2: `envFrom` + `configMap`

**Descripción**:
- Las variables sensibles (`STORJ_ACCESS`, `STORJ_MINIO_ACCESS_KEY`, `STORJ_MINIO_SECRET_KEY`) se definen como claves de un `configMap`.
- Se usan con `envFrom` para inyectarlas en el contenedor.
- El binario de `storj` $\color{Green}{\textbf{gateway}}$ recibe explícitamente los parámetros como argumentos CLI.

**Estructura esperada en `values.yaml`**:
```yaml
envconfigMap:
  enabled: true
  name: storj-env-config
  data:
    STORJ_ACCESS: ACCESS_VALUE
    STORJ_MINIO_ACCESS_KEY: ACCESS_KEY
    STORJ_MINIO_SECRET_KEY: SECRET_KEY

args:
  - exec /entrypoint run --access "$STORJ_ACCESS" --minio.access-key "$STORJ_MINIO_ACCESS_KEY" --minio.secret-key "$STORJ_MINIO_SECRET_KEY"
```

---

### 🔹 Modo 3: Vault Agent Injector

**Descripción**:
- Se usa `Hashicorp Vault` como backend de secretos. El `Vault Agent Injector` inyecta dinámicamente un secreto como fichero plano.
- Se utiliza `source` para cargar las variables antes de ejecutar `storj` <span style="color:green">gateway</span>.
- Evita usar `envFrom`, montar secretos estáticos y no expone credenciales.

**Estructura esperada en `values.yaml`**:
```yaml
vault:
  enabled: true
  agentImage: hashicorp/vault:1.19.3
  caCertPath: /run/secrets/kubernetes.io/serviceaccount/ca.crt
  role: storj-gateway
  secretPath: internal/data/storj-gateway/config
  template: |
    {{ with secret "internal/data/storj-gateway/config" }}
    export STORJ_ACCESS={{ .Data.data.access }}
    export STORJ_MINIO_ACCESS_KEY={{ index .Data.data "access-key" }}
    export STORJ_MINIO_SECRET_KEY={{ index .Data.data "secret-key" }}
    {{ end }}

args:
  - >
    source /vault/secrets/storj-config.txt && exec /entrypoint run --access "$STORJ_ACCESS" --minio.access-key "$STORJ_MINIO_ACCESS_KEY" --minio.secret-key "$STORJ_MINIO_SECRET_KEY"
```

**Anotaciones en `podAnnotations` generadas automáticamente**:
- `vault.hashicorp.com/agent-inject`
- `vault.hashicorp.com/agent-inject-template-*`
- `vault.hashicorp.com/agent-image`
- `vault.hashicorp.com/ca-cert`
- `vault.hashicorp.com/role`

---

## 🔹 Modo 4: `envFrom` + `Secret`

**Descripción**:
- Las variables sensibles (`STORJ_ACCESS`, `STORJ_MINIO_ACCESS_KEY`, `STORJ_MINIO_SECRET_KEY`) se definen como claves de un `Secret` tipo `Opaque`.
- Se inyectan automáticamente al contenedor usando `envFrom.secretRef`.
- Este modo es ideal cuando los secretos son gestionados por GitOps, SealedSecrets, o herramientas externas.

**Estructura esperada en `values.yaml`**:
```yaml
envSecret:
  enabled: true
  name: storj-env-secret
  data:
    STORJ_ACCESS: ACCESS_VALUE
    STORJ_MINIO_ACCESS_KEY: ACCESS_KEY
    STORJ_MINIO_SECRET_KEY: SECRET_KEY

args:
  - exec /entrypoint run --access "$STORJ_ACCESS" --minio.access-key "$STORJ_MINIO_ACCESS_KEY" --minio.secret-key "$STORJ_MINIO_SECRET_KEY"
```

**Ventajas**:
- Mayor seguridad frente a configMap.
- Compatible con Vault Agent si prepopula el `Secret` vía controller externo.
- Declarativo y compatible con Argo CD.

---

### 🔹 Modo Web UI: Filestash (`webUi.enabled: true`)

Este modo opcional permite desplegar el frontend **Filestash** como panel web para interactuar con el gateway Storj.
Ideal para usuarios que requieren una interfaz gráfica de administración de ficheros.

#### 📁 Secret necesario
**Filestash** gestiona sus credenciales internamente, por lo que **no requiere un Secret adicional** para autenticación básica.

La autenticación de acceso y administración se gestiona en el propio panel web de Filestash (login + zona de admin).
No es necesario usar anotaciones `nginx.ingress.kubernetes.io/auth-type: basic`.

#### 🧾 Configuración en `values.yaml`

```yaml
webUi:
  enabled: true
  replicaCount: 1

  image:
    repository: machines/filestash
    tag: "latest@sha256:8e39ba84953b547aed4a35ff65f0ab2e1a265c7e4412f7140410976c4ac5bcda"
    digest: "sha256:8e39ba84953b547aed4a35ff65f0ab2e1a265c7e4412f7140410976c4ac5bcda"
    # tag: "latest"   # Recomendado fijar un digest o versión estable

  ingress:
    enabled: true
    className: nginx
    host: filestash.cluster.local

    tls:
      enabled: true              # true para TLS, false para HTTP plano
      issuer: vault-issuer       # Issuer de cert-manager (e.g. vault-issuer, letsencrypt-prod)
      secretName: filestash-tls  # Nombre del Secret TLS

  persistence:
    enabled: true
    create: true
    existingClaim: filestash-config-pvc  # Si 'create' es false, debe existir este PVC
    storageClassName: longhorn
    size: 50Mi
```

#### 🔐 Seguridad
- Acceso web protegido mediante **login nativo** de **Filestash**.
- Zona de administración habilitada desde el propio UI (`/admin`), requiere usuario registrado con permisos.

#### 📸 Capturas de pantalla (miniaturas)
Interfaz principal de **Filestash** y panel de administración:

| UI Principal | Panel Admin |
|--------------|-------------|
| ![UI](https://www.filestash.app/img/screenshots/feature1.png) | ![Admin](https://www.filestash.app/img/screenshots/feature_sso.png) |

#### ✅ Resultado
Una vez desplegado, el panel será accesible en:

- `http://filestash.cluster.local` (si `tls.enabled: false`)
- `https://filestash.cluster.local` (si `tls.enabled: true` y certificado emitido por `vault-issuer`)

---
## 🧪 Validaciones y pruebas

Para cada modo, se ha validado:

- Correcta interpolación de `args`
- Generación esperada de `configMap` o anotaciones
- Inyección de secretos (modo Vault) conforme a la especificación de HashiCorp Vault Agent
- Separación estricta de lógica en `values.yaml`, sin mezclas

Comando de validación por modo:

```bash
helm template mhorcajada/storj-gateway --version 0.2.3 -f values-vault.yaml
helm template mhorcajada/storj-gateway --version 0.2.3 -f values-envFrom-Secret.yaml
helm template mhorcajada/storj-gateway --version 0.2.3 -f values-envFrom-configMap.yaml
helm template mhorcajada/storj-gateway --version 0.2.3 -f values-initContainer-configMap.yaml
```

Para comprobar sintaxis e inyección de variables:

```bash
helm install storj-release mhorcajada/storj-gateway --version 0.2.3 -f values-<modo>.yaml --dry-run --debug
```

---

## 🛠️ Requisitos

- Kubernetes >= 1.22
- Helm >= 3.10
- Vault Agent Injector habilitado en el clúster (solo en modo 3)
- Volumen persistente (`ReadWriteOnce`) en la ruta `/root/.local/share/storj/gateway`, con opción de usar un PVC preexistente (`create: false`) o permitir su creación automática (`create: true`).

---

### 📦 Volumen persistente (PVC)

El `gateway` de Storj usa un volumen persistente en la ruta exacta `/root/.local/share/storj/gateway` para configuración y certificados CA.

El comportamiento del PVC depende de los valores siguientes en `values.yaml`:

```yaml
persistence:
  enabled: true          # Requiere el montaje del volumen
  existingClaim: ...     # Si se indica, Helm montará este PVC preexistente
  create: true|false     # true: el PVC será creado por Helm. false: debe existir previamente.
```

- Para el modos `initContainer`, es obligatorio que el volumen exista y sea **escribible**.
- Para el modo `envFrom`, se requiere principalmente el volumen para los archivos temporales que pueda generar `storj`, aunque no necesariamente necesita `config.yaml`.
- En todos los casos, el `mountPath` debe ser `/root/.local/share/storj/gateway` por defecto o puede cambiarse con `--config-dir string`.
- Se ha probado la combinación de `enabled: true` con `create: false` (PVC preexistente) y `create: true` (PVC gestionado por el chart).

Ejemplo para PVC gestionado por Helm:

```yaml
persistence:
  enabled: true
  create: true
  accessMode: ReadWriteOnce
  size: 10Mi
  storageClassName: "longhorn"
  mountPath: /root/.local/share/storj/gateway
```

---

## 📁 Estructura del volumen

Storj genera los siguientes ficheros:

```bash
/root/.local/share/storj/gateway/
├── config.yaml
└── minio/
```

Uso confirmado: 5.4 MiB aprox (`df -h`), por tanto el tamaño mínimo del PVC es:

```yaml
persistence:
  size: 10Mi
```

---

## ✍️ Observaciones finales

- El chart ha sido validado por fases, un modo por despliegue.
- Los `args:` se adaptan dinámicamente al tipo de configuración seleccionada.
- El diseño evita renderizados inválidos (e.g. conflicto entre Vault y `envFrom`).
