# frozen_string_literal: true

module ApplicationHelper
  def title
    string = if content_for?(:whole_title)
               content_for(:whole_title)
    elsif content_for?(:title)
      "#{content_for(:title)} | Resagar"
    else
      "Resagar"
    end

    ActiveSupport::Inflector.transliterate(string)
  end

  # Devuelve la URL canonica de la pagina actual.
  # Casos especiales:
  #   - Posts paginados (pagina > 1): apunta a /posts
  #   - Post individual: usa post_path para evitar el .html
  #   - Resto: self-referential con el path actual
  def canonical_url
    base = Rails.application.config.x.site_url

    if @page.is_a?(Integer) && @page > 1
      return "#{base}/posts"
    end

    if controller_name == "posts" && action_name == "show" && @post
      return "#{base}#{post_path(@post)}"
    end

    "#{base}#{request.path}"
  end
end
