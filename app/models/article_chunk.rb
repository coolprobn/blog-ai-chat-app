class ArticleChunk < ApplicationRecord
  has_neighbors :embedding
end
