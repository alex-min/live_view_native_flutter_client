# Widgets

Widgets are defined in ```lib/live_view/ui/components/``` and all inherit the class ```LiveStateWidget```.

# Widget child

In Flutter, components can accept either a single child or multiple children but not both.
How the client reconciles this is to add a ```Column``` widget if needed to behave more like HTML.

Raw text elements in the xml payload are transformed into a basic Flutter ```Text``` widget.

Those two buttons are equivalent:

```xml
<ElevatedButton>Click me</ElevatedButton>
<ElevatedButton><Text>Click me</Text></ElevatedButton>
```

And those two buttons are exactly rendered the same way as well:

```xml
<ElevatedButton>
    <Column>
        <Text>Click</Text>
        <Text> me</Text>
    </Column>
</ElevatedButton>

<ElevatedButton>
    <Text>Click</Text>
    <Text> me</Text>
</ElevatedButton>
```