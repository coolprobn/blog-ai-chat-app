# frozen_string_literal: true

class Article < ApplicationRecord
  validates :source_url, presence: true, uniqueness: true
end
