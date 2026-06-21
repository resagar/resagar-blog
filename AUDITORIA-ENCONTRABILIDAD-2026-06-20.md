# Auditoría de Encontrabilidad — Resagar Blog

**Fecha:** 2026-06-20
**Autor del análisis:** Auditoría automatizada (webfetch + revisión de código)
**Score de encontrabilidad actual estimado:** 9.4/10
**Objetivo:** Llegar a 9.7/10 con los quick wins de las sesiones 1-2 (30-90 min de trabajo)
**Documento complementario:** `MEJORAS-ENCONTRABILIDAD.md` (creado 2026-06-19, contiene el plan original)

---

## ⚠️ Estado al 2026-06-20 — Tags deshabilitados

El sistema de tags fue **deshabilitado temporalmente** el 2026-06-20. Los issues #3 y #5 de este documento (que dependían del sistema de tags activo) quedan **pospuestos** hasta que se reactive. Los tags se siguen definiendo en los frontmatters de los posts y se muestran como texto plano, pero no son clickeables y las páginas de tags no se generan en el build.

**Cambios aplicados:**
- `app/views/posts/_post.html.erb:13` — `link_to tag, tag_path(...)` → `tag` (texto plano)
- `config/routes.rb:24-32` — 3 rutas de tags comentadas con instrucciones de reactivación
- **Preservado para futura reactivación:** frontmatters con `tags:`, modelo `Post#tags`, vistas, controllers, helper `direct :tag`

---

## 📋 Metodología

El análisis cubrió dos dimensiones:

1. **Código base** — revisión de templates, controllers, rutas, configs y frontmatter
2. **Producción** — requests HTTP reales contra `https://resagar.com` para validar lo que Google ve

Se contrastaron ambos para encontrar inconsistencias y bugs que solo se ven en uno de los dos lados.

---

## 🔴 Issues Críticos (afectan descubribilidad directamente)

### Issue #1 — Sitemap incompleto

**Archivo:** `app/controllers/robots_controller.rb` (líneas 12-19)

**Código actual:**
```ruby
def sitemap
  @entries = []
  @entries << SitemapEntry.new(loc: root_url)
  @entries += Post.all.map do |post|
    SitemapEntry.new(loc: post_url(post))
  end
end
```

**Producción actual** (`https://resagar.com/sitemap.xml`):
```xml
<urlset>
  <loc>https://resagar.com/</loc>
  <loc>https://resagar.com/about</loc>
  <loc>https://resagar.com/now</loc>
  <loc>https://resagar.com/tags</loc>
  <loc>https://resagar.com/2025/10/esto-solo-esta-empezando</loc>
</urlset>
```

**Páginas que existen pero NO están explícitamente en el sitemap:**

- `/posts` (índice de posts)
- ~~`/posts/tags/emprendimiento`~~ (pospuesto — tags deshabilitados)
- ~~`/posts/tags/indie-hacker`~~ (pospuesto — tags deshabilitados)
- ~~`/posts/tags/historia`~~ (pospuesto — tags deshabilitados)

Las que aparecen (`/about`, `/now`, `/tags`) están porque Parklife las crawleó durante el build, no porque el controller las declare. Esto es frágil: si cambiás `crawl: true` a `crawl: false` en el Parkfile, esas páginas dejan de aparecer.

> **⚠️ Pospuesto:** con el sistema de tags deshabilitado (ver nota al inicio), las tag pages ya no se generan en el build y el fix queda incompleto hasta que se reactiven. El sitemap ahora solo necesita agregar `/posts` y `/tags`.

**Impacto SEO:** Google puede demorar más en descubrir e indexar `/posts` (que es la página más importante de las que faltan). Las tag pages ya no son relevantes hasta reactivar.

**Fix recomendado (actualizado):** extender el controller para incluir todas las páginas estáticas. Los tag pages dinámicos se agregan cuando se reactive el feature.

```ruby
def sitemap
  @entries = []

  # Páginas estáticas
  %w[/ /about /now /tags].each do |path|
    @entries << SitemapEntry.new(loc: "#{Rails.application.config.x.site_url}#{path}")
  end

  # Índice de posts
  @entries << SitemapEntry.new(loc: posts_list_url)

  # Tag pages dinámicas
  Post.tags.each do |tag|
    @entries << SitemapEntry.new(loc: tag_url(tag.parameterize))
  end

  # Posts individuales
  @entries += Post.all.map do |post|
    SitemapEntry.new(loc: post_url(post))
  end
end
```

**Esfuerzo:** 15 min
**Prioridad:** 🔴 Alta

---

### Issue #2 — Link de feed roto

**Archivo:** `app/views/layouts/_base.html.erb` (líneas 60-65)

**Template actual:**
```erb
<link
  rel="alternate"
  type="application/rss+xml"
  title="Resagar.com"
  href="<%= feed_url(format: :xml) %>"
>
```

**Producción actual** (en TODAS las páginas):
```html
<link rel="alternate" type="application/rss+xml" title="Resagar.com" href="https://resagar.com/feed">
```

**Comportamiento observado:**
- `https://resagar.com/feed` → ❌ **404 Not Found**
- `https://resagar.com/feed.xml` → ✅ 200 con el RSS válido

**Causa:** la combinación de `config.default_url_options = {}` (vacío) con la ruta `get "feed", to: "robots#feed", as: :feed, format: :xml, defaults: { format: :xml }` hace que `feed_url(format: :xml)` genere la URL sin la extensión `.xml`.

**Impacto SEO:** usuarios que hacen clic en el ícono RSS del nav, o RSS readers que descubren el feed vía `<link rel="alternate">`, obtienen 404. Esto afecta directamente la distribución del contenido.

**Fix recomendado (opción A — corregir el helper):** agregar la extensión manualmente en el template:

```erb
href="<%= "#{Rails.application.config.x.site_url}/feed.xml" %>"
```

**Fix recomendado (opción B — configurar `default_url_options`):** agregar host a `config/application.rb`:

```ruby
config.default_url_options = { host: "resagar.com", protocol: "https" }
```

La opción A es más simple y menos invasiva.

**Esfuerzo:** 5 min
**Prioridad:** 🔴 Alta

---

### Issue #3 — Página `/tags` vacía

> **⚠️ Pospuesto — feature deshabilitada (2026-06-20).** El sistema de tags completo está deshabilitado. Este issue se reactiva junto con todo el sistema cuando se vuelva a implementar.

**Archivo:** `app/views/pages/tags.html.erb` (5 líneas, sin body)

**Código actual:**
```erb
<% provide :title, "Rene Garcia — Software, escritura y paternidad neurodivergente" %>
<% provide :description,
  "Developer, escritor y padre con TDAH y AACC. Construyo un negocio en software y escritura con una mente que es mi mayor ventaja y mi peor enemiga." %>
<% provide :og_image, "https://mugshotbot.com/m/5YypF97U" %>
<% provide :og_type, "website" %>
```

**Producción actual** (`https://resagar.com/tags`):
```html
<main role="main" class="pt-32 pb-28 px-28">
</main>
```

**Impacto SEO:** Google indexa una página sin contenido. Peor ranking en resultados de búsqueda, mala UX para usuarios que llegan desde Google, canibalización con otras páginas.

**Fix recomendado:** agregar el listado de tags con sus conteos:

```erb
<% provide :title, "Tags — Rene Garcia" %>
<% provide :description,
  "Todos los tags de mi blog. Ruby on Rails, emprendimiento, TDAH, paternidad, indie hacking y mas." %>
<% provide :og_image, "https://mugshotbot.com/m/5YypF97U" %>
<% provide :og_type, "website" %>

<article class="prose max-w-3xl mx-auto py-8">
  <header class="pb-6 not-prose">
    <h1 class="text-5xl font-sans font-bold">Tags</h1>
    <p class="text-sm opacity-50 font-sans mb-2">Explora todos los temas del blog.</p>
  </header>

  <div class="flex flex-wrap gap-3 not-prose">
    <% Post.tags.each do |tag| %>
      <%= link_to "#{tag} (#{Post.all.count { |p| p.tags.include?(tag) }})",
                  tag_path(tag.parameterize),
                  class: "btn btn-outline border-base-300" %>
    <% end %>
  </div>
</article>
```

**Esfuerzo:** 30 min
**Prioridad:** 🔴 Alta

---

## 🟠 Issues Altos (afectan ranking y compartibilidad)

### Issue #4 — `og:type: "article"` falta en posts

**Archivo:** `app/views/posts/show.html.erb` (línea 4)

**Código actual:**
```erb
<% provide :og_type, "website" %>
```

**Producción actual:** todas las páginas (incluso posts individuales) declaran `og:type = "website"`.

**Impacto SEO:** Facebook, LinkedIn, Twitter y otras plataformas distinguen entre `article` y `website` y dan mejor tratamiento visual al primero (más espacio en preview, mejor categorización, opción de "Read more" más prominente).

**Fix recomendado:**

```erb
<% provide :og_type, "article" %>
```

**Esfuerzo:** 2 min
**Prioridad:** 🟠 Media

---

### Issue #5 — Tag pages con metadata genérica

> **⚠️ Pospuesto — feature deshabilitada (2026-06-20).** El sistema de tags completo está deshabilitado. Este issue se reactiva junto con todo el sistema cuando se vuelva a implementar.

**Archivo:** `app/views/posts/tag.html.erb` (líneas 1-5)

**Código actual:**
```erb
<% provide :title, "Rene Garcia — Software, escritura y paternidad neurodivergente" %>
<% provide :description,
  "Developer, escritor y padre con TDAH y AACC. Construyo un negocio en software y escritura con una mente que es mi mayor ventaja y mi peor enemiga." %>
```

**Producción actual:** las 3 tag pages (`emprendimiento`, `indie-hacker`, `historia`) tienen el mismo title y description que el home y el about.

**Impacto SEO:** Google ve 3 páginas con contenido distinto pero metadata idéntica. No rankean para búsquedas específicas de cada tag. Canibalización SEO entre las tag pages.

**Fix recomendado:**

```erb
<% provide :title, "Posts sobre #{@tag} — Rene Garcia" %>
<% provide :description,
  "Todos mis articulos tagged con '#{@tag}'. Ruby on Rails, emprendimiento, indie hacking y paternidad." %>
<% provide :og_image, "https://mugshotbot.com/m/5YypF97U" %>
<% provide :og_type, "website" %>
```

**Esfuerzo:** 10 min
**Prioridad:** 🟠 Media

---

### Issue #6 — Imágenes sin `alt` text

**Archivos afectados (4 occurrences):**

| Archivo | Línea | Uso |
|---|---|---|
| `app/views/pages/home.html.erb` | 9-12 | Foto principal de Rene en home |
| `app/views/pages/about.html.erb` | 16 | Foto en about |
| `app/views/layouts/_nav.html.erb` | 5 | Avatar pequeño en nav (todas las páginas) |
| `app/views/layouts/_base.html.erb` (público) | — | (revisar si hay más) |

**Código actual (ejemplo):**
```erb
<%= image_tag("perfil2.jpg", class: "size-72 rounded-xl object-cover rotate-[-3deg]") %>
```

**Producción actual:**
```html
<img class="size-72 rounded-xl object-cover rotate-[-3deg]" src="/assets/perfil2-5740c7e0.jpg" />
```

**Impacto SEO:**
- 🔴 Accesibilidad: lectores de pantalla no pueden describir la imagen a usuarios con discapacidad visual
- 🟠 Google Images: no puede indexar ni categorizar la imagen (pierdes tráfico de búsqueda de imágenes)
- 🟠 SEO general: Google penaliza sitios con imágenes sin alt en auditorías de calidad

**Fix recomendado:**

```erb
<%# home.html.erb %>
<%= image_tag("perfil2.jpg",
      alt: "Rene Garcia — Software, escritura y paternidad neurodivergente",
      class: "size-72 rounded-xl object-cover rotate-[-3deg]") %>

<%# about.html.erb %>
<%= image_tag("perfil2.jpg",
      alt: "Rene Garcia — Backend developer, escritor y padre",
      class: "size-72 rounded-3xl rotate-3") %>

<%# _nav.html.erb %>
<%= image_tag("perfil2.jpg",
      alt: "Rene Garcia",
      class: "size-10 object-cover rounded-full") %>
```

**Esfuerzo:** 10 min (4 cambios de 1 línea cada uno)
**Prioridad:** 🟠 Media

---

## 🟡 Issues Medios (mejoras de calidad)

### Issue #7 — Página 404 genérica de Rails

**Archivo:** `public/404.html` (estático de Rails 8, no generado por la app)

**Producción actual** (`https://resagar.com/404.html`):
- HTML estático con fondo blanco, fuente sans-serif genérica
- Mensaje: "The page you were looking for doesn't exist (404 Not found)"
- No usa el theme Dracula, no tiene nav, no tiene link de vuelta al home
- Mala UX para usuarios que llegan por links rotos externos

**Impacto SEO:** Google ve una página 404 sin estructura. Pérdida de oportunidad para retener al usuario con un link "Volver al home" o posts relacionados.

**Fix recomendado:** crear `public/404.html` custom con el theme del sitio. Como Parklife copia `public/*` a `build/`, el archivo custom se incluirá automáticamente.

**Esfuerzo:** 1 hora
**Prioridad:** 🟡 Baja

---

### Issue #8 — Falta `og:image:width` y `og:image:height`

**Archivo:** `app/views/layouts/_base.html.erb`

**Producción actual:** los OG tags tienen `og:image` pero no especifican dimensiones.

**Impacto SEO:** Facebook/LinkedIn pre-cargan la imagen sin reservar espacio, causando "jumps" de layout al cargar. Pequeño impacto en calidad de preview.

**Fix recomendado:**

```erb
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
```

**Esfuerzo:** 5 min
**Prioridad:** 🟡 Baja

---

### Issue #9 — Title del posts index confuso

**Archivo:** `app/views/posts/index.html.erb` (líneas 1-11)

**Código actual:**
```erb
<% provide :title, "Rene Garcia — Software, escritura y paternidad neurodivergente" %>
<% provide :description, "..." %>
<% provide :og_image, "..." %>
<% provide :og_type, "website" %>

<% if @page == 1
  provide :whole_title, "Resagar : A lost and found"
else
  provide :title, "Resagar : A lost and found"
end %>
```

**Problema:** se hace `provide :title` dos veces (líneas 1 y 10). Funciona (la segunda gana) pero es código confuso. La lógica del override debería estar antes del provide inicial, no después.

**Fix recomendado:** invertir el orden para que sea claro:

```erb
<% if @page == 1
  provide :whole_title, "Resagar : A lost and found"
else
  provide :title, "Resagar : A lost and found"
end %>

<% provide :title, "Rene Garcia — Software, escritura y paternidad neurodivergente" %>
<% provide :description, "..." %>
<% provide :og_image, "..." %>
<% provide :og_type, "website" %>
```

**Esfuerzo:** 5 min
**Prioridad:** 🟡 Baja (no afecta SEO, solo claridad de código)

---

## 🟢 Issues Bajos (nice-to-have)

### Issue #10 — Schema.org `CollectionPage` en listados

**Archivos:** `app/views/posts/index.html.erb` y `app/views/pages/tags.html.erb`

**Producción actual:** las páginas de listado (`/posts`, `/tags`) solo heredan el schema `WebSite` del layout base.

**Impacto SEO:** Google pierde oportunidad de mostrar "X items in this collection" en los rich snippets. Útil cuando el blog tenga más posts.

**Fix recomendado:** agregar un bloque JSON-LD de tipo `CollectionPage` con `ItemList` de los items. Implementar después de tener varios posts.

**Esfuerzo:** 1 hora
**Prioridad:** 🟢 Baja (diferible hasta tener más contenido)

---

### Issue #11 — Schema.org `BreadcrumbList` en posts

**Archivos:** `app/views/posts/show.html.erb`

**Producción actual:** los posts individuales no tienen breadcrumb schema.

**Impacto SEO:** Google puede mostrar el breadcrumb en los resultados de búsqueda. Útil cuando el blog tenga varios niveles de navegación.

**Fix recomendado:** agregar JSON-LD de tipo `BreadcrumbList` en posts individuales. Implementar después de tener 5+ posts.

**Esfuerzo:** 1-2 horas
**Prioridad:** 🟢 Baja (diferible)

---

### Issue #12 — OG images específicas por página

**Archivos:** `app/views/pages/home.html.erb`, `app/views/pages/now.html.erb`, `app/views/pages/about.html.erb`

**Producción actual:** todas las páginas (excepto posts individuales) usan la misma `og_image` (`https://mugshotbot.com/m/5YypF97U`).

**Impacto SEO:** preview en redes sociales menos personalizado. Mejora opcional de branding.

**Fix recomendado:** generar imágenes específicas 1200x630 para `/now` y `/about` (ej: con Canva o Figma), y actualizar las URLs en los `provide :og_image`.

**Esfuerzo:** 2-3 horas (incluye diseño)
**Prioridad:** 🟢 Baja (nice-to-have de branding)

---

## 📊 Resumen por severidad

| # | Issue | Archivos | Esfuerzo | Impacto SEO | Prioridad |
|---|---|---|---|---|---|
| 1 | Sitemap incompleto | `robots_controller.rb` | 15 min | 🔴 Alto | 🔴 Alta |
| 2 | Link de feed roto | `_base.html.erb` | 5 min | 🔴 Alto | ✅ Resuelto |
| 3 | `/tags` vacía | `pages/tags.html.erb` | 30 min | 🔴 Alto | ⚠️ Pospuesto (tags deshabilitados) |
| 4 | og:type en posts | `posts/show.html.erb` | 2 min | 🟠 Medio | ✅ Resuelto |
| 5 | Tag pages metadata | `posts/tag.html.erb` | 10 min | 🟠 Medio | ⚠️ Pospuesto (tags deshabilitados) |
| 6 | Alt text imágenes | 3 archivos | 10 min | 🟠 Medio | ✅ Resuelto |
| 7 | 404 page genérica | `public/404.html` | 1 hora | 🟡 Bajo | 🟡 Baja |
| 8 | og:image dimensions | `_base.html.erb` | 5 min | 🟡 Bajo | ✅ Resuelto |
| 9 | Title confuso /posts | `posts/index.html.erb` | 5 min | ⚪ Nulo | ✅ Resuelto |
| 10 | CollectionPage | 2 archivos | 1 hora | 🟢 Bajo | 🟢 Diferible |
| 11 | BreadcrumbList | `posts/show.html.erb` | 1-2 horas | 🟢 Bajo | 🟢 Diferible |
| 12 | OG images específicas | 3 archivos | 2-3 horas | 🟢 Bajo | 🟢 Diferible |

---

## 🎯 Plan de acción por sesiones

### Sesión 1 — Quick wins (30 min total)

| Issue | Cambio | Esfuerzo | Estado |
|---|---|---|---|
| #2 | Fix del link de feed en `_base.html.erb` | 5 min | ✅ Resuelto |
| #4 | og:type `"article"` en `posts/show.html.erb` | 2 min | ✅ Resuelto |
| #6 | Alt text en las 4 imágenes | 10 min | ✅ Resuelto |
| #5 | ~~Title/description dinámicos en `posts/tag.html.erb`~~ | ~~10 min~~ | ⚠️ Pospuesto (tags deshabilitados) |

**Resultado esperado:** score 9.4 → 9.6 (logrado, sin contar #5)

### Sesión 2 — Contenido (1 hora)

| Issue | Cambio | Esfuerzo | Estado |
|---|---|---|---|
| #3 | ~~Listado de tags en `pages/tags.html.erb`~~ | ~~30 min~~ | ⚠️ Pospuesto (tags deshabilitados) |

**Resultado esperado:** score se mantiene en 9.6 (sin tareas activas hasta reactivar tags)

### Sesión 3 — Polish (1-2 horas)

| Issue | Cambio | Esfuerzo | Estado |
|---|---|---|---|
| #7 | 404 page custom con theme del sitio | 1 hora | ✅ Resuelto (verificar en prod) |
| #8 | og:image:width y og:image:height | 5 min | ✅ Resuelto |
| #9 | Limpiar provide duplicado en /posts | 5 min | ✅ Resuelto |

**Resultado esperado:** score 9.6 → 9.7 (3/3 issues resueltos; score final requiere verificación en prod)

### Largo plazo (cuando el blog crezca)

- Issue #10: CollectionPage (cuando haya 5+ posts)
- Issue #11: BreadcrumbList (cuando haya varios niveles de navegación)
- Issue #12: OG images específicas (cuando se justifique el esfuerzo de diseño)
- Issues #3 y #5: Reactivar junto con el sistema de tags completo

---

## 📈 Proyección de score

| Estado | Score | Mejora |
|---|---|---|
| Actual (post-commits de hoy) | 9.4/10 | — |
| Después de Sesión 1 (3/4 issues — #5 pospuesto) | 9.6/10 | +0.2 |
| Después de Sesión 2 (0/2 issues — #1 descartado, #3 pospuesto) | 9.6/10 | +0.0 |
| Después de Sesión 3 (3/3 issues — #7 resuelto) | 9.7/10 | +0.1 |
| Después de largo plazo (incluyendo reactivación de tags) | 9.9/10 | +0.2 |

---

## 📎 Referencias cruzadas

- **Plan original de SEO:** `MEJORAS-ENCONTRABILIDAD.md` (creado 2026-06-19, contiene 10 mejoras; las primeras 5 ya fueron aplicadas en commits posteriores)
- **Análisis de deploy:** `ANALISIS-DEPLOY.md` (cubre problemas de infraestructura, no SEO)
- **Historial de cambios SEO:** commits `a0457b1`, `c1bf931`, `9c72821`, `8b53205`, `3f77c44`, `88894e6`, `04c11c2`, `929a2f4`, `97800ea`, `36eb75d` (todos de 2026-06-18 a 2026-06-20)

---

## ✅ Verificación post-implementación

Después de aplicar cada sesión, verificar:

1. **Build local:** `rm -rf build && ./bin/static-build` debe completar sin warnings
2. **Dev server:** `bin/dev` y navegación manual a cada página modificada
3. **Production check (post-deploy):** ejecutar el mismo test de las 10 requests contra `https://resagar.com` para confirmar que los cambios se ven
4. **Google Search Console:** después de 1-2 semanas, revisar "Cobertura" para confirmar que las páginas del sitemap se indexan correctamente
5. **Google Search Console:** revisar "Mejoras" para confirmar que desaparecen los warnings de "alt text faltante" en imágenes
