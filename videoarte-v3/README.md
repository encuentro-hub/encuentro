# Videoarte Net v3 — Guía de instalación

## Qué hay de nuevo en v3
- Modal de detalle centrado con vídeo, tres columnas y tabs
- Favoritos y watchlist por usuario
- Perfil de usuario a pantalla completa con sub-redes de nodos
- Perfiles públicos/privados compartibles por URL (`?profile=user_id`)
- Sistema de comentarios moderados con preguntas establecidas + campo libre
- Opción de comentar como anónimo

---

## Estructura
```
videoarte-net-v3/
├── supabase_schema.sql
├── frontend/
│   └── index.html
└── server/
    ├── package.json  (igual que v2, no cambia)
    ├── .env.example  (igual que v2, no cambia)
    └── index.js
```

---

## Migración desde v2

### 1. Supabase — tablas nuevas
Ve a **SQL Editor → New query** y ejecuta el schema completo `supabase_schema.sql`.
Si ya tienes datos, las tablas existentes tienen `create table if not exists` y no se tocan.
Las tablas nuevas son: `user_saves`, `user_settings`, `questions`, `comments`.

El trigger `handle_new_user` se actualiza para crear también una fila en `user_settings`.

### 2. Servidor — reemplaza `index.js`
Copia el nuevo `server/index.js` a tu repo. No cambia ni `package.json` ni `.env`.

### 3. Frontend — reemplaza `index.html`
Copia el nuevo `frontend/index.html`. Recuerda cambiar la línea:
```js
const API = 'https://tu-servidor.railway.app';
```

---

## Nuevos endpoints

### Guardados
| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/saves/mine` | ✓ | Mis favoritos y watchlist |
| POST | `/saves` | ✓ | `{ piece_id, type: 'favorite'\|'watchlist' }` |
| DELETE | `/saves/:piece_id/:type` | ✓ | Eliminar guardado |
| GET | `/saves/user/:user_id` | — | Guardados públicos de otro usuario |

### Perfil y ajustes
| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/profile/:user_id` | — | Perfil público |
| GET | `/settings` | ✓ | Mis ajustes |
| PATCH | `/settings` | ✓ | `{ maps_public: true\|false }` |

### Preguntas
| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/questions?piece_id=xxx` | — | Preguntas globales + de esa pieza |
| POST | `/questions` | Admin | `{ text, piece_id?, order_idx? }` |
| PATCH | `/questions/:id` | Admin | Editar pregunta |
| DELETE | `/questions/:id` | Admin | Desactivar pregunta |

### Comentarios
| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/comments/:piece_id` | — | Comentarios aprobados |
| GET | `/comments/:piece_id/mine` | ✓ | Mis comentarios (incluye pendientes) |
| POST | `/comments` | ✓ | `{ piece_id, text, question_id?, anonymous? }` |
| DELETE | `/comments/:id` | ✓ | Borrar el mío |
| PATCH | `/comments/:id/approve` | Admin | Aprobar comentario |
| DELETE | `/comments/:id/reject` | Admin | Rechazar comentario |
| GET | `/comments-pending` | Admin | Ver pendientes de moderación |

---

## Flujo de moderación de comentarios

El usuario envía un comentario → queda en `approved = false` → el frontend muestra "PENDIENTE DE APROBACIÓN" solo al autor → vosotras revisáis con:

```bash
# Ver pendientes
curl https://tu-servidor.railway.app/comments-pending \
  -H "x-admin-token: TU_TOKEN"

# Aprobar
curl -X PATCH https://tu-servidor.railway.app/comments/ID_COMENTARIO/approve \
  -H "x-admin-token: TU_TOKEN"

# Rechazar
curl -X DELETE https://tu-servidor.railway.app/comments/ID_COMENTARIO/reject \
  -H "x-admin-token: TU_TOKEN"
```

---

## Añadir preguntas

```bash
# Pregunta global (aparece en todos los vídeos)
curl -X POST https://tu-servidor.railway.app/questions \
  -H "Content-Type: application/json" \
  -H "x-admin-token: TU_TOKEN" \
  -d '{"text": "¿Qué sensación te evoca esta pieza?", "order_idx": 1}'

# Pregunta específica de un vídeo
curl -X POST https://tu-servidor.railway.app/questions \
  -H "Content-Type: application/json" \
  -H "x-admin-token: TU_TOKEN" \
  -d '{"text": "¿Cómo lees la relación entre cuerpo y tecnología aquí?", "piece_id": "UUID_DE_LA_PIEZA", "order_idx": 1}'
```

---

## Perfiles públicos

Cuando un usuario activa "PÚBLICO" en su perfil, se genera una URL del tipo:
```
https://tu-dominio.netlify.app/?profile=abc123-uuid
```

Cualquiera que abra esa URL verá sus mapas de favoritos y watchlist directamente.
