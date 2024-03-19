# How the state lifecycle works

Components are defined in ```lib/live_view/ui/components/``` and all inherit the class ```LiveStateWidget```.

This class is responsible for handling all the state changes and refresh widgets if necessary.


## Changing pages & Wiping states

When changing pages, the existing state is wiped. Any changes which was done a result of a user action is reset.

This is done to avoid "phantom states", where the UI would carry the previous state into the next page.

This client is only supporting a single page at a time at the moment so this is necessary.