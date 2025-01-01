defmodule AiDrabbles.OpenAI do
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message
  require Logger

  def initialize_chain(message, model, opts \\ %{}) do
    api_key = System.get_env("OPENAI_KEY")

    %{llm: ChatOpenAI.new!(%{model: model, api_key: api_key})}
    |> LLMChain.new!()
    |> Map.merge(opts)
    |> LLMChain.add_message(Message.new_user!(message))
  end

  def run_chain(chain) do
    chain
    |> LLMChain.run()
    |> case do
      {:error, error} ->
        "You stupid fuck: #{error}"

      {:ok, updated_chain, %{content: last_message_content}} ->
        Logger.debug(last_message_content)
        updated_chain
    end
  end

  # TODO we need a module to spin up a genserver and hold the current chain as state
  # Maybe that should be separate from the API module? I think so
  # In that case, the API module (which is our boundary layer)
  # Should call the genserver module, which is pure
  # The boundary layer can just implement genserver unless the
  # genservers need some unique/fancy functionality
  def reply_to_chain(chain, message, opts \\ %{}) do
    chain
    |> Map.merge(opts)
    |> LLMChain.add_message(Message.new_user!(message))
  end
end
