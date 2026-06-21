Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
  get "about", to: "pages#about", as: :about
  get "now", to: "pages#now", as: :now

  get "/posts/:page", to: "posts#index", constraints: { page: /\d+/ }, as: :posts
  get "/posts", to: "posts#index", as: :posts_list
  get "/:year/:month/:slug", to: "posts#show", as: :slugged_post, constraints: { year: /\d*/, month: /\d{2}/, slug: /.*/, format: /html/ }
  direct :post do |post, options|
    route_for :slugged_post, { year: post.published_at.strftime("%Y"), month: post.published_at.strftime("%m"), slug: post.slug }.merge(options)
  end

  # === Tag routes (deshabilitadas temporalmente) ===
  # Para reactivar el sistema de tags completo, descomentar las 3 líneas de abajo
  # y volver a cambiar `tag` por `link_to tag, tag_path(tag.parameterize)` en
  # app/views/posts/_post.html.erb línea 13
  # get "tags", to: "pages#tags"
  # get "posts/tags/:tag_slug", to: "posts#tag", as: :_tag
  # direct :tag do |tag, options|
  #   route_for :_tag, { tag_slug: tag.parameterize }.merge(options)
  # end

  get "feed", to: "robots#feed", as: :feed, format: true
  get "robots", to: "robots#robots", as: :robots, format: true
  get "sitemap", to: "robots#sitemap", as: :sitemap, format: true
  get "/404.html", to: "errors#not_found"
end
