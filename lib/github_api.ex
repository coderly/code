defmodule C.GitHub.Client do
  use Revolver.Client, otp_app: :c
end

defmodule C.GitHub.API do
  import C.GitHub.Client
  import Revolver.Conn

  @doc """
  Fetches a list of repos for the give username.
  """
  def list! do
    conn() |> get!("/users/venkatd/repos")
  end

  def authorize! do
    auth = get_username_password()
    authorize_req(auth) |> post!("/authorizations")

    otp = IO.gets("Please specify two-factor auth code: ") |> String.trim()

    response = authorize_req(auth)
    |> put_req_header("x-github-otp", otp)
    |> post!("/authorizations")

    token = response.resp_body["token"]

    C.Git.set_config("code.github.token", token)

    IO.puts("Authorized with GitHub")
  end

  def authorize(conn) do
    case C.Git.get_config("code.github.token") do
      {:ok, token} ->
        put_req_header(conn, "authorization", "Bearer #{token}")
    end
  end

  def create_pull_request(opts) do
    opts = Enum.into(opts, %{})
    do_create_pull_request(opts)
  end
  def do_create_pull_request(%{org: org, repo: repo, base: base, head: head}) do
    params = %{
      "title" => "Amazing new feature",
      "body" => "Please pull this in!",
      "head" => head,
      "base" => base
    }
    conn()
    |> authorize()
    |> put_req_body(params)
    |> post!("/repos/#{org}/#{repo}/pulls")
  end

  def get_pull_requests(opts) do
    opts = Enum.into(opts, %{})
    do_get_pull_requests(opts)
  end
  def do_get_pull_requests(%{org: org, repo: repo, base: base, head: head}) do
    conn()
    |> authorize()
    |> get!("/repos/#{org}/#{repo}/pulls?state=open&base=#{base}&head=#{head}")
  end

  defp authorize_req(auth) do
    conn()
    |> put_req_header("authorization", generate_basic_auth_header(auth))
    |> put_req_body(%{"scopes" => ["repo"], "note" => "code cli"})
  end

  def get_username_password() do
    username = IO.gets("username: ")
    password = IO.gets("password: ")
    {String.trim(username), String.trim(password)}
  end

  def generate_basic_auth_header({username, password}) do
    "Basic " <> Base.encode64(username <> ":" <> password)
  end

end
