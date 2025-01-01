defmodule AiDrabbles.Repo do
  use Ecto.Repo,
    otp_app: :ai_drabbles,
    adapter: Ecto.Adapters.Postgres
end
