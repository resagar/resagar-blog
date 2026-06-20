class RobotsController < ApplicationController
  layout false

  def feed
    @posts = Post.all.reverse.take(10)
  end

  def robots
  end

  def sitemap
    @entries = []

    @entries << SitemapEntry.new(loc: root_url)
    @entries << SitemapEntry.new(loc: about_url)
    @entries << SitemapEntry.new(loc: now_url)
    @entries << SitemapEntry.new(loc: tags_url)

    @entries += Post.all.map do |post|
      SitemapEntry.new(loc: post_url(post))
    end
  end

  class SitemapEntry
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :loc, :string
    attribute :lastmod, :datetime, default: -> { Time.current }
    attribute :changefreq, :string, default: "daily"
    attribute :priority, :float, default: 1.0
  end
end
