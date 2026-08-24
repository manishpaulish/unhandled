#!/usr/bin/env python3
"""Drive the language server through a real session and check what comes back.

A server that compiles but never answers is worse than no server, so this
speaks the actual protocol over stdin/stdout rather than calling into the
library.
"""
import json, os, subprocess, sys, tempfile, shutil, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
SERVER = os.environ.get("UNHANDLED_LSP", str(ROOT / "_build/default/bin/unhandled_lsp.exe"))
RUNNER = os.environ.get("OCAMLRUN", "")
OCAMLC = os.environ.get("OCAMLC", "ocamlc")

def frame(obj):
    body = json.dumps(obj).encode()
    return b"Content-Length: %d\r\n\r\n%s" % (len(body), body)

def read_messages(data):
    out, i = [], 0
    while True:
        j = data.find(b"\r\n\r\n", i)
        if j < 0: break
        header = data[i:j].decode(errors="replace")
        length = None
        for line in header.split("\r\n"):
            if line.lower().startswith("content-length:"):
                length = int(line.split(":", 1)[1].strip())
        if length is None: break
        body = data[j+4 : j+4+length]
        try: out.append(json.loads(body))
        except Exception: pass
        i = j + 4 + length
    return out

def main():
    work = tempfile.mkdtemp()
    try:
        proj = pathlib.Path(work) / "proj"
        (proj / "_build").mkdir(parents=True)
        (proj / "dune-project").write_text("(lang dune 3.0)\n")
        (proj / "metrics.ml").write_text(
            "type _ Effect.t += Emit : string -> unit Effect.t\n"
            "let log msg    = Effect.perform (Emit msg)\n"
            "let process xs = List.iter log xs\n"
            "let ()         = process [\"a\"]\n")
        subprocess.run([OCAMLC, "-bin-annot", "-c", "metrics.ml"],
                       cwd=proj, capture_output=True)
        for ext in (".cmt", ".cmi", ".cmo"):
            src = proj / ("metrics" + ext)
            if src.exists(): shutil.move(str(src), str(proj / "_build" / ("metrics" + ext)))

        uri = "file://" + str(proj / "metrics.ml")
        session = b"".join([
            frame({"jsonrpc":"2.0","id":1,"method":"initialize",
                   "params":{"rootUri":"file://"+str(proj),"capabilities":{}}}),
            frame({"jsonrpc":"2.0","method":"initialized","params":{}}),
            frame({"jsonrpc":"2.0","method":"textDocument/didOpen",
                   "params":{"textDocument":{"uri":uri,"languageId":"ocaml",
                                             "version":1,"text":""}}}),
            frame({"jsonrpc":"2.0","id":2,"method":"shutdown","params":{}}),
            frame({"jsonrpc":"2.0","method":"exit","params":{}}),
        ])
        cmd = ([RUNNER] if RUNNER else []) + [SERVER]
        p = subprocess.run(cmd, input=session, capture_output=True, timeout=60)
        msgs = read_messages(p.stdout)

        init = [m for m in msgs if m.get("id") == 1]
        diags = [m for m in msgs if m.get("method") == "textDocument/publishDiagnostics"]
        ok = True

        if not init or "capabilities" not in init[0].get("result", {}):
            print("FAIL: no initialize result"); ok = False
        else:
            print("PASS: initialize returned capabilities")

        found = None
        for d in diags:
            for item in d["params"]["diagnostics"]:
                if "Emit" in item.get("message", ""): found = (d, item)
        if not found:
            print("FAIL: no diagnostic mentioning Emit")
            print("  messages:", json.dumps(msgs)[:600]); ok = False
        else:
            d, item = found
            print(f"PASS: diagnostic published -> {item['message']}")
            print(f"      code={item.get('code')} severity={item.get('severity')} "
                  f"line={item['range']['start']['line']}")
            rel = item.get("relatedInformation", [])
            if len(rel) < 2:
                print(f"FAIL: blame path has {len(rel)} step(s), expected the chain"); ok = False
            else:
                print(f"PASS: blame path carried as {len(rel)} relatedInformation entries")
                for r in rel:
                    print(f"      - {r['message']}")
        if p.returncode != 0:
            print(f"FAIL: server exited {p.returncode}"); ok = False
        else:
            print("PASS: server shut down cleanly")
        return 0 if ok else 1
    finally:
        shutil.rmtree(work, ignore_errors=True)

sys.exit(main())
