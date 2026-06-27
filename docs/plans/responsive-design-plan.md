# Plan: Hacer el Blog Responsive (Mobile-First)

**Generated**: 2026-06-27
**Stack**: Rails 8 + Tailwind v4 + DaisyUI (tema dracula) + `@tailwindcss/typography` + Stimulus
**Complejidad estimada**: Media
**Restricción crítica**: Preservar 100% la apariencia actual en `lg+` (mismo blog, no uno diferente)

## Overview

Adaptar la UI existente a móvil/tablet **sin cambiar el diseño en desktop**. Estrategia mobile-first con breakpoints estándar de Tailwind v4 (`sm` 40rem, `md` 48rem, `lg` 64rem), preservando el layout actual en `lg+` y aplicando reflow progresivo en pantallas menores.

### Principios rectores

1. **Mobile-first**: estilos base para móvil, escalado con `sm:` / `md:` / `lg:`.
2. **Identidad visual intocable en `lg+`**: padding `px-28`, tipografía, colores dracula, todo igual.
3. **Reflow, no rewrite**: sólo cambiamos clases, no componentes.
4. **CSS-only cuando sea posible**: `<details>` para menú hamburguesa, container queries donde aporten.
5. **Tipografía legible para blog**: 16-18px base, 65-75ch de ancho máximo de lectura.
6. **Tap targets ≥ 44px** en elementos interactivos móviles.
7. **Sin clases inválidas**: corregir bugs pre-existentes (Bootstrap en `posts/index`, `space-x-21.5` en `posts/show`).

## Sistema de Diseño (Convenciones)

Todos los cambios siguen estas reglas para mantener coherencia:

| Elemento | Móvil (base) | sm (≥640px) | md (≥768px) | lg+ (≥1024px) |
|---|---|---|---|---|
| Padding horizontal contenedor | `px-4` | `sm:px-6` | — | `lg:px-28` |
| Padding top main | `pt-6` | `sm:pt-10` | `md:pt-20` | `lg:pt-32` |
| Padding bottom main | `pb-8` | `sm:pb-12` | `md:pb-20` | `lg:pb-28` |
| Tipografía base cuerpo | `text-base` | — | — | `lg:text-lg` |
| Tipografía h1 hero | `text-3xl` | `sm:text-4xl` | — | `lg:text-5xl` |
| Ancho máximo lectura | `max-w-prose` | — | — | `max-w-3xl` |
| Imagen hero (home) | `size-48` | `sm:size-56` | `md:size-64` | `lg:size-72` |
| Imagen about | `size-40` | `sm:size-52` | `md:size-64` | `lg:size-72` |
| Nav inline | oculto (hamburguesa) | visible (inline) | visible | visible |
| Botón "atrás" post | sticky top | inline | inline | inline |

**Clases prohibidas durante el refactor** (cleanup de bugs):
- `d-flex`, `justify-content-between`, `mb-5`, `btn-outline-primary` (Bootstrap — no funcionan en DaisyUI)
- `space-x-21.5` (valor inválido, debe ser `space-x-[5.375rem]` o `gap-21.5` que tampoco existe → usar `gap-8 lg:gap-[5.375rem]`)

## Sprint 1: Fundación del Layout Shell

**Goal**: El contenedor principal y el body responden correctamente a todos los viewports, preservando la apariencia actual en `lg+`.

**Demo/Validación**:
- Abrir `/` en viewport 375px → el contenido respeta los bordes, sin scroll horizontal.
- Abrir `/` en viewport 1440px → layout idéntico al actual (paddings `px-28`, `pt-32`, `pb-28`).
- Probar 640px, 768px, 1024px como puntos intermedios.

### Task 1.1: Refactorizar `app/views/layouts/application.html.erb`

- **Location**: `app/views/layouts/application.html.erb`
- **Description**: Cambiar padding y dimensiones del shell principal a responsive
- **Cambios específicos**:
  - `<header class="navbar w-full px-28">` → `class="navbar w-full px-4 sm:px-6 lg:px-28"`
  - `<main role="main" class="pt-32 pb-28 px-28">` → `class="pt-6 sm:pt-10 md:pt-20 lg:pt-32 pb-8 sm:pb-12 md:pb-20 lg:pb-28 px-4 sm:px-6 lg:px-28"`
- **Acceptance criteria**:
  - En 375px: contenido no se sale del viewport, padding lateral ~16px
  - En 1024px+: idéntico al actual (px-28, pt-32, pb-28)
- **Validation**: `bin/rails server` + DevTools responsive mode
- **Dependencies**: ninguna (es la base)

### Task 1.2: Prevenir scroll horizontal global

- **Location**: `app/views/layouts/_base.html.erb` línea 62 (`<body class="bg-base-200">`)
- **Description**: Añadir `overflow-x-hidden` al body para evitar desbordes accidentales
- **Cambio**: `<body class="bg-base-200">` → `<body class="bg-base-200 overflow-x-hidden">`
- **Acceptance criteria**: Ningún elemento puede generar scroll horizontal en ningún viewport
- **Validation**: DevTools → "Show scroll overflow"
- **Dependencies**: 1.1 (puede ir en paralelo)

## Sprint 2: Navegación Responsive

**Goal**: El nav funciona perfectamente en móvil (menú hamburguesa) y mantiene el diseño actual en `lg+`.

**Demo/Validación**:
- En 375px: aparece un botón hamburguesa, el nav inline está oculto, tocarlo abre el menú
- En 640px+: el nav inline aparece, la hamburguesa desaparece
- El nav sigue mostrando foto perfil, links, RSS

### Task 2.1: Implementar menú hamburguesa con `<details>` en `_nav.html.erb`

- **Location**: `app/views/layouts/_nav.html.erb`
- **Description**: Convertir el nav en responsive con hamburguesa CSS-only
- **Estructura propuesta** (preservando identidad visual):
  ```html
  <nav class="w-full flex flex-row items-center justify-between gap-2">
    <!-- Foto perfil (visible en todas las pantallas) -->
    <%= link_to root_path do %>
      <%= image_tag("perfil2.jpg", alt: "...", class: "size-9 sm:size-10 object-cover rounded-full") %>
    <% end %>

    <!-- En lg+: nav inline horizontal (clases hidden lg:flex) -->
    <ul class="hidden lg:flex flex-row justify-center items-center border border-base-300 rounded-full shadow-md px-3 font-sans font-medium text-sm">
      <!-- los 4 <li> actuales -->
    </ul>

    <!-- En <lg: hamburguesa con <details> -->
    <details class="lg:hidden relative">
      <summary class="btn btn-outline border-base-300 shadow-md rounded-full p-2 cursor-pointer list-none">
        <svg ...> <!-- icono hamburguesa --></svg>
      </summary>
      <ul class="absolute right-0 top-full mt-2 menu bg-base-100 border border-base-300 rounded-box shadow-lg z-50 w-48 p-2 font-sans">
        <!-- los 4 <li> -->
      </ul>
    </details>

    <!-- Botón RSS (siempre visible) -->
    <div class="tooltip tooltip-right" data-tip="Rss">...</div>
  </nav>
  ```
- **Acceptance criteria**:
  - En 375px: sólo se ve foto + hamburguesa + RSS, tocar hamburguesa abre dropdown con los 4 links
  - En 1024px+: idéntico al actual (foto + 4 links inline + RSS)
  - Los items del menú móvil tienen tap target ≥ 44px
  - El menú se cierra al tocar un link (comportamiento nativo de `<a>` en `<details>`)
- **Validation**: Probar en Chrome DevTools modo responsive + dispositivo real si es posible
- **Dependencies**: 1.1 (necesita el shell responsivo)

### Task 2.2: Ajustar el header de la nav a responsive

- **Location**: `app/views/layouts/_nav.html.erb`
- **Description**: La altura y centrado del nav se mantiene en todas las pantallas
- **Cambios**: aplicar `items-center` al nav y `min-h-10` para evitar colapsos
- **Acceptance criteria**: El nav se ve centrado verticalmente en todas las pantallas
- **Dependencies**: 2.1

## Sprint 3: Footer Responsive

**Goal**: El footer se apila verticalmente en móvil y mantiene el layout horizontal en `lg+`.

**Demo/Validación**:
- En 375px: links y copyright apilados verticalmente, padding reducido
- En 1024px+: idéntico al actual

### Task 3.1: Refactorizar `_footer.html.erb`

- **Location**: `app/views/layouts/_footer.html.erb`
- **Description**: Convertir el footer a responsive
- **Cambios**:
  - `footer h-28` → `footer min-h-20 lg:min-h-28`
  - `sm:footer-horizontal justify-between content-center ... px-28` → `flex-col gap-2 sm:flex-row sm:justify-between sm:items-center px-4 sm:px-6 lg:px-28 py-4 lg:py-0`
  - `<aside>`: añadir `order-first sm:order-last` o reorganizar para que el copyright quede abajo en móvil
- **Acceptance criteria**:
  - En 375px: nav arriba, copyright abajo
  - En 1024px+: idéntico al actual
  - Sin desbordes horizontales
- **Validation**: DevTools responsive
- **Dependencies**: 1.1

## Sprint 4: Páginas Principales (Home y About)

**Goal**: Las páginas más visitadas se ven correctamente en móvil.

**Demo/Validación**: Probar `/` y `/about` en 375px, 768px, 1024px, 1440px

### Task 4.1: Refactorizar `home.html.erb` header

- **Location**: `app/views/pages/home.html.erb` líneas 8-84
- **Description**: Convertir el header (imagen + texto) en stack vertical en móvil
- **Cambios**:
  - `class="flex flex-row justify-around"` → `class="flex flex-col md:flex-row md:justify-around items-center md:items-start gap-6 md:gap-10"`
  - Imagen: `class="size-72 rounded-xl object-cover rotate-[-3deg]"` → `class="size-48 sm:size-56 md:size-64 lg:size-72 rounded-xl object-cover rotate-[-3deg] mx-auto md:mx-0"`
  - Sección: `class="flex flex-col max-w-md space-y-4"` → `class="flex flex-col max-w-md space-y-4 text-center md:text-left"`
- **Acceptance criteria**:
  - En 375px: imagen arriba (centrada), texto debajo
  - En 768px+: layout horizontal idéntico al actual
  - La rotación `rotate-[-3deg]` se preserva
- **Dependencies**: 1.1

### Task 4.2: Refactorizar `home.html.erb` secciones inferiores

- **Location**: `app/views/pages/home.html.erb` líneas 85-145
- **Description**: Ajustar paddings de las secciones "¿Que estoy haciendo ahora?" y "Últimos artículos"
- **Cambios**:
  - `pt-32` → `pt-12 sm:pt-16 md:pt-24 lg:pt-32`
  - `pt-16` → `pt-8 sm:pt-10 md:pt-12 lg:pt-16`
  - Los iconos sociales: añadir `flex-wrap` y `justify-center md:justify-start` para que no se desborden
- **Acceptance criteria**:
  - En 375px: secciones con padding vertical reducido
  - En 1024px+: idéntico al actual
- **Dependencies**: 1.1

### Task 4.3: Refactorizar `about.html.erb` layout grid

- **Location**: `app/views/pages/about.html.erb` líneas 8-91
- **Description**: Convertir el grid de 2 columnas en stack vertical en móvil
- **Cambios**:
  - `class="grid grid-cols-[1fr_auto] gap-12"` → `class="grid grid-cols-1 lg:grid-cols-[1fr_auto] gap-8 lg:gap-12"`
  - Sidebar `class="px-10 flex flex-col space-y-7"` → `class="px-0 sm:px-6 lg:px-10 flex flex-col space-y-6 lg:space-y-7 items-center lg:items-start text-center lg:text-left"`
  - Imagen: `class="size-72 rounded-3xl rotate-3"` → `class="size-40 sm:size-52 md:size-64 lg:size-72 rounded-3xl rotate-3"`
  - `space-y-12` (dentro del sidebar) → `space-y-6 lg:space-y-12`
- **Acceptance criteria**:
  - En 375px: imagen centrada arriba, links centrados debajo, artículo abajo
  - En 1024px+: grid 2 columnas idéntico al actual
  - La rotación `rotate-3` se preserva
- **Dependencies**: 1.1

## Sprint 5: Posts (Index, Show, Cards)

**Goal**: Las páginas de artículos (el corazón del blog) son perfectamente legibles en móvil. Se corrige el bug pre-existente de clases Bootstrap.

**Demo/Validación**:
- Abrir `/posts` en 375px → lista de posts legible, paginación funciona, sin botones rotos
- Abrir un post individual en 375px → botón "atrás" accesible, artículo legible
- Abrir `/posts/tag/foo` → ya tiene estilos básicos (fix de bug)

### Task 5.1: Refactorizar `posts/index.html.erb` (incluye fix de bug Bootstrap)

- **Location**: `app/views/posts/index.html.erb` líneas 17-34
- **Description**: Hacer la lista de posts responsive + reemplazar clases Bootstrap inválidas
- **Cambios**:
  - Header: `pl-6 mb-15 max-w-2xl flex flex-col space-y-5` → `px-4 sm:px-6 lg:px-0 mb-8 sm:mb-10 lg:mb-15 max-w-2xl flex flex-col space-y-4 sm:space-y-5`
  - h1: `text-4xl font-bold` → `text-3xl sm:text-4xl font-bold`
  - Lista: `flex flex-col max-w-2xl space-y-5` → `flex flex-col max-w-2xl space-y-4 sm:space-y-5 px-4 sm:px-6 lg:px-0`
  - **Paginación (FIX DE BUG)**: reemplazar:
    ```html
    <div class="d-flex justify-content-between mb-5">
      <a class="btn btn-outline-primary">...</a>
    ```
    por:
    ```html
    <div class="flex flex-col sm:flex-row justify-between gap-3 mb-8 sm:mb-12 px-4 sm:px-6 lg:px-0">
      <%= link_to "Articulos más recientes", ..., class: "btn btn-outline border-base-300" %>
      <%= link_to "Articulos anteriores", ..., class: "btn btn-outline border-base-300" %>
    </div>
    ```
- **Acceptance criteria**:
  - En 375px: h1 legible, padding lateral cómodo, paginación apilada verticalmente con botones DaisyUI
  - En 1024px+: idéntico al actual
  - Los botones de paginación **dejan de estar rotos** (usan `btn-outline` de DaisyUI en lugar de `btn-outline-primary` inexistente)
- **Dependencies**: 1.1

### Task 5.2: Refactorizar `posts/show.html.erb` (botón "atrás")

- **Location**: `app/views/posts/show.html.erb` líneas 7-23
- **Description**: Convertir el botón "atrás" en responsive
- **Cambios**:
  - `class="grid grid-cols-[auto_1fr] items-baseline space-x-21.5"` → `class="grid grid-cols-1 md:grid-cols-[auto_1fr] md:items-baseline gap-4 md:gap-8 lg:gap-[5.375rem]"`
  - Botón: añadir `mb-2 md:mb-0` y asegurar tap target ≥ 44px (`btn-lg` o `p-3`)
  - En móvil, considerar `sticky top-0 z-10 bg-base-100 py-2` para que el botón quede siempre visible al hacer scroll
- **Acceptance criteria**:
  - En 375px: botón "atrás" arriba, artículo debajo, el botón queda accesible
  - En 1024px+: idéntico al actual
  - El bug de `space-x-21.5` se corrige
- **Dependencies**: 1.1

### Task 5.3: Refactorizar `_post_card.html.erb`

- **Location**: `app/views/posts/_post_card.html.erb`
- **Description**: Ajustar padding de la card
- **Cambios**: `class="p-6 flex flex-col space-y-3"` → `class="p-4 sm:p-6 flex flex-col space-y-2 sm:space-y-3"`
- **Acceptance criteria**: Padding cómodo en móvil, idéntico en desktop
- **Dependencies**: 1.1 (puede ir en paralelo)

### Task 5.4: Refactorizar `_post.html.erb`

- **Location**: `app/views/posts/_post.html.erb`
- **Description**: Mejorar wrapping del header del post
- **Cambios**: El `<p>` con fecha y tags puede romperse en líneas muy estrechas; envolver en clases que permitan wrap natural
- **Acceptance criteria**: El header del post se ve limpio en móvil sin overflow
- **Dependencies**: ninguna

### Task 5.5: Estilizar `posts/tag.html.erb` (fix de bug existente)

- **Location**: `app/views/posts/tag.html.erb`
- **Description**: Esta página no tiene ninguna clase CSS. Aplicar estilos base + responsive
- **Cambios**: envolver el contenido en `<article class="prose max-w-3xl mx-auto py-8 px-4 sm:px-6">` y aplicar tamaños de heading responsive (`text-3xl md:text-4xl`, `text-2xl md:text-3xl`, etc.)
- **Acceptance criteria**:
  - En 375px: página legible, no aspecto de "HTML sin estilo"
  - En 1024px+: equivalente visual al resto del blog
- **Dependencies**: ninguna (es independiente)

## Sprint 6: Páginas Auxiliares (Now, 404)

**Goal**: Las páginas estáticas secundarias también son responsive.

### Task 6.1: Refactorizar `now.html.erb`

- **Location**: `app/views/pages/now.html.erb`
- **Description**: Reducir tipografía del h1 en móvil
- **Cambios**:
  - h1: `text-5xl font-sans font-bold` → `text-3xl sm:text-4xl md:text-5xl font-sans font-bold`
  - Añadir `px-4 sm:px-6` al contenedor article para padding lateral
- **Acceptance criteria**: H1 legible en móvil, sin overflow horizontal
- **Dependencies**: 1.1

### Task 6.2: Refactorizar `not_found.html.erb`

- **Location**: `app/views/errors/not_found.html.erb`
- **Description**: Reducir h1 y apilar botones en móvil
- **Cambios**:
  - h1: `text-7xl` → `text-6xl md:text-7xl`
  - Botones container: `flex flex-row` → `flex flex-col sm:flex-row`
  - Botones: añadir `w-full sm:w-auto` para que ocupen todo el ancho en móvil
  - Añadir `px-4` a la sección
- **Acceptance criteria**:
  - En 375px: 404 legible, botones apilados con tap target amplio
  - En 1024px+: idéntico al actual
- **Dependencies**: 1.1

## Sprint 7: Validación y Pulido

**Goal**: Verificar que todo funciona en dispositivos reales y pulir detalles.

### Task 7.1: Build de assets y verificar compilación

- **Location**: `app/assets/builds/`
- **Description**: Compilar Tailwind para asegurar que las nuevas clases se incluyen en el bundle
- **Comando**: `bin/rails tailwindcss:build` o `bin/rails assets:precompile`
- **Acceptance criteria**: El build pasa sin errores, las clases responsive están en el CSS final
- **Dependencies**: todas las anteriores

### Task 7.2: Verificación visual en múltiples viewports

- **Location**: N/A (validación manual)
- **Description**: Probar cada página en 320px, 375px, 414px, 640px, 768px, 1024px, 1280px, 1440px
- **Checklist**:
  - Sin scroll horizontal en ningún viewport
  - Imágenes no se desbordan
  - Texto siempre legible (no < 14px)
  - Tap targets ≥ 44px en móvil
  - Menú hamburguesa se abre/cierra correctamente
  - Paginación funciona
  - Botón "atrás" accesible en posts
- **Dependencies**: 7.1

### Task 7.3: Lighthouse mobile audit

- **Location**: N/A
- **Description**: Ejecutar Lighthouse en modo mobile para verificar performance y accesibilidad
- **Métricas objetivo**:
  - Performance ≥ 90
  - Accessibility ≥ 95
  - Best Practices ≥ 95
- **Dependencies**: 7.1

### Task 7.4: Optimizaciones de performance móvil

- **Location**: varios archivos
- **Description**: Añadir `loading="lazy"` y `decoding="async"` a imágenes (excepto above-the-fold)
- **Acceptance criteria**: Imágenes no bloquean render inicial
- **Dependencies**: 7.2

## Estrategia de Testing

| Tipo | Herramienta | Qué verifica |
|---|---|---|
| Visual responsive | Chrome DevTools (modo responsive) | Layout en 320, 375, 414, 640, 768, 1024, 1280, 1440px |
| Real device | BrowserStack / dispositivo físico | Tap targets, scroll, menús |
| Accesibilidad | Lighthouse + axe DevTools | Contraste, tap targets, ARIA, semántica |
| Performance | Lighthouse mobile | FCP, LCP, CLS |
| Compilación | `bin/rails tailwindcss:build` | Clases responsive incluidas |
| Regresión visual | (opcional) Percy/Chromatic | Si se añade CI |

## Riesgos y Gotchas

| # | Riesgo | Mitigación |
|---|---|---|
| 1 | Las clases de DaisyUI/Tailwind no se compilan en el build de producción si no se usan en el código fuente escaneado | Verificar en `app/assets/builds/tailwind.css` que las nuevas clases aparecen; el `Gemfile` debe incluir `tailwindcss-rails` correctamente |
| 2 | El menú `<details>` no se cierra al hacer click fuera | Comportamiento aceptado (trade-off por zero-JS); alternativa: Stimulus controller |
| 3 | El `prose` de Typography tiene sus propios breakpoints que pueden chocar con los del blog | No modificar `.prose`; ajustar contenedores externos |
| 4 | El tipografía de headings (Raleway) puede hacer que `text-5xl` sea muy ancho en móvil | Usar `text-3xl sm:text-4xl md:text-5xl` (ramp) en h1 de hero/now |
| 5 | El fix del bug Bootstrap en `posts/index` puede cambiar la apariencia de los botones (DaisyUI `btn-outline` vs Bootstrap `btn-outline-primary`) | Es intencional; alinear con el resto del blog |
| 6 | El autor ya tenía identificados ciertos problemas en la auditoría SEO; verificar que la responsividad no rompa los structured data (JSON-LD) | Los scripts JSON-LD no tienen clases; no se tocan |
| 7 | Posibles conflictos con la regla `space-x-21.5` si la usa otro archivo | Sólo aparece en `posts/show.html.erb` (verificado); cambio seguro |
| 8 | `size-72` (288px) puede generar imágenes borrosas en mobile si el src no es retina | Considerar añadir `srcset` en el futuro (fuera del scope actual) |

## Plan de Rollback

Si después de implementar algo falla o el diseño no convence:

1. **Por sprint**: cada sprint es independiente → `git revert <commit>` del sprint
2. **Por archivo**: cada cambio es a nivel de clases en un único `.erb` → `git checkout HEAD~1 -- <file>`
3. **Total**: `git reset --hard HEAD~N` donde N = número de commits

Recomendación: hacer **un commit por tarea** (25 tareas ≈ 25 commits) para granularidad máxima.

## Resumen de Archivos Afectados

| Archivo | Cambios | Sprint |
|---|---|---|
| `app/views/layouts/application.html.erb` | padding responsive | 1 |
| `app/views/layouts/_base.html.erb` | `overflow-x-hidden` | 1 |
| `app/views/layouts/_nav.html.erb` | menú hamburguesa `<details>` | 2 |
| `app/views/layouts/_footer.html.erb` | flex-col responsive | 3 |
| `app/views/pages/home.html.erb` | header + secciones | 4 |
| `app/views/pages/about.html.erb` | grid responsive | 4 |
| `app/views/pages/now.html.erb` | h1 responsive | 6 |
| `app/views/posts/index.html.erb` | responsive + fix Bootstrap | 5 |
| `app/views/posts/show.html.erb` | botón "atrás" responsive | 5 |
| `app/views/posts/_post.html.erb` | header del post | 5 |
| `app/views/posts/_post_card.html.erb` | padding card | 5 |
| `app/views/posts/tag.html.erb` | estilos base (fix bug) | 5 |
| `app/views/errors/not_found.html.erb` | h1 + botones | 6 |

**Total**: 13 archivos modificados, 0 archivos nuevos, 0 dependencias añadidas.

## Decisiones técnicas asumidas

1. Menú hamburguesa con `<details>` (cero JS nuevo) en lugar de Stimulus.
2. Mobile-first con breakpoints estándar Tailwind v4.
3. Breakpoint de cambio de diseño: `lg` (1024px) — en ≥lg es idéntico al actual.
4. Sin dependencias nuevas (sin librerías JS adicionales).
5. Un commit por tarea (25 commits estimados).
6. `.prose` del plugin Typography NO se toca (ya es responsive).
7. Fix del bug de Bootstrap en `posts/index` incluido.
8. Fix del bug de estilo en `posts/tag.html.erb` incluido.
