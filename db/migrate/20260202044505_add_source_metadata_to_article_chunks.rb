class AddSourceMetadataToArticleChunks < ActiveRecord::Migration[8.1]
  def change
    add_column :article_chunks, :source_url, :string
    add_column :article_chunks, :source_title, :string
  end
end
