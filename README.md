# rlsp

The client side of the Language Server Protocol, for
[raz](https://github.com/ldiaz94/raz) programs: the framing of
messages, file URIs and UTF-16 columns, and one language server run
over its standard input and output. It is what dwa's editor talks to
servers with, taken out so another program can.

| Module | What |
|---|---|
| `LspWire` | `Content-Length` envelopes: `feed` bytes in any pieces, `take` whole bodies, `frame` one to send |
| `LspText` | local file URIs (`uri`, `path`) and UTF-16 positions in one line (`units`, `column`) |
| `LspServer` | one server process: `start` (queues `initialize`), `request`, `next` (at most one pipe operation, never waits with 0), `shutdown`, `done` |

`LspServer` is a state machine for a loop that also serves a user:
it never blocks, bounds its queue, answers the server's own requests
with an error, and times out a server that does not answer. It
advertises UTF-16 positions, pulled and pushed diagnostics, and
completion without snippets. Replies are parsed in place by rjson's
`Json`, so what a caller keeps it copies before the next `next`.

## Get it

Needs raz 0.25 and [rjson](../rjson) (`Json`).

    make check       # each module's main, then a session with a test peer
    make check-lsp   # the session with typescript-language-server (TSSERVER=path/to/tsserver.js)
    make fmt
    make install     # the modules in ~/.raz/lib, to import with no -I

A program imports `LspServer`, `LspWire`, `LspText`; the names are flat,
so a program must not name a module of its own the same. `test/LspSession.raz`
is a complete use: start, open a document, ask a definition, change,
close, shut down.

## Correctness

`LspWire` and `LspText` are tested by their own `main`: frames split at
every byte, malformed and over-long headers, surrogate pairs, URI escapes.
`test/LspPeer.raz` is a strict peer that checks the handshake, unsaved
text and shutdown, and fails on a hang or a bad message; `test/LspSession.raz`
runs `LspServer` against it, or against the real server with `--typescript`.

## Left out

Choosing or finding a server, document ownership and versions, restarts,
any editor type (a line is passed as bytes), remote URIs, encodings other
than UTF-16, and every LSP method: a caller builds its own JSON params.

## Could raz-lsp and concha-lsp adopt it?

Both are language servers, so they use the other side of the protocol;
`LspServer` (a client) is no use to them.

- `Lwire.raz` in both is byte for byte `LspWire` with another name: a
  change of import, nothing else.
- `Ltext.raz`'s `uriPath` resembles `LspText.path`; its `column` and
  `offset` take a `utf8` flag (position encoding negotiated) that
  `LspText` lacks. Adopting `LspText` means checking `uriPath`'s strictness
  against it and adding a `utf8` choice to `units` and `column`. Their
  document stores and line splitting stay theirs.

Neither has been changed.

## Licence

ISC.
