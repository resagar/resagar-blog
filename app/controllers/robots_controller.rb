class RobotsController < ApplicationController
  layout false

  def feed
    @posts = Post.all.reverse.take(10)
  end

  def robots
  end

  def sitemap
    @entries = []

    @entries << SitemapEntry.new(loc: root_url, priority: 1.0, changefreq: "daily")
    @entries << SitemapEntry.new(loc: posts_list_url, priority: 0.9, changefreq: "daily")
    @entries << SitemapEntry.new(loc: about_url, priority: 0.5, changefreq: "monthly")
    @entries << SitemapEntry.new(loc: now_url, priority: 0.6, changefreq: "weekly")

    @entries += Post.all.map do |post|
      SitemapEntry.new(
        loc: post_url(post),
        lastmod: post.published_at,
        priority: 0.8,
        changefreq: "monthly",
        image: post.og_image.presence
      )
    end
  end

  class SitemapEntry
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :loc, :string
    attribute :lastmod, :datetime, default: -> { Time.current }
    attribute :changefreq, :string, default: "daily"
    attribute :priority, :float, default: 1.0
    attribute :image, :string
  end
end
