# Videoarte Net — Guía de despliegue desde cero

## Estructura del repositorio

```
tu-repo/
├── docs/
│   └── index.html          ← frontend (GitHub Pages lo sirve desde aquí)
├── server/
│   ├── index.js
│   ├── package.json
│   └── .env.example
├── supabase_schema.sql
└── README.md
```

---

## PASO 1 — Supabase (base de datos y autenticación)

### 1.1 Crear cuenta y proyecto
1. Ve a https://supabase.com y crea una cuenta gratuita
2. Haz clic en **New project**
3. Ponle un nombre, elige una región cercana (EU West para España) y una contraseña de base de datos (guárdala)
4. Espera 1-2 minutos a que el proyecto arranque

### 1.2 Ejecutar el schema
1. En el panel de Supabase, ve a **SQL Editor** (icono de terminal en el menú izquierdo)
2. Haz clic en **New query**
3. Copia todo el contenido de `supabase_schema.sql` y pégalo
4. Haz clic en **Run** (o Ctrl+Enter)
5. Deberías ver "Success. No rows returned" — eso es correcto

### 1.3 Configurar autenticación
1. Ve a **Authentication → Providers**
2. Asegúrate de que **Email** está activado
3. Para desarrollo: desactiva "Confirm email" (así los usuarios no necesitan confirmar el email)
4. Para producción: déjalo activado

### 1.4 Configurar URLs permitidas
1. Ve a **Authentication → URL Configuration**
2. En **Site URL** pon la URL de tu GitHub Pages (la sabrás después del paso 3):
   ```
   https://tu-usuario.github.io/tu-repo
   ```
3. En **Redirect URLs** añade la misma URL

### 1.5 Copiar las credenciales
Ve a **Project Settings → API** y copia estos tres valores — los necesitarás en el paso 2:
- **Project URL** → es tu `SUPABASE_URL`
- **anon public** → es tu `SUPABASE_ANON_KEY`
- **service_role** (haz clic en "Reveal") → es tu `SUPABASE_SERVICE_KEY`

⚠️ La `service_role` key tiene acceso total a tu base de datos. Nunca la pongas en el frontend ni la subas a GitHub.

---

## PASO 2 — GitHub (código y frontend)

### 2.1 Crear el repositorio
1. Ve a https://github.com y crea una cuenta si no tienes
2. Haz clic en **New repository**
3. Ponle un nombre (por ejemplo `videoarte-net`)
4. Déjalo **Public** (necesario para GitHub Pages gratuito)
5. Haz clic en **Create repository**

### 2.2 Subir los archivos
La forma más fácil sin usar Git en la terminal:

1. En tu repo vacío, haz clic en **uploading an existing file**
2. Arrastra toda la carpeta del proyecto (o sube los archivos uno a uno)
3. Asegúrate de que la estructura queda exactamente así:
   ```
   docs/index.html
   server/index.js
   server/package.json
   server/.env.example
   supabase_schema.sql
   README.md
   ```
4. Haz clic en **Commit changes**

### 2.3 Activar GitHub Pages
1. Ve a tu repo → **Settings** (pestaña superior)
2. En el menú izquierdo busca **Pages**
3. En **Source** selecciona:
   - Branch: `main`
   - Folder: `/docs`
4. Haz clic en **Save**
5. Espera 1-2 minutos — GitHub te mostrará la URL:
   ```
   https://tu-usuario.github.io/tu-repo
   ```

### 2.4 Actualizar la URL de la API en el frontend
1. En GitHub, navega a `docs/index.html`
2. Haz clic en el lápiz (Edit)
3. Busca esta línea cerca del principio del `<script>`:
   ```js
   const API = 'https://pruebaencuentro-production.up.railway.app';
   ```
4. Cámbiala por la URL de Render que obtendrás en el paso 3 — de momento déjala así y vuelve después
5. Haz clic en **Commit changes**

---

## PASO 3 — Render (servidor backend)

### 3.1 Crear cuenta
1. Ve a https://render.com y crea una cuenta gratuita
2. Conecta tu cuenta de GitHub cuando te lo pida

### 3.2 Crear el Web Service
1. Haz clic en **New +** → **Web Service**
2. Selecciona tu repositorio de GitHub (`videoarte-net`)
3. Configura así:
   - **Name**: `videoarte-net` (o el nombre que quieras)
   - **Region**: Frankfurt (la más cercana a España)
   - **Branch**: `main`
   - **Root Directory**: `server` ← importante, sin esto no encuentra el package.json
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free

4. Haz clic en **Create Web Service**

### 3.3 Añadir las variables de entorno
Antes de que el servidor arranque necesita las credenciales. En la página del servicio:

1. Ve a la pestaña **Environment**
2. Haz clic en **Add Environment Variable** para cada una:

| Key | Value |
|-----|-------|
| `SUPABASE_URL` | La URL del proyecto de Supabase |
| `SUPABASE_SERVICE_KEY` | La service_role key de Supabase |
| `SUPABASE_ANON_KEY` | La anon public key de Supabase |
| `ADMIN_TOKEN` | Un token secreto que tú inventas (ver abajo) |

⚠️ NO añadas `PORT` — Render lo inyecta automáticamente.

### 3.4 Generar el ADMIN_TOKEN
El admin token es una contraseña que usaréis para añadir piezas, aprobar comentarios, etc. Genera uno seguro abriendo la terminal de tu ordenador y ejecutando:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Copia el resultado (una cadena larga de letras y números) y úsalo como `ADMIN_TOKEN`. Guárdalo en un lugar seguro.

Si no tienes Node instalado, también puedes usar cualquier generador de contraseñas con 40+ caracteres.

### 3.5 Esperar el despliegue
1. Ve a la pestaña **Logs** del servicio
2. Espera a ver el mensaje: `Videoarte Net API v3 en http://localhost:XXXX`
3. La URL pública de tu servidor será algo como:
   ```
   https://videoarte-net.onrender.com
   ```

### 3.6 Actualizar la URL en el frontend
Ahora vuelve a GitHub → `docs/index.html` → editar → y cambia:
```js
const API = 'https://videoarte-net.onrender.com';
```
por tu URL real de Render.

---

## PASO 4 — Verificar que todo funciona

Abre tu URL de GitHub Pages en el navegador. Deberías ver la pantalla con `CARGANDO_` y luego la red de nodos vacía (todavía no hay piezas).

Para comprobar que el servidor responde, abre:
```
https://videoarte-net.onrender.com/pieces
```
Debería devolver `[]` (array vacío).

---

## PASO 5 — Añadir contenido

### Añadir una pieza
```bash
curl -X POST https://videoarte-net.onrender.com/pieces \
  -H "Content-Type: application/json" \
  -H "x-admin-token: TU_ADMIN_TOKEN" \
  -d '{
    "title": "Cuerpo sin órganos",
    "author": "Elena Vidal",
    "tags": ["cuerpo", "fragmento", "loop"],
    "vimeo_url": "https://player.vimeo.com/video/ID_DEL_VIDEO",
    "vimeo_thumb": "https://i.vimeocdn.com/video/ID_THUMB.jpg",
    "year": 2023
  }'
```

La URL de Vimeo tiene el formato `https://player.vimeo.com/video/XXXXXXX` donde `XXXXXXX` es el ID numérico del vídeo.

Para la miniatura, puedes obtenerla desde la API de Vimeo o simplemente omitir el campo `vimeo_thumb` — el nodo mostrará un gráfico ASCII en su lugar.

### Añadir preguntas de reflexión (globales)
```bash
curl -X POST https://videoarte-net.onrender.com/questions \
  -H "Content-Type: application/json" \
  -H "x-admin-token: TU_ADMIN_TOKEN" \
  -d '{
    "text": "¿Qué sensación o recuerdo te evoca esta pieza?",
    "order_idx": 1
  }'
```

### Añadir una pregunta específica para una pieza
```bash
curl -X POST https://videoarte-net.onrender.com/questions \
  -H "Content-Type: application/json" \
  -H "x-admin-token: TU_ADMIN_TOKEN" \
  -d '{
    "text": "¿Cómo lees la relación entre cuerpo y tecnología aquí?",
    "piece_id": "UUID_DE_LA_PIEZA",
    "order_idx": 1
  }'
```

### Moderar comentarios
```bash
# Ver comentarios pendientes
curl https://videoarte-net.onrender.com/comments-pending \
  -H "x-admin-token: TU_ADMIN_TOKEN"

# Aprobar un comentario
curl -X PATCH https://videoarte-net.onrender.com/comments/ID_COMENTARIO/approve \
  -H "x-admin-token: TU_ADMIN_TOKEN"

# Rechazar un comentario
curl -X DELETE https://videoarte-net.onrender.com/comments/ID_COMENTARIO/reject \
  -H "x-admin-token: TU_ADMIN_TOKEN"
```

---

## Notas importantes

**Render free tier**: El servidor se duerme después de 15 minutos sin actividad. La primera petición tras el reposo tarda 30-60 segundos. Es normal — es la limitación del plan gratuito.

**Actualizar el frontend**: Cada vez que edites `docs/index.html` en GitHub, GitHub Pages lo publica automáticamente en 1-2 minutos.

**Actualizar el servidor**: Cada vez que edites cualquier archivo en la carpeta `server/` en GitHub, Render redespliega automáticamente.

**Supabase URL en autenticación**: Si cambias la URL del frontend (por ejemplo si añadís un dominio propio), recuerda actualizar el Site URL en Supabase → Authentication → URL Configuration.

---

## Resumen de URLs

| Servicio | URL |
|----------|-----|
| Frontend | `https://tu-usuario.github.io/tu-repo` |
| Backend API | `https://tu-app.onrender.com` |
| Supabase dashboard | `https://supabase.com/dashboard/project/TU_PROJECT_ID` |
