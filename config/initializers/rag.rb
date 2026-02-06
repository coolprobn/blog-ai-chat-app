# RAG retrieval and reranking configuration.
# Override via ENV: RAG_PRE_RERANK_LIMIT, RAG_POST_RERANK_LIMIT, RAG_RERANK_ENABLED.

Rails.application.config.x.rag_pre_rerank_limit =
  (ENV["RAG_PRE_RERANK_LIMIT"] || 8).to_i.clamp(1, 50)

Rails.application.config.x.rag_post_rerank_limit =
  (ENV["RAG_POST_RERANK_LIMIT"] || 3).to_i.clamp(1, 20)

Rails.application.config.x.rag_rerank_enabled =
  ENV.fetch("RAG_RERANK_ENABLED", "true").downcase.in?(%w[true 1 yes])
