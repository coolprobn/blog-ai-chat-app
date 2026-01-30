class BlogSearch < RubyLLM::Tool
  description "Searches blog posts for relevant content to answer questions."
  param :query, desc: "User question about the blog"

  def execute(query:)
    embedding =
      RubyLLM.embed(query, provider: :ollama, assume_model_exists: true).vectors

    chunks =
      ArticleChunk.nearest_neighbors(
        :embedding,
        embedding,
        distance: "cosine"
      ).limit(5)

    return "No relevant blog content found." if chunks.empty?

    chunks.map(&:content).join("\n\n---\n\n")
  end
end
