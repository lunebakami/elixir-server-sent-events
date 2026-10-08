defmodule SseDemoWeb.SseController do
  use SseDemoWeb, :controller

  def index(conn, _params) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("x-accel-buffering", "no")
      |> send_chunked(200)

    enviar_contador(conn, 1)
  end

  defp enviar_contador(conn, valor) do
    dados = Jason.encode!(%{valor: valor})
    evento = "event: contador\ndata: #{dados}\n\n"

    case chunk(conn, evento) do
      {:ok, conn} ->
        Process.sleep(1_000)
        enviar_contador(conn, valor + 1)

      {:error, _motivo} ->
        conn
    end
  end
end
