class BlogSearch < RubyLLM::Tool
  description "Searches the author's blog posts for relevant content only."
  param :query, desc: "User question about the blog"

  def execute(query:)
    result = search(query)

    { context: build_context(result), sources: result[:sources] }.to_json
  end

  def search(query)
    q = query.to_s.strip
    return empty_result if q.blank?

    pre_limit = Rails.application.config.x.rag_pre_rerank_limit
    post_limit = Rails.application.config.x.rag_post_rerank_limit
    rerank = Rails.application.config.x.rag_rerank_enabled

    embedding =
      RubyLLM.embed(q, provider: :ollama, assume_model_exists: true).vectors

    chunks =
      ArticleChunk
        .nearest_neighbors(:embedding, embedding, distance: "cosine")
        .limit(pre_limit)
        .to_a

    return empty_result if chunks.empty?

    if rerank && chunks.size > post_limit
      chunks = Reranker.new.call(q, chunks, post_limit)
    else
      chunks = chunks.first(post_limit)
    end

    context_parts = []
    sources = []

    chunks.each do |chunk|
      context_parts << <<~TEXT.strip
        [Source: #{chunk.source_title}]
        #{chunk.content}
      TEXT

      if chunk.source_url.present?
        sources << { title: chunk.source_title, url: chunk.source_url }
      end
    end

    {
      context: context_parts.join("\n\n---\n\n"),
      sources: sources.uniq { |s| s[:url] }
    }
  end

  private

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
