defmodule Summarize do
  import Models

  def chunked_text(filename, chunk_size \\ 500, overlap_size \\ 100) do
    graphemes =
      filename
      |> File.read!()
      |> String.graphemes()

    # Chunk the graphemes with the specified overlap
    graphemes
    |> Enum.chunk_every(chunk_size, chunk_size - overlap_size, :discard)
    |> Enum.map(&Enum.join/1)
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

  def summarize(serving, text) do
    prompt = "The text is: #{text} \n In summary, the author is saying:"
    pid = self()

    spawn(fn ->
      output = Nx.Serving.run(serving, prompt) |> Enum.to_list()
      send(pid, {:output, output})
    end)

    start_time = :erlang.monotonic_time(:second)

    receive do
      {:output, output} ->
        end_time = :erlang.monotonic_time(:second)
        IO.puts("Process took #{end_time - start_time} seconds.")
        IO.inspect(serving, label: "With serving")
        output
    after
      60 * 60 * 12 * 1000 -> "Timed out after 12 hours"
    end
  end
end
