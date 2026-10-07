# Responsive native canvases

`ScaledBox` renders one child on a fixed logical canvas, then scales it to the
available width while keeping the width/height ratio. Author `Positioned`
coordinates in logical units. `borderRadius` clips the complete canvas in those
same units. Its default dimensions are 100 × 100.

```xml
<ScaledBox width="966" height="1466" borderRadius="48">
  <Stack>
    <Positioned top="100" left="150" width="600" height="500">
      <FittedBox><Text style="fontSize: 500">Variable length text</Text></FittedBox>
    </Positioned>
  </Stack>
</ScaledBox>
```

`FittedBox` shrinks its child when necessary. It does not truncate text or enlarge
a child that already fits. It can be used independently of `ScaledBox`.

A `ScaledBox` can optionally load fonts using a JSON `fonts` attribute mapping
family names to URLs. Relative URLs resolve against the connected server. The
client loads each family/URL once and displays fallback text while loading;
a failed request leaves fallback text usable. Use `style="fontFamily: ..."`
on the canvas to set its default, or a `Text` style to override it.
Font files belong to the server/application, not to this client package.

`FlipCard` can be placed on a scaled canvas. Supply `flipped` and `onFlip` when
the server owns the state. Omit both for local browsing: unrelated server patches
do not reset the selected face. A new card mount starts on its front.

Shared native components may return safe markup fragments from slots. The client
parses these fragments as widgets, while escaped user text remains text. Stack
flattens dynamic Positioned children so they receive Stack parent data directly.
