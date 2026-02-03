class BlogSearch < RubyLLM::Tool
  LIMIT = 5

  description "Searches blog posts for relevant content to answer questions."
  param :query, desc: "User question about the blog"

  def execute(query:)
    result = search(query)
    context = result[:context]
    sources = result[:sources]

    sources_line =
      sources
        .each_with_index
        .map { |s, i| "[#{i + 1}] #{s[:title]} (#{s[:url]})" }
        .join(", ")

    <<~TEXT.strip
      Context:
      #{context}

      Sources:
      #{sources_line.present? ? "Sources: #{sources_line}\n\n" : ""}
    TEXT
  end

  # Returns { context: string, sources: array } for use by controllers (RAG + citations).
  def search(query)
    q = query.to_s.strip
    return { context: "No query provided.", sources: [] } if q.blank?

    embedding =
      RubyLLM.embed(q, provider: :ollama, assume_model_exists: true).vectors

    chunks =
      ArticleChunk.nearest_neighbors(
        :embedding,
        embedding,
        distance: "cosine"
      ).limit(LIMIT)

    if chunks.empty?
      return { context: "No relevant blog content found.", sources: [] }
    end

    sources = []
    context_parts = []

    chunks.each do |chunk|
      context_parts << chunk.content
      if chunk.source_url.present? || chunk.source_title.present?
        title = chunk.source_title.presence || "Post"
        url = chunk.source_url.presence
        sources << { title:, url: } if url.present?
      end
    end

    sources.uniq! { |s| s[:url] }

    context = context_parts.join("\n\n---\n\n")

    { context:, sources: }
  end
end
