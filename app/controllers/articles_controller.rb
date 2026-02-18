class ArticlesController < ApplicationController
  def index
    @articles = Article.all
    @selected_url = params[:article].presence

    return unless @selected_url.present?

    article = Article.find_by(source_url: @selected_url)

    @selected_article_title = article.title.presence || @selected_url
    @selected_article_content = article.content
  end
end
