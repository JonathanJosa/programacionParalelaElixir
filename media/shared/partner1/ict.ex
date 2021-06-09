defmodule ElixirScript.State do
    @moduledoc false
  
    # Holds the state for the ElixirScript compiler
  
    def start_link(compiler_opts) do
      Agent.start_link(fn ->
        %{
          modules: Keyword.new(),
          js_modules: [],
          in_memory_modules: [],
          compiler_opts: compiler_opts
        }
      end)
    end
  
    def stop(pid) do
      Agent.stop(pid)
    end
  
    def get_module(pid, module) do
      Agent.get(pid, fn state ->
        Keyword.get(state.modules, module)
      end)
    end
  
    def put_module(pid, module, value) do
      Agent.update(pid, fn state ->
        value =
          Map.put_new(value, :used, [])
          |> Map.put_new(:used_modules, [])
  
        modules = Keyword.put(state.modules, module, value)
        %{state | modules: modules}
      end)
    end
  
    def put_used_module(pid, module, used_module) do
      Agent.update(pid, fn state ->
        module_info = Keyword.get(state.modules, module)
  
        used_modules = Map.get(module_info, :used_modules, [])
        used_modules = Enum.uniq([used_module | used_modules])
  
        module_info = Map.put(module_info, :used_modules, used_modules)
        modules = Keyword.put(state.modules, module, module_info)
  
        %{state | modules: modules}
      end)
    end
  
    def has_used?(pid, module, func) do
      Agent.get(pid, fn state ->
        module_info = Keyword.get(state.modules, module)
        used = Map.get(module_info, :used, [])
  
        Enum.find(used, fn x -> x == func end) != nil
      end)
    end
  
    def put_used(pid, module, {_function, _arity} = func) do
      Agent.update(pid, fn state ->
        module_info = Keyword.get(state.modules, module)
  
        used = Map.get(module_info, :used, [])
        used = [func | used]
  
        module_info = Map.put(module_info, :used, used)
        modules = Keyword.put(state.modules, module, module_info)
  
        %{state | modules: modules}
      end)
    end
  
    def put_javascript_module(pid, module, name, path) do
      Agent.update(pid, fn state ->
        js_modules = Map.get(state, :js_modules, [])
        js_modules = [{module, name, path} | js_modules]
        %{state | js_modules: js_modules}
      end)
    end
  
    def put_diagnostic(pid, module, diagnostic) do
      Agent.update(pid, fn state ->
        module_info = Keyword.get(state.modules, module)
  
        if module_info do
          diagnostics = Map.get(module_info, :diagnostics, [])
          diagnostics = [diagnostic | diagnostics]
  
          module_info = Map.put(module_info, :diagnostics, diagnostics)
          modules = Keyword.put(state.modules, module, module_info)
  
          %{state | modules: modules}
        else
          state
        end
      end)
    end
  
    def list_javascript_modules(pid) do
      Agent.get(pid, fn state ->
        state.js_modules
        |> Enum.map(fn {module, _name, _path} ->
          module
        end)
      end)
    end
  
    def js_modules(pid) do
      Agent.get(pid, fn state ->
        state.js_modules
      end)
    end
  
    def is_global_module(pid, module) do
      Agent.get(pid, fn state ->
        result =
          Enum.find(state.js_modules, fn {mod, _name, path} -> mod == module and path == nil end)
  
        if result == nil, do: false, else: true
      end)
    end
  
    def get_global_module_name(pid, module) do
      Agent.get(pid, fn state ->
        result =
          Enum.find(state.js_modules, fn {mod, _name, path} -> mod == module and path == nil end)
  
        if result == nil, do: nil, else: elem(result, 1)
      end)
    end
  
    def remove_unused_functions(pid) do
      Agent.get(pid, fn state ->
        state.compiler_opts.remove_unused_functions
      end)
    end
  
    def get_js_module_name(pid, module) do
      Agent.get(pid, fn state ->
        {_, name, _} =
          state.js_modules
          |> Enum.find(fn {m, _, _} -> module == m end)
  
        name
      end)
    end
  
    def list_modules(pid) do
      Agent.get(pid, fn state ->
        state.modules
      end)
    end
  
    def get_in_memory_module(pid, module) do
      Agent.get(pid, fn state ->
        Keyword.get(state.in_memory_modules, module)
      end)
    end
  
    def get_in_memory_modules(pid) do
      Agent.get(pid, fn state ->
        state.in_memory_modules
      end)
    end
  
    def put_in_memory_module(pid, module, beam) do
      Agent.update(pid, fn state ->
        in_memory_modules = Map.get(state, :in_memory_modules, [])
        in_memory_modules = Keyword.put(in_memory_modules, module, beam)
        %{state | in_memory_modules: in_memory_modules}
      end)
    end
  end