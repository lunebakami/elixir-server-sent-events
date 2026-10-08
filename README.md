# Server-Sent Events com Elixir e Phoenix

Exemplo didático de SSE implementado manualmente com `Plug.Conn.send_chunked/2`
e `Plug.Conn.chunk/2`. O Phoenix mantém uma resposta HTTP aberta e envia um
contador a cada segundo. Um frontend em HTML e JavaScript recebe os eventos
com `EventSource` e mostra o contador e o histórico na tela.

## Requisitos e instalação

O exemplo foi preparado com Elixir 1.19.5, Erlang/OTP 28.5 e Phoenix 1.8.15.
Não precisa de banco de dados, Node.js ou compilação de assets.

Se você usa [mise](https://mise.jdx.dev/), pode instalar e ativar as versões
na pasta do projeto:

```bash
mise use --pin erlang@28.5 elixir@1.19.5-otp-28
elixir --version
mix local.hex --force
mix local.rebar --force
```

Para baixar e executar este projeto:

```bash
git clone https://github.com/lunebakami/elixir-server-sent-events.git
cd elixir-server-sent-events
mix setup
mix phx.server
```

Se as ferramentas foram configuradas em outra pasta pelo mise, execute o
comando `mise use` acima também na pasta deste clone.

## Testar pelo frontend

Abra [http://localhost:4000/index.html](http://localhost:4000/index.html)
no navegador, preferencialmente Brave Origin.

1. Clique em **Conectar** para abrir a conexão SSE.
2. Observe o contador e o histórico atualizando a cada segundo.
3. Clique em **Desconectar** para encerrar a conexão com `EventSource.close()`.
4. Conecte novamente: uma nova requisição inicia o contador em 1.

Nas ferramentas de desenvolvedor, abra **Network** e selecione a requisição
`events` para acompanhar a conexão. Ela permanece aberta enquanto você recebe
os eventos. A página e o endpoint usam a mesma origem, permitindo usar
`new EventSource("/events")` diretamente.

## Testar pelo terminal

Com o servidor rodando, execute em outro terminal:

```bash
curl -N -i http://localhost:4000/events
```

O `-N` desativa o buffering de saída do curl; o `-i` mostra os cabeçalhos.
Depois deles, os eventos aparecem neste formato:

```text
event: contador
data: {"valor":1}

event: contador
data: {"valor":2}

```

A linha vazia após `data` delimita cada evento. Use `Ctrl+C` para desconectar.

## Como funciona

Os arquivos principais são:

| Arquivo | Responsabilidade |
| --- | --- |
| `lib/sse_demo_web/router.ex` | Define `GET /events` fora do pipeline que aceita somente JSON. |
| `lib/sse_demo_web/controllers/sse_controller.ex` | Configura os cabeçalhos e escreve os eventos na resposta. |
| `lib/sse_demo_web.ex` | Inclui `index.html` na lista de arquivos estáticos permitidos. |
| `priv/static/index.html` | Abre e fecha a conexão e exibe os dados recebidos. |

No controller, `send_chunked(200)` inicia a resposta com status 200 e o tipo
`text/event-stream`. Depois, cada chamada a `chunk/2` envia texto no formato SSE:

```elixir
dados = Jason.encode!(%{valor: valor})
evento = "event: contador\ndata: #{dados}\n\n"
```

Quando `chunk/2` retorna `{:ok, conn}`, o processo espera um segundo e chama
novamente a função com o contador incrementado. `Process.sleep/1` suspende o
processo daquela requisição; outras conexões continuam sendo atendidas.
Quando uma escrita retorna erro, o loop termina.

No frontend, o nome `contador` corresponde ao campo `event` enviado pelo servidor:

```javascript
const stream = new EventSource("/events");

stream.addEventListener("contador", (evento) => {
  const dados = JSON.parse(evento.data);
  console.log(dados.valor);
});
```

## Criar um projeto equivalente do zero

Com Elixir, Hex e Rebar instalados:

```bash
mix archive.install hex phx_new 1.8.15 --force
mix phx.new sse_demo --no-ecto --no-html --no-assets --no-live --no-mailer --install
cd sse_demo
```

Em seguida, implemente o controller e a rota `/events`, crie o frontend em
`priv/static/index.html` e inclua `index.html` em `static_paths/0`, conforme os
arquivos deste repositório. A opção `--no-html` dispensa a estrutura de templates,
mas permite servir essa página estática pelo `Plug.Static` do endpoint.

## Limites do exemplo e próximos passos

Cada conexão tem seu próprio contador. O navegador tenta reconectar após uma
interrupção, mas este exemplo reinicia a contagem e não recupera eventos perdidos.
Para recuperação, é necessário definir IDs, armazenar eventos e tratar o
cabeçalho `Last-Event-ID`.

Para receber eventos reais da aplicação, o próximo passo é assinar um tópico do
`Phoenix.PubSub` e aguardar mensagens com `receive`. Em períodos sem mensagens,
um comentário SSE como `": ping\n\n"` pode servir de heartbeat. Em produção,
ajuste buffering e timeouts do servidor e do proxy; o cabeçalho
`x-accel-buffering: no` presente no exemplo é específico para Nginx.

## Verificação

```bash
mix precommit
```

Esse alias compila com warnings tratados como erros, remove dependências não
usadas do lockfile, formata o código e executa os testes disponíveis. Os testes
automatizados devem ser complementados pela verificação manual do fluxo SSE.

## Referências

- [Gerador de projetos Phoenix](https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html)
- [Plug.Conn.send_chunked/2](https://plug.hexdocs.pm/Plug.Conn.html#send_chunked/2)
- [Plug.Conn.chunk/2](https://plug.hexdocs.pm/Plug.Conn.html#chunk/2)
- [Especificação de Server-Sent Events](https://html.spec.whatwg.org/multipage/server-sent-events.html)
