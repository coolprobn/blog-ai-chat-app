# README

## Gemini AI Bot for Personal Blog

Hi!

This is my first project using AI/LLM and it took a whole day to complete this project; me being an absolute beginner.

Below I have laid out instructions on running this app locally.

### Built with

1. Rails
2. Ruby LLM
3. Gemini

You can switch to OpenAI using RubyLLM if you want, I used Gemini because it's free.

### Pre-requisites

1. API Key for Gemini, you can get yours at https://aistudio.google.com/app/apikey
2. pgvector extension in your machine
  
    I am using M1 MacOS and all I had to do was run `brew install pgvector`

### Installation

1. Clone the repo: `git clone git@github.com:coolprobn/blog-ai-chat-app.git`
2. Regenerate credentials since current credentials file uses my secret key: `rm config/credentials.yml.enc && EDITOR=nano bin/rails credentials:edit`
3. Add api key for Gemini inside the credentials file

    ```
    gemini:
      api_key: add_your_key_here
    ```

### Store blog content from web to database

Run `bin/rails blog:ingest` so blog content is fetched from the Web and stored in the database as a vector.

It's only fetching 5-6 pages at the moment but it works for this demo so I have left it as it is for now.

Rake task for this is inside `lib/ingest_blog.rake`.

You can change URL to your own blog and modify content as required if you want the bot to answer questions about your blogs.

### See it in action

Run `bin/dev` and visit `http://localhost:3000/` to see the app in action. Ask questions and you will get a brief summary of the content in blogs.

Please note that Bot is really not that smart. You have to be very specific to get correct answers.

Overall, it was a very nice experience for me honestly. It had been a long time since I wanted to build something in AI space.

It was also very frustrating not knowing where to start because I am an absolute beginner and by open-sourcing this repo, I hope it ends up helping a lot more beginners like me.

Thanks for sticking till the end! Happy tinkering and happy coding!

Lastly, don't hesitate to shoot me a [DM in Twitter](https://x.com/coolprobn) if you have any questions or confusion, I will try my best to help you.
