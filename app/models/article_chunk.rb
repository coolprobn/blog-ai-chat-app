class ArticleChunk < ApplicationRecord
  has_neighbors :embedding

  scope :with_source, -> { where.not(source_url: [nil, ""]) }
  scope :for_article, ->(url) { where(source_url: url) }

  # Full-text search on content + source_title. Returns relation ordered by ts_rank.
  # Requires content_tsv column (add_fulltext_to_article_chunks migration).
  def self.keyword_search(query, limit: 100)
    q = query.to_s.strip
    return none if q.blank?

    safe = connection.quote(q)
    where("content_tsv @@ plainto_tsquery('english', ?)", q)
      .order(Arel.sql("ts_rank_cd(content_tsv, plainto_tsquery('english', #{safe})) DESC"))
      .limit(limit)
  end

  # Returns array of { url:, title: } for left nav, ordered by title
  def self.distinct_articles
    with_source
      .select("DISTINCT ON (source_url) source_url, source_title")
      .order("source_url, created_at ASC")
      .map { |c| { url: c.source_url, title: c.source_title.presence || c.source_url } }
      .sort_by { |a| a[:title].to_s.downcase }
  end
end
