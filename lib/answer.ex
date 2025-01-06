defmodule QuestionAnswering do
  alias Bumblebee.Text
  alias Nx.Serving

  def register(), do: document_qa_serving(Models.roberta(), Models.roberta_tokenizer(), :serving)

  def ask_question_batched(serving, question, context) do
    inputs = Enum.map(context, fn chunk -> %{question: question, context: chunk} end)
    Serving.batched_run(serving, inputs)
  end

  def ask_question(serving, question, context) do
    Serving.run(serving, %{question: question, context: context})
  end

  def document_qa_serving(model, tokenizer \\ nil, batch_size \\ 4, sequence_length \\ 256) do
    {:ok, model_info} = Bumblebee.load_model({:hf, model})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, tokenizer || model})

    Bumblebee.Text.question_answering(model_info, tokenizer,
      compile: [batch_size: batch_size, sequence_length: sequence_length],
      defn_options: [compiler: EXLA]
    )
  end

  def document_qa_async_serving(
        model,
        tokenizer \\ nil,
        name,
        batch_size \\ 4,
        sequence_length \\ 256
      ) do
    Serving.start_link(
      name: name,
      serving: document_qa_serving(model, tokenizer, batch_size, sequence_length)
    )
  end

  def generate_text_async(serving, prompt) do
    Nx.Serving.batched_run(serving, prompt)
  end

  def generate_text(serving, prompt) do
    Nx.Serving.run(serving, prompt)
  end

  def text_generation_serving(model, tokenizer \\ nil, batch_size \\ 4, sequence_length \\ 256) do
    {:ok, model_info} = Bumblebee.load_model({:hf, model})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, tokenizer || model})
    {:ok, base_config} = Bumblebee.load_generation_config({:hf, model})
    generation_config = Bumblebee.configure(base_config, max_new_tokens: 15)

    Bumblebee.Text.generation(model_info, tokenizer, generation_config,
      stream: true,
      compile: [batch_size: batch_size, sequence_length: sequence_length],
      defn_options: [compiler: EXLA]
    )

    # Nx.Serving.run(serving, "Elixir is a functional") |> Enum.to_list()
  end

  def text_generation_async_serving(
        model,
        name,
        tokenizer \\ nil,
        batch_size \\ 4,
        sequence_length \\ 256
      ) do
    Serving.start_link(
      name: name,
      serving: text_generation_serving(model, tokenizer, batch_size, sequence_length)
    )
  end

  def docs(package) do
    {output, _exit_code} = System.cmd("mix", ["hex.docs", "fetch", package])

    directory_path =
      output
      |> String.split("fetched: ")
      |> List.last()
      |> String.trim()

    raw_text =
      directory_path
      |> Path.join("**/*.html")
      |> Path.wildcard()
      |> Enum.map(&File.read!/1)
      |> Enum.join(" ")
      |> Floki.text()

    raw_text
    |> String.graphemes()
    |> Enum.chunk_every(1000)
    |> Enum.map(&Enum.join/1)
  end

  def chunked_text(filename, chunk_size \\ 500, overlap_size \\ 100) do
    content = File.read!(filename)

    # Split content into graphemes
    graphemes = String.graphemes(content)

    # Chunk the graphemes with the specified overlap
    graphemes
    |> Enum.chunk_every(chunk_size, chunk_size - overlap_size, :discard)
    |> Enum.map(&Enum.join/1)
  end
end

# {:ok, model_info} = Bumblebee.load_model({:hf, "google/flan-t5-large"})
# {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "google/flan-t5-large"})
# {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "google/flan-t5-large"})
# generation_config = Bumblebee.configure(generation_config, max_new_tokens: 15)

# serving = Bumblebee.Text.generation(model_info, tokenizer, generation_config, stream: true)

# Nx.Serving.run(serving, "Elixir is a functional") |> Enum.to_list()

# "google/flan-t5-large"
