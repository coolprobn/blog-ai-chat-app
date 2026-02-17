class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :source_url
      t.string :title
      t.text :content

      t.timestamps
    end
    add_index :articles, :source_url, unique: true
  end
end
