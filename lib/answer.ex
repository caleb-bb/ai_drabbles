defmodule QuestionAnswering do
  alias Bumblebee.Text
  alias Nx.Serving

  def setup_model do
    # Load the model and tokenizer
    {:ok, model} =
      Bumblebee.load_model(
        {:local,
         "/Users/caleb/.cache/huggingface/hub/models--google--flan-t5-large/snapshots/0613663d0d48ea86ba8cb3d7a44f0f65dc596a2a"}
      )

    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "distilbert-base-uncased"})

    # Define the question-answering pipeline
    Bumblebee.Text.question_answering(model, tokenizer)
  end

  def ask_question(pipeline, question, context) do
    Serving.run(pipeline, %{question: question, context: context})
  end

  def document_qa_serving(model, tokenizer \\ nil) do
    {:ok, model_info} = Bumblebee.load_model({:hf, model})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, tokenizer || model})

    Bumblebee.Text.question_answering(model_info, tokenizer)
  end

  def text_generation_serving(model, tokenizer \\ nil) do
    {:ok, model_info} = Bumblebee.load_model({:hf, model})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, tokenizer || model})
    {:ok, base_config} = Bumblebee.load_generation_config({:hf, model}) |> dbg()
    generation_config = Bumblebee.configure(base_config, max_new_tokens: 15)

    Bumblebee.Text.generation(model_info, tokenizer, generation_config, stream: true)

    # Nx.Serving.run(serving, "Elixir is a functional") |> Enum.to_list()
  end
end

# {:ok, model_info} = Bumblebee.load_model({:hf, "google/flan-t5-large"})
# {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "google/flan-t5-large"})
# {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "google/flan-t5-large"})
# generation_config = Bumblebee.configure(generation_config, max_new_tokens: 15)

# serving = Bumblebee.Text.generation(model_info, tokenizer, generation_config, stream: true)

# Nx.Serving.run(serving, "Elixir is a functional") |> Enum.to_list()

# "google/flan-t5-large"
