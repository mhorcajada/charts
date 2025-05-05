# Storj Gateway Helm Chart - Documentación técnica (02-05-2025)

Este repositorio contiene un Helm Chart personalizado para desplegar un contenedor **Storj Gateway** configurado dinámicamente mediante tres modos posibles de aprovisionamiento de configuración:

- `Modo 1`: Configuración mediante ConfigMap + initContainer
- `Modo 2`: Configuración mediante `envFrom` con ConfigMap
- `Modo 3`: Configuración mediante inyección automática de secretos desde Vault (Vault Agent Injector)
- `Modo 4`: Configuración mediante `envFrom` con Secret

El diseño de este chart permite seleccionar **exclusivamente** un modo por despliegue, respetando la filosofía _"one responsibility per deployment"_ y asegurando aislamiento de lógica en `values.yaml`.

Cada modo está validado con `helm template` y `helm install --dry-run` para garantizar su correcto renderizado sin errores y cumplimiento del comportamiento esperado.


## 🧩 Modos de configuración disponibles

### 🔹 Modo 1: `initContainer` + `configMap`

**Descripción**:
- Se monta un `ConfigMap` en solo lectura que contiene el `config.yaml` de configuración de Storj.
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

### 🔹 Modo 2: `envFrom` + `ConfigMap`

**Descripción**:
- Las variables sensibles (`STORJ_ACCESS`, `STORJ_KEY`, `STORJ_SECRET`) se definen como claves de un `ConfigMap`.
- Se usan con `envFrom` para inyectarlas en el contenedor.
- El binario `storj` recibe explícitamente los parámetros como argumentos CLI.

**Estructura esperada en `values.yaml`**:
```yaml
envConfigMap:
  enabled: true
  name: storj-env-config
  data:
    STORJ_ACCESS: ACCESS_VALUE
    STORJ_KEY: ACCESS_KEY
    STORJ_SECRET: SECRET_KEY

args:
  - exec /entrypoint run --access "$STORJ_ACCESS" --minio.access-key "$STORJ_KEY" --minio.secret-key "$STORJ_SECRET"
```

---

### 🔹 Modo 3: Vault Agent Injector

**Descripción**:
- Se usa `Vault` como backend secreto. El `Vault Agent Injector` inyecta dinámicamente un secreto como fichero plano.
- Se utiliza `source` para cargar las variables antes de ejecutar `storj`.
- Evita usar `envFrom` o montar secretos estáticos.

**Estructura esperada en `values.yaml`**:
```yaml
vault:
  enabled: true
  agentImage: hashicorp/vault:1.19.3
  role: storj-gateway
  secretPath: internal/data/storj-gateway/config
  template: |
    {{ with secret "internal/data/storj-gateway/config" }}
    export STORJ_ACCESS={{ .Data.data.access }}
    export STORJ_KEY={{ index .Data.data "access-key" }}
    export STORJ_SECRET={{ index .Data.data "secret-key" }}
    {{ end }}

args:
  - >
    source /vault/secrets/storj-config.txt && exec /entrypoint run --access "$STORJ_ACCESS" --minio.access-key "$STORJ_KEY" --minio.secret-key "$STORJ_SECRET"
```

**Anotaciones en `podAnnotations` generadas automáticamente**:
- `vault.hashicorp.com/agent-inject`
- `vault.hashicorp.com/agent-inject-template-*`
- `vault.hashicorp.com/agent-image`
- `vault.hashicorp.com/role`

---

## 🔹 Modo 4: `envFrom` + `Secret`

**Descripción**:
- Las variables sensibles (`STORJ_ACCESS`, `STORJ_KEY`, `STORJ_SECRET`) se definen como claves de un `Secret` tipo `Opaque`.
- Se inyectan automáticamente al contenedor usando `envFrom.secretRef`.
- Este modo es ideal cuando los secretos son gestionados por GitOps, SealedSecrets, o herramientas externas.

**Estructura esperada en `values.yaml`**:
```yaml
envSecret:
  enabled: true
  name: storj-env-secret
  data:
    STORJ_ACCESS: ACCESS_VALUE
    STORJ_KEY: ACCESS_KEY
    STORJ_SECRET: SECRET_KEY

args:
  - exec /entrypoint run --access "$STORJ_ACCESS" --minio.access-key "$STORJ_KEY" --minio.secret-key "$STORJ_SECRET"
```

**Ventajas**:
- Mayor seguridad frente a ConfigMap.
- Compatible con Vault Agent si prepopula el `Secret` vía controller externo.
- Declarativo y compatible con Argo CD.

---

## 🧪 Validaciones y pruebas

Para cada modo, se ha validado:

- Correcta interpolación de `args`
- Generación esperada de `ConfigMap` o anotaciones
- Inyección de secretos (modo Vault) conforme a la especificación de HashiCorp Vault Agent
- Separación estricta de lógica en `values.yaml`, sin mezclas

Comando de validación por modo:

```bash
helm template . -f values-envFrom-configMap.yaml
helm template . -f values-initContainer-configMap.yaml
helm template . -f values-vault.yaml
helm template . -f values-envFrom-Secret.yaml
```

Para comprobar sintaxis e inyección de variables:

```bash
helm install storj-release . -f values-<modo>.yaml --dry-run
```

---

## 🛠️ Requisitos

- Kubernetes >= 1.22
- Helm >= 3.10
- Vault Agent Injector habilitado en el clúster (solo en modo 3)
- Volumen persistente (`ReadWriteOnce`) en la ruta `/root/.local/share/storj/gateway`, con opción de usar un PVC preexistente (`create: false`) o permitir su creación automática (`create: true`).

---

### 📦 Volumen persistente (PVC)

El `gateway` de Storj necesita un volumen persistente en la ruta exacta `/root/.local/share/storj/gateway`.

El comportamiento del PVC depende de los valores siguientes en `values.yaml`:

```yaml
persistence:
  enabled: true          # Requiere el montaje del volumen
  existingClaim: ...     # Si se indica, Helm montará este PVC preexistente
  create: true|false     # true: el PVC será creado por Helm. false: debe existir previamente.
```

- Para los modos `initContainer` y `vault`, es obligatorio que el volumen exista y sea **escribible**.
- Para el modo `envFrom`, se requiere principalmente el volumen para los archivos temporales que pueda generar `storj`, aunque no necesariamente necesita `config.yaml`.
- En todos los casos, el `mountPath` debe ser `/root/.local/share/storj/gateway`.
- Se ha probado la combinación de `enabled: true` con `create: false` (PVC preexistente) y `create: true` (PVC gestionado por el chart).

Ejemplo para PVC gestionado por Helm:

```yaml
persistence:
  enabled: true
  create: true
  accessMode: ReadWriteOnce
  size: 1Gi
  storageClassName: "longhorn"
  mountPath: /root/.local/share/storj/gateway
```

---

## 📁 Estructura del volumen

Storj genera los siguientes ficheros:

```bash
/root/.local/share/storj/gateway/
├── config.yaml
├── minio/
└── lost+found/
```

Uso confirmado: 5.4 MiB aprox (`df -h`), por tanto el tamaño mínimo del PVC es:

```yaml
persistence:
  size: 5Mi
```

---

## ✍️ Observaciones finales

- El chart ha sido validado por fases, un modo por despliegue.
- Los `args:` se adaptan dinámicamente al tipo de configuración seleccionada.
- El diseño evita renderizados inválidos (e.g. conflicto entre Vault y `envFrom`).


