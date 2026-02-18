module ApplicationHelper
  # Sanitizes stored article HTML (from Article) for safe display. Keeps structure, code blocks, links.
  def sanitize_article_html(html)
    return "" if html.blank?

    sanitize(
      html,
      tags: %w[
        p
        div
        span
        br
        h1
        h2
        h3
        h4
        h5
        h6
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
        blockquote
        hr
        img
        table
        thead
        tbody
        tr
        th
        td
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
end
