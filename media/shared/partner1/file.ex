@doc since: "1.12.0"
@spec raise(binary, exit_code: non_neg_integer()) :: no_return
def raise(message, opts) when is_binary(message) and is_list(opts) do
  Kernel.raise(Mix.Error, mix: Keyword.get(opts, :exit_code, 1), message: message)
end

@doc since: "1.10.0"
@spec path_for(:archives | :escripts) :: String.t()
def path_for(:archives) do
  System.get_env("MIX_ARCHIVES") || Path.join(Mix.Utils.mix_home(), "archives")
end

def path_for(:escripts) do
  Path.join(Mix.Utils.mix_home(), "escripts")
end

@doc since: "1.12.0"
def install(deps, opts \\ [])

def install(deps, opts) when is_list(deps) and is_list(opts) do
  Mix.start()

  if Mix.Project.get() do
    Mix.raise("Mix.install/2 cannot be used inside a Mix project")
  end

  elixir_requirement = opts[:elixir]
  elixir_version = System.version()

  if !!elixir_requirement and not Version.match?(elixir_version, elixir_requirement) do
    Mix.raise(
      "Mix.install/2 declared it supports only Elixir #{elixir_requirement} " <>
        "but you're running on Elixir #{elixir_version}"
    )
  end

  deps =
    Enum.map(deps, fn
      dep when is_atom(dep) ->
        {dep, ">= 0.0.0"}

      {app, opts} when is_atom(app) and is_list(opts) ->
        {app, maybe_expand_path_dep(opts)}

      {app, requirement, opts} when is_atom(app) and is_binary(requirement) and is_list(opts) ->
        {app, requirement, maybe_expand_path_dep(opts)}

      other ->
        other
    end)

  force? = !!opts[:force]

  case Mix.State.get(:installed) do
    nil ->
      :ok

    ^deps when not force? ->
      :ok

    _ ->
      Mix.raise("Mix.install/2 can only be called with the same dependencies in the given VM")
  end

  installs_root =
    System.get_env("MIX_INSTALL_DIR") ||
      Path.join(Mix.Utils.mix_cache(), "installs")

  id = deps |> :erlang.term_to_binary() |> :erlang.md5() |> Base.encode16(case: :lower)
  version = "elixir-#{System.version()}-erts-#{:erlang.system_info(:version)}"
  dir = Path.join([installs_root, version, id])

  if opts[:verbose] do
    Mix.shell().info("using #{dir}")
  end

  if force? do
    File.rm_rf!(dir)
  end

  config = [
    version: "0.1.0",
    build_per_environment: true,
    build_path: "_build",
    lockfile: "mix.lock",
    deps_path: "deps",
    deps: deps,
    app: :mix_install,
    erlc_paths: ["src"],
    elixirc_paths: ["lib"],
    compilers: [],
    consolidate_protocols: Keyword.get(opts, :consolidate_protocols, true)
  ]

  :ok = Mix.Local.append_archives()
  :ok = Mix.ProjectStack.push(__MODULE__.InstallProject, config, "nofile")
  build_dir = Path.join(dir, "_build")

  try do
    run_deps? = not File.dir?(build_dir)
    File.mkdir_p!(dir)

    File.cd!(dir, fn ->
      if run_deps? do
        Mix.Task.rerun("deps.get")
      end

      Mix.Task.rerun("deps.loadpaths")
      Mix.Task.rerun("compile")
    end)

    for app <- Mix.Project.deps_apps() do
      Application.ensure_all_started(app)
    end

    Mix.State.put(:installed, deps)
    :ok
  after
    Mix.ProjectStack.pop()
  end
end

defp maybe_expand_path_dep(opts) do
  if Keyword.has_key?(opts, :path) do
    Keyword.update!(opts, :path, &Path.expand/1)
  else
    opts
  end
end
end