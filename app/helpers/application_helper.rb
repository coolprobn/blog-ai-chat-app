module ApplicationHelper
  # Sanitizes stored article HTML (from Article) for safe display. Keeps structure, code blocks, links.
  def sanitize_article_html(html)
    return "" if html.blank?

    sanitize(
      html,
      tags: %w[
        p div span br h1 h2 h3 h4 h5 h6
        a strong em b i code pre ul ol li
        blockquote hr img table thead tbody tr th td
      ],
      attributes: {
        "a" => %w[href target rel class],
        "img" => %w[src alt width height class],
        "code" => ["class"],
        "pre" => ["class"],
        "div" => ["class"],
        "span" => ["class"]
      }
    )
  end

  # Renders article content as HTML via Redcarpet: paragraphs, code blocks, links, lists, etc.
  def format_article_content(content)
    return "" if content.blank?

    html = markdown_renderer.render(content)
    sanitize(
      html,
      tags: %w[
        p
        br
        a
        strong
        em
        b
        i
        code
        pre
        ul
        ol
        li
        h1
        h2
        h3
        h4
        blockquote
        hr
      ],
      attributes: {
        "a" => %w[href target rel class],
        "pre" => ["class"],
        "code" => ["class"]
      }
    )
  end

  def markdown_renderer
    @markdown_renderer ||=
      Redcarpet::Markdown.new(
        Redcarpet::Render::HTML.new(
          filter_html: true,
          link_attributes: {
            target: "_blank",
            rel: "noopener"
          }
        ),
        fenced_code_blocks: true,
        autolink: true,
        tables: true,
        strikethrough: true,
        lax_spacing: false
      )
  end
end
