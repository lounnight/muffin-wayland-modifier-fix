# Cinnamon on Wayland: Shift / Ctrl / Alt not working

## Cause

This is a known bug in **muffin**, Cinnamon's compositor, not in your keyboard
or its layout.

On the Wayland session muffin treats modifier-only key presses as its own
window-manager shortcuts and swallows the `wl_keyboard.key` (key-down) event
before it reaches Wayland clients. Clients only receive the matching key-up
event, so:

- Shift/Ctrl/Alt do nothing when pressed alone (games, Ctrl+click, Shift+click,
  Ctrl+scroll, modifier-only shortcuts),
- normal typing and Ctrl+C style shortcuts can still work because the modifier
  *state* is sent.

Upstream issue: <https://github.com/linuxmint/wayland/issues/1>
Upstream fix (merged, not yet in the 6.6.x release branch):
<https://github.com/linuxmint/muffin/commit/068e127c0b6181d1761484e2192604713378273d>

Fedora 44 currently ships muffin 6.6.3, which predates the fix. The fix only
exists in upstream `master` (and in the `leigh123linux/cin_dev` COPR, which
tracks Cinnamon git).

## Option 1 - Quick, no root: use the Cinnamon (X11) session

The X11 session is still installed (`/usr/share/xsessions/cinnamon.desktop`):

1. Log out.
2. On the login screen click the gear/session selector.
3. Pick **Cinnamon** (not "Cinnamon on Wayland (Experimental)").
4. Log in.

Modifiers work normally there.

## Option 2 - Keep Wayland: install a patched muffin

`./build-and-install.sh` downloads the Fedora 44 muffin 6.6.3 source RPM,
applies the upstream fix, builds `muffin-6.6.3-2.fc44`, and installs it.
It asks for your sudo password (build dependencies + package install).

Just run the file
```sh
./build-and-install.sh
```

Then log out and back into the **Cinnamon on Wayland** session (muffin is the
compositor, so a restart is required). Verify with:

```sh
rpm -q muffin      # should print muffin-6.6.3-2.fc44
```

### Revert

```sh
sudo dnf downgrade -y muffin
```

### Notes

- A later official muffin update (6.6.4+) will replace this build. If the
  official package still lacks the fix, re-run the script (adjust `VERSION` /
  `FEDORA_REL` at the top if needed).
- The script only rebuilds muffin; it does not touch Cinnamon itself.
