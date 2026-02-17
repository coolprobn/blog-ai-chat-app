class ArticleChunk < ApplicationRecord
  has_neighbors :embedding

  scope :with_source, -> { where.not(source_url: [nil, ""]) }
  scope :for_article, ->(url) { where(source_url: url) }

  # Returns array of { url:, title: } for left nav, ordered by title
  def self.distinct_articles
    with_source
      .select("DISTINCT ON (source_url) source_url, source_title")
      .order("source_url, created_at ASC")
      .map { |c| { url: c.source_url, title: c.source_title.presence || c.source_url } }
      .sort_by { |a| a[:title].to_s.downcase }
  end
end
