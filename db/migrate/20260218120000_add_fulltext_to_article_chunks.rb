class AddFulltextToArticleChunks < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL.squish
      ALTER TABLE article_chunks
        ADD COLUMN content_tsv tsvector
        GENERATED ALWAYS AS (
          to_tsvector('english', coalesce(content, '') || ' ' || coalesce(source_title, ''))
        ) STORED;
    SQL

    add_index :article_chunks, :content_tsv, using: :gin
  end

  def down
    remove_index :article_chunks, :content_tsv, if_exists: true
    remove_column :article_chunks, :content_tsv
  end
end
