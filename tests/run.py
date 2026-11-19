"""Run pure Lua tests with Lua 5.1 and LuaJIT (pip install lupa). No WoW required."""
from pathlib import Path
import importlib
import os

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
for module in ("lupa.lua51", "lupa.luajit21"):
    lua = importlib.import_module(module).LuaRuntime(unpack_returned_tuples=True)
    check = lua.eval("function(source,name) local f,e=loadstring(source,name); assert(f,e) end")
    for path in (ROOT / "Spaghetti").glob("*.lua"):
        check(path.read_text(encoding="utf-8"), str(path))
    lua.execute((ROOT / "tests" / "logic.lua").read_text(encoding="utf-8"))
    lua = importlib.import_module(module).LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tests" / "v2.lua").read_text(encoding="utf-8"))
    lua = importlib.import_module(module).LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tests" / "v3.lua").read_text(encoding="utf-8"))
    lua = importlib.import_module(module).LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tests" / "v031.lua").read_text(encoding="utf-8"))
    lua = importlib.import_module(module).LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tests" / "ui_smoke.lua").read_text(encoding="utf-8"))
    print(f"PASS {module}: source syntax, logic suite and mocked UI lifecycle", flush=True)
