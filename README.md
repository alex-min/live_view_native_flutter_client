# Live View Native Flutter Client

A Flutter client for LiveView native

⚠⚠ This client is a tech preview only, it's not ready to be usable for your own project ⚠⚠ 

## Getting Started

- [Install Flutter](https://docs.flutter.dev/get-started/install)
- clone this repository in a folder
- clone [the demo live view flutter server](https://github.com/alex-min/live_view_flutter_demo)
- Use "flutter run" to run the client
- You can modify the live view url in lib/main.dart, by default it uses localhost:4000 and 10.0.0.2:4000 for the android emulator

## What is there already?

- Some basic components are partially supported (Container, TextButton, Icon, AppBar ...)
- Basic styling (padding, margin and background)
- Basic forms (validation & submit)
- Dynamic attributes & replacement
- Conditional components
- Material Icons

## What is missing?

- Documentation
- Navigation
- A full API support of all the components
- Themes
- Modclasses (same as live view swift native)
- Hooks
- Animations
- Better live reloading
- ...

As you see on this list, the client isn't fully usable for a real app yet.

## Philosophy

- The Flutter client should support absolutely everything to make a real app
- Users of this client should almost never dive into the flutter code, the client should be as complete and extensive as possible. 
- The client should be extendable in the future and available as a flutter package


## What does the code looks like?

This is an example of the code on the server:

```elixir
  @impl true
  def render(%{platform_id: :flutterui} = assigns) do
    # This UI renders on flutter
    ~FLUTTERUI"""
    <Scaffold>
      <AppBar>
        <title>
          <Text>Hello Native</Text>
        </title>
        <leading>
        <Icon size="20" name="menu" />
        </leading>
      </AppBar>
      <Container padding={10 + @counter} decoration={bg_color(@counter)}>
        <Form phx-change="validate" phx-submit="save">
          <ListView>
            <Container decoration="background: white">
              <TextField decoration="fillColor: white; filled: true" name="myfield" value={"Current margin #{@counter}"}>
                <icon>
                  <Container decoration="background" padding="10">
                    <Icon size="20" name="key" />
                  </Container>
                </icon>
              </TextField>
            </Container>
            <Container decoration="background: white" margin="10 0 0 0">
              <TextField name="myfield2" decoration="fillColor: white; filled: true" value="Second field" />
            </Container>
            <Center>
              <Text style="textTheme: headlineMedium; fontWeight: bold; fontStyle: italic">
                Current Margin: <%= @counter %>
              </Text>
            </Center>
            <%= if rem(@counter, 2) == 1 do %>
              <Center><Text>the current margin is odd</Text></Center>
            <% else %>
              <Center><Text>the current margin is even</Text></Center>
            <% end %>
            <TextButton phx-click="inc">
              <Text>
                Increment margin
              </Text>
            </TextButton>
            <Container margin="10 0 0 0">
              <TextButton type="submit">
                <Text>
                  Submit form
                </Text>
              </TextButton>
            </Container>
            <Text><%= @form_field %></Text>
          </ListView>
        </Form>
      </Container>
    </Scaffold>
    """
  end
```