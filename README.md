# README

## RAG Chat for Personal Blog

Hi!

This is my first project using AI/LLM and it took a whole day to complete this project; me being an absolute beginner.

Below I have laid out instructions on running this app locally.

### Built with

1. Rails
2. [Ruby LLM](https://github.com/crmne/ruby_llm)
3. **Ollama** — local LLM stack using:
   - **Qwen** (`qwen2.5:7b-instruct`) for chat/completions
   - **Nomic** (`nomic-embed-text`) for embeddings (RAG retrieval)

You can use any other Ollama (or RubyLLM-supported) model or any switch to any other models like OpenAI and Gemini by editing `config/initializers/ruby_llm.rb` and changing `config.default_model` and `config.default_embedding_model`.

### Pre-requisites

1. **Ollama** (macOS only in this guide) — see [Install Ollama on macOS](#install-ollama-on-macos) below.
2. **pgvector** — for vector search. On macOS: `brew install pgvector`

### Install Ollama on macOS

1. **Install Ollama**
   - Download the macOS app from [ollama.com](https://ollama.com) and drag it to Applications, or install via Homebrew:
     ```bash
     brew install ollama
     ```
   - Start the Ollama service (required for the app to work):
     ```bash
     ollama serve
     ```
     Leave this running in a terminal, or run Ollama from the menu bar if you installed the app.

2. **Pull the chat model (Qwen)**
   ```bash
   ollama pull qwen2.5:7b-instruct
   ```

3. **Pull the embedding model (Nomic)**
   ```bash
   ollama pull nomic-embed-text
   ```

After this, the app will use these models for RAG Q&A.

### Installation

1. Clone the repo: `git clone git@github.com:coolprobn/blog-ai-chat-app.git`
2. Install dependencies: `bundle install`
3. Set up the database: `bin/rails db:create db:migrate`
4. (Optional) Regenerate credentials if you add API keys later: `rm config/credentials.yml.enc && EDITOR=nano bin/rails credentials:edit`

### Configure models (optional)

To use a different chat or embedding model, edit `config/initializers/ruby_llm.rb` and change:

- `config.default_model` — chat/completions (e.g. another Ollama model)
- `config.default_embedding_model` — embeddings for RAG (e.g. another Ollama embedding model)

No API keys are required when using Ollama locally.

### Store blog content from web to database

Run:

```bash
bin/rails blog:ingest
```

Blog content is fetched from the web and stored in the database as vectors using the Nomic embedding model.

The rake task lives in `lib/tasks/ingest_blog.rake`. You can change the blog URL and parsing logic there to point at your own blog.

### See it in action

1. Ensure **Ollama is running** (`ollama serve` or the Ollama app).
2. Run the app: `bin/dev`
3. Open [http://localhost:3000/](http://localhost:3000/)

You’ll land on the chats page. Create a new chat and ask questions about your blog; answers are generated using RAG over the ingested content (Qwen for chat, Nomic for retrieval).

The bot only answers from the blog content it has seen—ask specific questions for best results.

---

It was a very nice experience for me honestly. It had been a long time since I wanted to build something in the AI space.

It was also very frustrating not knowing where to start because I am an absolute beginner. By open-sourcing this repo, I hope it helps other beginners like me.

Thanks for sticking till the end! Happy tinkering and happy coding!

If you have questions, feel free to reach out via [Twitter/X](https://x.com/coolprobn).
