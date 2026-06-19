class Page < ApplicationModel
  attribute :filepath, :string
  attribute :frontmatter, default: -> { {} }
  attribute :body, :string

  def self.all
    # Load all files from _posts directory
    cache[:all] ||= Dir.glob("#{Rails.root}/_pages/**/*.*").map do |filepath|
      Page.from_file(filepath)
    end
  end

  def self.from_file(path)
    parsed = FrontMatterParser::Parser.parse_file(path)
    new(filepath: path, frontmatter: parsed.front_matter, body: parsed.content)
  end

  def slug
    @_slug ||= raw_slug.downcase
  end

  def project_filepath
    filepath.sub("#{Rails.root}/", "")
  end

  def filename
    File.basename(filepath, ".*")
  end

  def title
    frontmatter.fetch("title", "")
  end

  def summary
    frontmatter["summary"] || frontmatter["description"] || ""
  end

  def content
    @_content ||= Kramdown::Document.new(body, input: "GFM").to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def raw_slug
    filename&.gsub(/\.[^.]+\z/, "")
  end
end
