namespace :blog do
  desc "Fetch and store article chunks with embeddings"
  task ingest: :environment do
    require "ruby_llm"
    require "nokogiri"
    require "httparty"

    # NOTE: change this to your own blog URL if you want
    base_url = "https://prabinpoudel.com.np"
    article_index = HTTParty.get("#{base_url}/articles/")
    doc = Nokogiri.HTML(article_index.body)

    links =
      doc
        .css("a")
        .map { |a| a["href"] }
        .select { |href| href&.include?("/articles/") }
        .uniq

    links.each do |path|
      full_url = URI.join(base_url, path).to_s
      puts "Fetching #{full_url}"

      page = HTTParty.get(full_url)
      next unless page.success?

      page_doc = Nokogiri.HTML(page.body)
      article_node = page_doc.css("article").first
      next unless article_node

      # Extract text but preserve hyperlinks as "link text (url)" so references are stored
      content = []
      article_node.traverse do |node|
        if node.is_a?(Nokogiri::XML::Text)
          # Skip text inside <a> so we don't duplicate link text
          content << node.text if node.parent.name != "a"
        elsif node.name == "a" && node["href"].present?
          link_text = node.text.strip.presence || node["href"]
          href = node["href"].strip
          href = URI.join(full_url, href).to_s if href.start_with?("/")
          content << " #{link_text} (#{href}) "
        end
      end

      content = content.compact.join.gsub(/\s+/, " ").strip

      source_title =
        article_node.css("h1, h2").first&.text&.strip.presence || full_url

      chunks = content.scan(/.{1,800}(?:\n|\z)/m)

      chunks.each do |chunk|
        embedding =
          RubyLLM.embed(chunk, provider: :ollama, assume_model_exists: true)

        ArticleChunk.create!(
          content: chunk,
          embedding: embedding.vectors,
          source_url: full_url,
          source_title: source_title
        )
      end
    end
  end
end
