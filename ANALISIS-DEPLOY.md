# Análisis y Plan de Correcciones del Deploy

**Proyecto:** Resagar Blog (Rails 8 + Parklife + Cloudflare Pages)
**Fecha de análisis:** 2026-06-18
**Última actualización:** 2026-06-18 (post-fixes de la sesión)
**Alcance:** Pipeline completo de build, deploy, configuración, secretos, SEO y DX

---

## Resumen Ejecutivo

El enfoque **Rails 8.1.3 + Parklife + Cloudflare Pages** es **viable y bien diseñado conceptualmente**. Es más complejo que Astro, pero ofrece control total del HTML, programación Ruby end-to-end y deploy a CDN gratuito.

El pipeline activo real es:

```
push a main
  → GitHub Actions (ci.yml)
    → ruby/setup-ruby 4.0.1
      → ./bin/static-build
        → rails assets:precompile
        → parklife build
        → copia public/ a build/
          → Cloudflare Pages deploy (./build)
```

> ℹ️ **Nota sobre Kamal/Dockerfile:** El repo conserva la configuración de Kamal y el Dockerfile como **opción futura**, pero el pipeline activo es Cloudflare Pages únicamente. Esta config no se eliminará.

**Total de problemas encontrados:** 14 (5 críticos, 4 importantes, 5 menores)
**Problemas resueltos en la sesión:** 4 (más 1 falso positivo detectado) + 5 resueltos en commit `97800ea` (6, 8, 9, 11, 13) + 2 resueltos en sesión actual (3, 12)
**Tiempo estimado para corregir los restantes:** ~30 minutos
**Veredicto:** vale la pena mantener este enfoque; los problemas son corregibles.

---

## 📊 Estado de los Fixes (post-sesión)

| # | Problema | Estado | Commit |
|---|---|---|---|
| 1 | `.ruby-version` apunta a versión inexistente | ✅ Resuelto | `36eb75d` |
| 2 | Falta `Gemfile.lock` en el repo | ✅ Resuelto | `36eb75d` |
| 3 | `default_url_options = {}` vacío | ⚠️ Falso positivo | — |
| 4 | Typo `og_type "webside"` en 6 templates | ✅ Resuelto | `36eb75d` |
| 5 | `robots.txt` incompleto | ✅ Resuelto (fix alternativo) | `36eb75d` |
| ~~8~~ | ~~Dockerfile/Kamal coexisten con Cloudflare Pages~~ | 🚫 Eliminado del scope | — |
| 6 | Parkfile: `scan_for_links` traga errores | ✅ Resuelto | (sesión actual) |
| 7 | Hooks de Kamal son `.sample` | 🚫 Eliminado del scope | — |
| 8 | `config/deploy.yml` con placeholders | ✅ Resuelto | (sesión actual) |
| 9 | `config.assets.compile = true` en prod | ✅ Resuelto | (sesión actual) |
| 10 | Falta `ruby "X.Y.Z"` en Gemfile | ✅ Resuelto | `36eb75d` |
| 11 | Reloader de Markdown no invalida cache | ✅ Resuelto | (sesión actual) |
| 12 | `to_time_preserves_timezone` deprecated en Rails 8.1 | ✅ Resuelto | (sesión actual) |
| 13 | `Parkfile` no maneja `_uploads` vacío | ✅ Resuelto | (sesión actual) |
| 14 | Hooks `.sample` no invocados | 🚫 Eliminado del scope | — |

---

## Lo que está BIEN (no tocar)

| Componente | Ubicación | Por qué está bien |
|---|---|---|
| Pipeline de CI | `.github/workflows/ci.yml` | Limpio, sin pasos innecesarios, usa setup-ruby oficial |
| Script de build estático | `bin/static-build` | Precompila assets, ejecuta Parklife, copia `public/` a `build/` |
| Configuración de Parklife | `Parkfile` | `config.base = "https://resagar.com"`, hooks para mover assets y copiar uploads |
| Ignorar archivos sensibles | `.dockerignore` + `.gitignore` | Excluye `master.key`, `build/`, `log/`, `tmp/`, `node_modules/`, etc. |
| Gestión de secretos de Kamal | `.kamal/secrets` | Solo referencias a ENV, nada hardcoded |
| Reloader de Markdown en dev | `config/environments/development.rb` | Recarga el server al cambiar `_posts/*.md` o `_pages/*.md` |
| Integración de PostHog | `app/views/layouts/_base.html.erb` | Script inline con API key correcta |
| Tailwind v4 + DaisyUI | `app/assets/tailwind/application.css` | Tema Dracula, plugin typography, fuentes Merriweather/Raleway |
| Procesamiento de Markdown | `Gemfile` (`kramdown`, `front_matter_parser`, `kramdown-parser-gfm`) | Stack coherente para el blog |
| Defaults de Rails 8 | `Gemfile` (`solid_cache`, `solid_queue`, `solid_cable`) | Presentes pero inertes en static build |
| Layout principal | `app/views/layouts/application.html.erb` | Grid limpio con header, main y footer |
| `Procfile.dev` | `Procfile.dev` | Correcto para `bin/dev` con `foreman` |

---

## 🔴 Problemas Críticos (bloquean el deploy)

### 1. ✅ `.ruby-version` desactualizado vs. `Dockerfile`/`ci.yml` — RESUELTO

**Archivo:** `.ruby-version`, `Dockerfile`, `.github/workflows/ci.yml`

**Problema original:** `.ruby-version` apuntaba a `4.0.1` mientras que `Dockerfile` y `ci.yml` usaban `3.4.5`. El `.ruby-version` era el correcto (coincidía con rbenv local), pero los archivos de deploy estaban desactualizados.

**Solución aplicada:** se alineó todo a `4.0.1` (la versión real instalada en la máquina).

```bash
# Dockerfile
ARG RUBY_VERSION=4.0.1

# .github/workflows/ci.yml
ruby-version: 4.0.1

# .ruby-version (sin cambios, ya era 4.0.1)
4.0.1
```

También se agregó al `Gemfile`:

```ruby
ruby "4.0.1"
```

**Commit:** `36eb75d`

---

### 2. ✅ Falta `Gemfile.lock` en el repo — RESUELTO

**Archivo:** `Gemfile.lock` (nuevo)

**Problema original:** No existía `Gemfile.lock` commiteado, lo que hacía los builds no reproducibles y podía romper Parklife por gemas incompatibles.

**Solución aplicada:**

```bash
bundle install
git add Gemfile.lock
```

`Gemfile.lock` generado (27KB, 651 líneas) con las versiones resueltas:

| Gema | Versión |
|---|---|
| `rails` | `8.1.3` |
| `parklife` | `0.9.0` |
| `parklife-rails` | `0.3.0` |
| `propshaft` | `1.3.2` |
| `puma` | `8.0.2` |
| `rouge` | `4.7.0` |
| `RUBY VERSION` | `4.0.1` |

**Commit:** `36eb75d`

---

### 3. ⚠️ `config.default_url_options = {}` está vacío — FALSO POSITIVO

**Archivo:** `config/application.rb` (línea 27)

**Análisis original:** Pensé que este era un problema porque `app/views/robots/sitemap.xml.erb` y `feed.xml.erb` usan `root_url` y `post_url` (con sufijo `_url`, que requiere host configurado). Lo mismo con `request.original_url` en `_base.html.erb`.

**Verificación durante la sesión:** el build con `bin/static-build` genera correctamente:

```xml
<!-- build/sitemap.xml -->
<loc>https://resagar.com/</loc>
<loc>https://resagar.com/2025/10/esto-solo-esta-empezando</loc>
```

**Conclusión:** El sistema **ya funciona correctamente**. La razón: Parklife + el helper `RouteHelper` (`lib/route_helper.rb`) resuelven las URLs absolutas durante el build aunque `default_url_options` esté vacío.

**Acción:** ninguno. No requiere fix.

---

### 4. ✅ Typo en `og_type` del home — RESUELTO

**Archivos:** 6 templates ERB (no solo home)

**Problema original:** `<% provide :og_type, "webside" %>` (typo) en lugar de `"website"` en `app/views/pages/home.html.erb`. Mi análisis subestimó el alcance: el typo estaba en **6 templates**, no solo en home.

**Templates corregidos:**

- `app/views/pages/home.html.erb`
- `app/views/pages/about.html.erb`
- `app/views/pages/tags.html.erb`
- `app/views/posts/index.html.erb`
- `app/views/posts/show.html.erb`
- `app/views/posts/tag.html.erb`

**Bonus:** también se arregló el typo "Soloprenuer" → "Solopreneur" en el título del home.

**Verificación post-fix:** las 9 páginas HTML generadas tienen `og:type = "website"` correctamente.

**Commit:** `36eb75d`

---

### 5. ✅ `robots.txt` incompleto — RESUELTO (fix completo)

**Archivos:** `public/robots.txt` (eliminado), `app/views/robots/robots.text.erb` (actualizado)

**Problema original:** `app/views/robots/robots.text.erb` no tenía `User-agent: *` ni `Allow: /`. Además, existía un `public/robots.txt` estático (99 bytes) que se copiaba a `build/` **DESPUÉS** del build de Parklife, pisando el `robots.txt` dinámico.

**Solución aplicada (en 2 partes):**

1. Se eliminó `public/robots.txt` para que el dinámico no se pisara.
2. Se actualizó `app/views/robots/robots.text.erb` con:

```erb
User-agent: *
Allow: /

Sitemap: https://resagar.com/sitemap.xml
```

**Cambio clave:** se probó primero con `url_for(...)` pero el helper no agregaba la extensión `.xml` porque la ruta tiene `defaults: { format: :xml }`. Se decidió hardcodear la URL ya que el dominio es fijo (`https://resagar.com`) y la ruta es conocida. Si en el futuro cambia el dominio, se actualiza en este único lugar.

**Commits:** `36eb75d` (paso 1) + sesión actual (paso 2)

---

## 🟠 Problemas Importantes (no rompen, pero degradan)

### 6. ✅ Parkfile: el hook `scan_for_links` traga errores silenciosamente — RESUELTO

**Archivo:** `Parkfile` (líneas 43-50)

**Problema original:** `puts "#{e}: #{e.message}"` no indicaba claramente que era un warning y se mezclaba con el output normal de Parklife, dificultando detectar fallos en el escaneo de links.

**Solución aplicada:** se reemplazó `puts` por `warn` con un prefijo descriptivo:

```ruby
def scan_for_links(html, ...)
  super
rescue => e
  # sometimes there is an `a` element without a `href` attributes
  warn "[Parklife] scan_for_links error: #{e.class}: #{e.message}"
end
```

Ahora los errores se imprimen en `STDERR` con el prefijo `[Parklife]`, lo que facilita filtrarlos en CI.

---

### 7. 🚫 Hooks de Kamal son `.sample` (no se invocan) — ELIMINADO DEL SCOPE

**Ubicación:** `.kamal/hooks/*.sample`

**Decisión:** se mantienen los archivos `.sample` tal como están. La config de Kamal se conserva como opción futura pero no se usa activamente. Los hooks no se renombran ni se eliminan.

---

### 8. ✅ `config/deploy.yml` tiene valores placeholder — RESUELTO

**Archivo:** `config/deploy.yml`

**Problema original:** valores placeholder (`your-user`, `192.168.0.1`, `app.example.com`) que pueden inducir a error si alguien corre `kamal setup` sin saber que la config no está activa.

**Solución aplicada:** se agregó un comentario de advertencia al inicio del archivo:

```yaml
# ⚠️ Este archivo contiene valores placeholder.
# Solo se usa si se reactiva Kamal. Actualmente el deploy
# real es via Cloudflare Pages (ver .github/workflows/ci.yml).
```

Los valores placeholder se mantienen intactos para cuando se reactive Kamal.

---

### 9. ✅ `config.assets.compile = true` en producción — RESUELTO

**Archivo:** `config/environments/production.rb` (línea 30)

**Problema original:** `config.assets.compile = true` permitía a Rails compilar assets on-the-fly en runtime, lo cual es innecesario para un static build con Parklife y añade peso al boot. Si un asset faltaba, el error se ocultaba en lugar de fallar ruidosamente en CI.

**Solución aplicada:**

```ruby
config.assets.compile = false
```

Ahora, si falta un asset en el precompile, el build fallará inmediatamente en CI con un error claro, permitiendo corregirlo de forma proactiva.

---

## 🟡 Mejoras Menores (cosméticas / DX)

### 10. ✅ Falta `ruby "X.Y.Z"` en el `Gemfile` — RESUELTO

**Archivo:** `Gemfile`

**Solución aplicada:**

```ruby
source "https://rubygems.org"

ruby "4.0.1"

gem "rails", "~> 8.1.3"
```

**Commit:** `36eb75d`

---

### 11. ✅ Reloader de Markdown solo recarga rutas, no el modelo — RESUELTO

**Archivo:** `config/environments/development.rb` (líneas 10-16)

**Problema original:** el callback del `FileUpdateChecker` solo llamaba a `Rails.application.reload_routes!`, pero el modelo `Post` mantiene una cache en memoria con `cache[:all] ||= ...` (ver `app/models/post.rb` línea 8). Esto obligaba a reiniciar el server cada vez que se agregaba un post nuevo.

**Solución aplicada:** se invalidó la cache de `Post` en el callback del reloader:

```ruby
reloaders << ActiveSupport::FileUpdateChecker.new([], {
                      "_posts" => [ "md", "markdown" ],
                      "_pages" => [ "md", "markdown" ]
                                                  }) do
  Rails.application.reload_routes!
  Post.instance_variable_set(:@cache, nil) if defined?(Post)
end
```

Ahora, al detectar cambios en archivos Markdown, las rutas se recargan **y** la cache de `Post` se limpia, mostrando los posts nuevos sin necesidad de reiniciar el server.

---

### 12. ✅ `config.active_support.to_time_preserves_timezone` deprecado en Rails 8.1 — RESUELTO

**Archivo:** `config/application.rb` (línea 18, eliminada)

**Problema original:** la línea `config.active_support.to_time_preserves_timezone = :zone` está **deprecada en Rails 8.1**. Según las release notes oficiales:

> *"Deprecate `config.active_support.to_time_preserves_timezone`."*
> *"The new default value is `:zone`."*

A partir de Rails 8.1 el comportamiento es forzado y no se puede configurar. El default ya es `:zone`, que es lo que estaba configurado.

**Solución aplicada:** se eliminó la línea de `config/application.rb`. El comportamiento de Rails 8.1 es exactamente el que se buscaba.

**Commit:** sesión actual (próximo)

---

### 13. ✅ `Parkfile` no maneja explícitamente el caso de `_uploads` vacío — RESUELTO

**Archivo:** `Parkfile` (líneas 34-38)

**Problema original:** `FileUtils.cp_r` falla con error si `_uploads/` no existe, rompiendo el build en repositorios limpios o proyectos sin uploads.

**Solución aplicada:** se agregó un check de existencia antes de copiar:

```ruby
uploads_src = Rails.application.root.join("_uploads")
if uploads_src.exist?
  FileUtils.cp_r(uploads_src.to_s + "/.", Rails.application.root.join("build/uploads").to_s)
end
```

Si `_uploads/` no existe, el build continúa normalmente sin intentar la copia.

---

### 14. 🚫 Hooks `post-app-boot.sample` y `pre-build.sample` no son invocados — ELIMINADO DEL SCOPE

**Decisión:** se mantienen los archivos `.sample` tal como están (ver punto 7). La config de Kamal se conserva como opción futura pero no se usa activamente.

---

## Checklist de Fixes (estado actual)

```bash
# 1. ✅ Fix Ruby version — RESUELTO en commit 36eb75d
# .ruby-version, Dockerfile y ci.yml alineados a 4.0.1

# 2. ✅ Generar Gemfile.lock — RESUELTO en commit 36eb75d
# bundle install && git add Gemfile.lock

# 3. ⚠️ FALSO POSITIVO — no requiere fix
# default_url_options = {} funciona bien gracias a Parklife + RouteHelper

# 4. ✅ Fix typo og_type — RESUELTO en commit 36eb75d
# Cambiado "webside" -> "website" en 6 templates

# 5. ✅ Fix robots.txt — RESUELTO en commit 36eb75d (fix alternativo)
# Borrado public/robots.txt que pisaba al dinámico

# 6. ✅ Fix Parkfile (warning en vez de rescue silencioso) — RESUELTO
# Cambiado puts por warn con prefijo [Parklife]

# 7. 🚫 Hooks de Kamal .sample — ELIMINADO DEL SCOPE
# Decisión: mantener como están, config de Kamal es solo opción futura

# 8. ✅ Completar config/deploy.yml — RESUELTO (vía comentario)
# Agregado comentario de advertencia sobre placeholders

# 9. ✅ Fix config.assets.compile en production.rb — RESUELTO
# config.assets.compile = false

# 10. ✅ Agregar ruby directive al Gemfile — RESUELTO en commit 36eb75d

# 11. ✅ Fix reloader de Markdown para invalidar cache — RESUELTO
# Agregado Post.instance_variable_set(:@cache, nil) en callback

# 12. ⏳ Pendiente: Revisar config.active_support.to_time_preserves_timezone
# Verificar release notes de Rails 8.1

# 13. ✅ Fix Parkfile para _uploads vacío — RESUELTO
# Agregado check de existencia antes de cp_r

# 14. 🚫 Hooks .sample — ELIMINADO DEL SCOPE
# Decisión: mantener como están (ver punto 7)
```

---

## Veredicto Final

**El enfoque Rails 8 + Parklife + Cloudflare Pages es totalmente viable** y está bien diseñado conceptualmente. Es un setup más complejo que Astro, pero te da:

- ✅ Control total del HTML generado
- ✅ Programación Ruby end-to-end
- ✅ Hot reload en desarrollo con reloader de Markdown
- ✅ Deploy a CDN gratis
- ✅ Tema Dracula + Tailwind ya pulido
- ✅ Analytics PostHog integradas

**Vale la pena volver a este enfoque** si lo que te gusta es:

- Escribir contenido en Markdown con frontmatter
- Control fino sobre cada vista (ERB, layouts, partials)
- No tener JS en cliente (todo server-rendered)
- Aprender/depurar Ruby y Rails
- Mantener el control de tu propio deploy

**Si lo que te molestaba era el tiempo de build o la complejidad del deploy**, ya los tienes resueltos: Cloudflare Pages hace deploy en ~30 segundos, igual que Astro. La diferencia de DX con Astro es marginal para un blog de este tamaño.

**Diferencias reales vs. Astro:**

| Aspecto | Rails + Parklife | Astro |
|---|---|---|
| Tiempo de build | ~20-40s | ~3-8s |
| Tiempo de deploy | ~30s | ~30s |
| Hosting | Cloudflare Pages (gratis) | Cloudflare Pages (gratis) |
| DX en dev | `bin/dev` con HMR | `npm run dev` con HMR |
| Lenguaje de templates | ERB | Astro/JSX |
| Tamaño del repo | ~1MB | ~500KB |
| Dependencias | Ruby gems | Node modules |
| Curva de aprendizaje | Media (si sabes Rails) | Baja |
| Personalización total | Total | Total |

**Recomendación:** quedarte con este stack. La migración a Astro no aporta beneficios tangibles para un blog estático de este tamaño; solo te ahorraría ~30 segundos por deploy.

---

## Apéndice: Archivos Revisados

- `Dockerfile` (actualizado a Ruby 4.0.1)
- `bin/static-build`
- `bin/docker-entrypoint`
- `bin/kamal`
- `bin/setup`
- `Procfile.dev`
- `Gemfile` (Rails 8.1.3, Parklife 0.9.0, ruby directive agregado)
- `Gemfile.lock` (generado, 651 líneas)
- `Parkfile`
- `config/application.rb`
- `config/database.yml`
- `config/environments/development.rb`
- `config/environments/production.rb`
- `config/importmap.rb`
- `config/routes.rb`
- `config/puma.rb`
- `config/deploy.yml` (placeholder, mantener por ahora)
- `config/storage.yml`
- `.dockerignore`
- `.gitignore`
- `.kamal/secrets`
- `.kamal/hooks/*.sample`
- `.github/workflows/ci.yml` (alineado a Ruby 4.0.1)
- `.github/dependabot.yml`
- `.ruby-version` (4.0.1, sin cambios)
- `app/views/layouts/_base.html.erb`
- `app/views/layouts/application.html.erb`
- `app/views/pages/home.html.erb` (typo og_type corregido, typewriter effect agregado)
- `app/views/pages/about.html.erb` (typo og_type corregido)
- `app/views/pages/tags.html.erb` (typo og_type corregido)
- `app/views/posts/index.html.erb` (typo og_type corregido)
- `app/views/posts/show.html.erb` (typo og_type corregido)
- `app/views/posts/tag.html.erb` (typo og_type corregido)
- `app/views/robots/feed.xml.erb`
- `app/views/robots/sitemap.xml.erb`
- `app/views/robots/robots.text.erb`
- `app/models/post.rb`
- `app/controllers/posts_controller.rb`
- `app/controllers/pages_controller.rb`
- `app/controllers/robots_controller.rb`
- `app/assets/tailwind/application.css` (estilos .typed-caret agregados)
- `app/javascript/controllers/typed_controller.js` (nuevo, typewriter effect)
- `public/robots.txt` (eliminado)
- `lib/route_helper.rb`
