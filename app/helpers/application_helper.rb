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
end
