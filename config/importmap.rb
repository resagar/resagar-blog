# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@tailwindcss/typography", to: "@tailwindcss--typography.js" # @0.5.19
pin "cssesc" # @3.0.0
pin "postcss-selector-parser" # @6.0.10
pin "tailwindcss/colors", to: "tailwindcss--colors.js" # @4.1.14
pin "tailwindcss/plugin", to: "tailwindcss--plugin.js" # @4.1.14
pin "util-deprecate" # @1.0.2
