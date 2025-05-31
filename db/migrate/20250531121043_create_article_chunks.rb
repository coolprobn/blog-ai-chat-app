class CreateArticleChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :article_chunks do |t|
      t.text :content
      t.vector :embedding

      t.timestamps
    end
  end
end
