class BlogSearch < RubyLLM::Tool
  include Rails.application.routes.url_helpers

  description "Searches the author's blog posts for relevant content only."
  param :query, desc: "User question about the blog"

  def execute(query:)
    result = search(query)

    { context: build_context(result), sources: result[:sources] }.to_json
  end

  RRF_K = 60

  def search(query)
    q = query.to_s.strip
    return empty_result if q.blank?

    pre_limit = Rails.application.config.x.rag_pre_rerank_limit
    post_limit = Rails.application.config.x.rag_post_rerank_limit
    rerank = Rails.application.config.x.rag_rerank_enabled

    # Vector (semantic) search
    embedding =
      RubyLLM.embed(q, provider: :ollama, assume_model_exists: true).vectors
    vector_chunks =
      ArticleChunk
        .nearest_neighbors(:embedding, embedding, distance: "cosine")
        .limit(pre_limit)
        .to_a

    # Keyword (full-text) search
    keyword_chunks =
      ArticleChunk.keyword_search(q, limit: pre_limit).to_a

    # Hybrid: merge with Reciprocal Rank Fusion, then cap
    chunks = rrf_merge(vector_chunks, keyword_chunks).first(pre_limit)

    return empty_result if chunks.empty?

    if rerank && chunks.size > post_limit
      chunks = Reranker.new.call(q, chunks, post_limit)
    else
      chunks = chunks.first(post_limit)
    end

    context_parts = []
    sources = []

    chunks.each do |chunk|
      app_url =
        chunk.source_url.present? ? article_app_url(chunk.source_url) : nil
      source_line =
        if app_url.present?
          "[Source: #{chunk.source_title} | URL: #{app_url}]"
        else
          "[Source: #{chunk.source_title}]"
        end
      context_parts << <<~TEXT.strip
        #{source_line}
        #{chunk.content}
      TEXT

      sources << { title: chunk.source_title, url: app_url } if app_url
    end

    {
      context: context_parts.join("\n\n---\n\n"),
      sources: sources.uniq { |s| s[:url] }
    }
  end

  private

  def rrf_merge(vector_list, keyword_list, k: RRF_K)
    scores = Hash.new(0)
    vector_list.each_with_index { |c, i| scores[c.id] += 1.0 / (k + i + 1) }
    keyword_list.each_with_index { |c, i| scores[c.id] += 1.0 / (k + i + 1) }

    all_by_id = (vector_list + keyword_list).index_by(&:id)
    all_by_id
      .values
      .sort_by { |c| -scores[c.id] }
      .uniq(&:id)
  end

  def article_app_url(external_url)
    return nil if external_url.blank?

    root_url(article: external_url, host: "http://localhost:3000")
  end

  def empty_result
    { context: "NO_RELEVANT_BLOG_CONTENT", sources: [] }
  end

  def build_context(result)
    <<~TEXT
      BLOG_CONTEXT_START
      #{result[:context]}
      BLOG_CONTEXT_END
    TEXT
  end
end
