<p align="right"><b>🇺🇸 English</b> | <a href="README.md">🇯🇵 日本語</a></p>

<h1 align="center">
  <img src="shell/assets/branding/mugen-shell_logo.png" width="200" alt="mugen-shell logo" /><br/>
  mugen-shell
</h1>

<p align="center"><i>A 夢幻 shell, built on Quickshell + Hyprland.</i></p>

https://github.com/user-attachments/assets/bb69bbe1-e069-4ca7-a48d-6ac7036e9d77

My dotfiles for a Hyprland + Quickshell desktop, packaged so they can be installed from Arch packages or a Nix flake.

---

## Features

- **App launcher**: genres, favorites and your own groups
- **Calendar**: a notification when an event is due
- **Timer**: time left shown in the bar
- **Weather**: no API key, location found automatically
- **Music**: controls for what's playing, with album art
- **Clipboard**: searchable history that keeps images too
- **Notifications**: do not disturb, click to jump to the sending app
- **Screenshots**: region, window or full screen, plus a gallery
- **Wallpapers and colors**: image and video wallpapers and a slideshow, with their colors carried into your apps
- **Light / dark**: GTK apps switch along
- **Lock screen**: clock and weather, and an animation that moves as you type
- **System controls**: audio, brightness, WiFi, Bluetooth, IME and more
- **Keyboard**: open and drive the panels with keybindings
- **Customization**: change the bar's color and shape, transparency, animation speed and more in the Settings window
- **Yura**: an AI assistant you can talk to from the bar or a chat panel

Each one is described in [FEATURES.en.md](FEATURES.en.md).

---

## Yura

An assistant for the small things on your desktop. Ask it to work mugen-shell for you: volume, timers, checking your schedule and more. You reach it from the input row in the bar or the chat panel.

- Models: local models through Ollama, Claude, Gemini, any OpenAI-compatible API
- Desktop control: "set volume to 30" or "start a 5 minute timer" changes the volume or starts the timer
- External MCP servers are supported; by default, external writes are held for approval

Configuration is in [SETUP.en.md](SETUP.en.md#configuring-mugen-ai).

---

## Installation

The steps are in [SETUP.en.md](SETUP.en.md).

To try it without installing, use the demo VM. The user name and password are both `mugen` (the same password unlocks the screen).

```sh
nix build "github:tmy7533018/mugen-shell#nixosConfigurations.vm.config.system.build.vm" && ./result/bin/run-mugen-vm-vm
```

---

## Credits

mugen-shell stands on [Hyprland](https://hypr.land/), [Quickshell](https://quickshell.org/), and many other projects. The full list is in [SETUP.en.md → Credits](SETUP.en.md#credits).

---

## License

MIT License
