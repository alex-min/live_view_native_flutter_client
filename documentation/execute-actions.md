# How to execute actions on the client

Properties on the server-side which execute actions like phx-click, live-patch or switchTheme are defined in the client as "Execs".

## Triggers

An exec attribute carries a JSON payload: a list of `[name, arguments]` pairs.

- `phx-click` fires its execs when the widget is tapped.
- `phx-on-mount` fires its execs once when the element is inserted into the
  widget tree. It does not re-fire when unrelated assigns change the page, and
  fires again if the element is removed and re-added (e.g. an if/else swap)
  or after a page change.

```xml
<Text phx-click='[["goBack"]]'>Back</Text>
<Text phx-on-mount='[["speak", {"text": "xin chào", "lang": "vi-VN"}]]'>
  Replay pronunciation
</Text>
```

## speak

Built-in text-to-speech exec. Speaks `text` in the `lang` locale
(e.g. `vi-VN`), falling back to the language prefix (`vi`) then to the engine
default voice when the exact locale is unavailable. Any in-flight speech is
cancelled first, so rapid successive calls never overlap. Empty text is a
no-op.

[....Add more here...]