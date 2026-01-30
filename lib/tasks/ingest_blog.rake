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
      article_node = page_doc.css("article")
      content = article_node.text.strip

      chunks = content.scan(/.{1,1000}/m)

      chunks.each do |chunk|
        embedding =
          RubyLLM.embed(chunk, provider: :ollama, assume_model_exists: true)

        ArticleChunk.create!(content: chunk, embedding: embedding.vectors)
      end
    end
  end
end
