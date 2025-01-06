defmodule ChainStuff do
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message

  def do_shit() do
    {:ok, _updated_chain, response} =
      %{llm: ChatOpenAI.new!(%{model: "gpt-4"})}
      |> LLMChain.new!()
      |> LLMChain.add_message(Message.new_user!("Testing, testing!"))
      |> LLMChain.run()

    response.content
  end

  def agent() do
    %{llm: ChatOpenAI.new!(%{model: "gpt-4"})}
    |> LLMChain.new!()
  end
end
