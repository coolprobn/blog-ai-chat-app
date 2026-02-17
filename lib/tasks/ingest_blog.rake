namespace :blog do
  MAX_ARTICLES = 100

  desc "Fetch and store article chunks with embeddings (follows pagination, max #{MAX_ARTICLES} articles)"
  task ingest: :environment do
    require "ruby_llm"
    require "nokogiri"
    require "httparty"

    # NOTE: change this to your own blog URL if you want
    base_url = "https://prabinpoudel.com.np"

    # Collect article URLs from index + paginated pages. Skip /articles/page/N/ itself.
    article_urls = []
    page_num = 1

    loop do
      index_url =
        (
          if page_num == 1
            "#{base_url}/articles/"
          else
            "#{base_url}/articles/page/#{page_num}/"
          end
        )
      puts "Scanning index: #{index_url}"
      page = HTTParty.get(index_url)
      break unless page.success?

      doc = Nokogiri.HTML(page.body)
      links =
        doc
          .css("a")
          .map { |a| a["href"] }
          .compact
          .map { |href| URI.join(base_url, href).to_s }
          .uniq

      # Only links to actual articles: exclude index and pagination pages
      new_articles =
        links.select do |url|
          next false if url == "#{base_url}/articles"
          next false if url == "#{base_url}/articles/"
          next false if url.match?(%r{/articles/page/\d+/?\z})
          url.include?("/articles/")
        end

      new_articles.each do |url|
        article_urls << url unless article_urls.include?(url)
      end

      break if article_urls.size >= MAX_ARTICLES

      # Next page: try page_num + 1; stop if this page had no new article links
      has_next =
        links.any? { |u| u.match?(%r{/articles/page/#{page_num + 1}/?}) }
      break unless has_next

      page_num += 1
    end

    article_urls = article_urls.first(MAX_ARTICLES)
    puts "Found #{article_urls.size} article(s) to ingest"

    article_urls.each do |full_url|
      puts "Fetching #{full_url}"

      page = HTTParty.get(full_url)
      next unless page.success?

      page_doc = Nokogiri.HTML(page.body)
      article_node = page_doc.css("article").first
      next unless article_node

      source_title =
        article_node.css("h1, h2").first&.text&.strip.presence || full_url

      # Store full article HTML for display (code blocks, headings, etc.)
      full_html = article_node.inner_html
      fragment = Nokogiri::HTML.fragment(full_html)
      fragment
        .css("a[href]")
        .each do |a|
          href = a["href"].to_s.strip
          a["href"] = URI.join(full_url, href).to_s if href.start_with?("/")
        end
      Article.find_or_initialize_by(source_url: full_url).update!(
        title: source_title,
        content: fragment.to_html
      )

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
