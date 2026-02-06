# Reranks a list of chunks by relevance to a query using the configured LLM (Ollama).
# Used by BlogSearch after retrieval; not an LLM-callable tool.
class Reranker
  INSTRUCTIONS = <<~TEXT.strip.freeze
    You are a relevance judge. Given a query and numbered passages, output only the passage numbers in order of relevance to the query, one number per line. No explanation, no other text.
  TEXT

  # @param query [String] user question
  # @param chunks [Array<ArticleChunk>] chunks to rerank (order preserved on failure)
  # @param keep_top [Integer] number of top chunks to return
  # @return [Array<ArticleChunk>] top keep_top chunks in relevance order
  def call(query, chunks, keep_top)
    return chunks.first(keep_top) if chunks.size <= keep_top

    prompt = build_prompt(query, chunks, keep_top)
    response =
      RubyLLM
        .chat(provider: :ollama, assume_model_exists: true)
        .with_instructions(INSTRUCTIONS)
        .with_temperature(0)
        .ask(prompt)

    indices = parse_response(response.content, chunks.size, keep_top)
    return chunks.first(keep_top) if indices.blank?

    indices.first(keep_top).filter_map { |i| chunks[i] if i.between?(0, chunks.size - 1) }
  rescue StandardError => e
    Rails.logger.warn("[Reranker] Rerank failed, using original order: #{e.message}")
    chunks.first(keep_top)
  end

  private

  def build_prompt(query, chunks, keep_top)
    passages =
      chunks
        .each_with_index
        .map { |c, i| "#{i + 1}. #{c.content.truncate(600)}" }
        .join("\n\n")

    <<~TEXT.strip
      Query: #{query}

      Passages:
      #{passages}

      Return only the numbers 1-#{chunks.size} of the top #{keep_top} most relevant passages, one number per line, most relevant first. No other text.
    TEXT
  end

  def parse_response(content, max_index, limit)
    return [] if content.blank?

    lines =
      content
        .strip
        .lines
        .map(&:strip)
        .reject(&:blank?)
        .first(limit)

    indices = []
    lines.each do |line|
      n = line.to_i
      indices << n - 1 if n.between?(1, max_index) && !indices.include?(n - 1)
    end
    indices
  end
end
