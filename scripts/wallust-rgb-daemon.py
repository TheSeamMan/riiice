#!/usr/bin/env python3
import time, json, math, random
from pathlib import Path
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

HOME = Path.home()
COLORS_FILE = HOME / "rice/shell-qs/colors.json"
MODE_FILE = Path("/tmp/shellby-rgb.mode")

# Master Brightness Scale (0.0 to 1.0) -> 0.38 keeps keys warm, cozy, and never blinding!
MASTER_BRI = 0.38

def hex_to_rgb(h, bri=MASTER_BRI):
    h = h.lstrip("#")
    if len(h) != 6:
        return (int(189 * bri), int(147 * bri), int(249 * bri))
    return (
        int(int(h[0:2], 16) * bri),
        int(int(h[2:4], 16) * bri),
        int(int(h[4:6], 16) * bri),
    )

def lerp_rgb(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t),
    )

def scale_rgb(c, factor):
    factor = max(0.0, min(1.5, factor))
    return (
        min(255, int(c[0] * factor)),
        min(255, int(c[1] * factor)),
        min(255, int(c[2] * factor)),
    )

def load_palette():
    try:
        data = json.loads(COLORS_FILE.read_text())
        raw = [hex_to_rgb(data.get(k, "#bd93f9"))
               for k in ["c1", "c2", "c3", "c4", "c5", "c6", "c9", "c10", "c11", "c12", "c13", "c14"]]
        distinct = []
        for c in raw:
            if all(abs(c[0]-d[0]) + abs(c[1]-d[1]) + abs(c[2]-d[2]) > 35 for d in distinct):
                distinct.append(c)
        return distinct if len(distinct) >= 3 else raw[:6]
    except Exception:
        return [(90, 20, 45), (20, 95, 60), (95, 80, 20), (20, 75, 100), (75, 35, 105)]

def get_mode():
    if MODE_FILE.exists():
        m = MODE_FILE.read_text().strip().lower()
        if m in ("sparkle", "wave", "rave", "static", "off"):
            return m
    return "sparkle"

def get_unique_devices(cli):
    # CRITICAL FIX: MSI GE68HX exposes duplicate Keyboard (0 & 2) and Lightbar (1 & 3) interfaces!
    # Talking to both simultaneously causes hardware packet collisions and frantic flashing.
    seen_names = set()
    unique = []
    for dev in cli.devices:
        if dev.name not in seen_names and len(dev.leds) > 0:
            seen_names.add(dev.name)
            # Pick the software-controllable mode (Direct / Custom / Static)
            mode_names = {m.name.lower(): m.name for m in dev.modes}
            for target in ("direct", "custom", "per key", "static"):
                if target in mode_names:
                    try:
                        dev.set_mode(mode_names[target])
                    except Exception:
                        pass
                    break
            unique.append(dev)
    return unique

def connect_ready():
    while True:
        try:
            cli = OpenRGBClient("127.0.0.1", 6742, "ShellbyWallustRGB")
            if len(cli.devices) > 0:
                return cli, get_unique_devices(cli)
        except Exception:
            pass
        time.sleep(1.5)

def main():
    cli, devices = connect_ready()
    pal = load_palette()
    last_mtime = 0
    last_static_sig = ""
    tick = 0.0
    sparkles = {}

    while True:
        try:
            if COLORS_FILE.exists():
                mt = COLORS_FILE.stat().st_mtime
                if mt != last_mtime:
                    last_mtime = mt
                    pal = load_palette()
                    last_static_sig = ""

            mode = get_mode()
            n_pal = len(pal)

            # Static / Off only send ONE packet when selected
            if mode in ("static", "off"):
                sig = f"{mode}:{last_mtime}"
                if sig != last_static_sig:
                    for d_idx, dev in enumerate(devices):
                        if mode == "off":
                            dev.set_color(RGBColor(0, 0, 0), fast=False)
                        else:
                            # Soft, cozy solid Wallust color (Keyboard = primary accent, Lightbar = secondary accent)
                            c = pal[(d_idx + 2) % n_pal]
                            dev.set_color(RGBColor(*c), fast=False)
                    last_static_sig = sig
                time.sleep(0.3)
                continue

            last_static_sig = ""

            for d_idx, dev in enumerate(devices):
                n_leds = len(dev.leds)
                if d_idx not in sparkles or len(sparkles[d_idx]) != n_leds:
                    sparkles[d_idx] = [[0.0, pal[0]] for _ in range(n_leds)]

                sp_list = sparkles[d_idx]
                colors_out = []

                if mode == "sparkle":
                    # Gentle, slow fireflies over a warm 25% base glow
                    if random.random() < 0.22:
                        k = random.randrange(n_leds)
                        if sp_list[k][0] < 0.1:
                            sp_list[k] = [1.0, random.choice(pal)]

                    base_bg = scale_rgb(pal[0], 0.28)
                    for i in range(n_leds):
                        heat, col = sp_list[i]
                        if heat > 0.03:
                            # Smooth sine fade in & out (no harsh white flash!)
                            glow = math.sin(heat * math.pi)
                            c = lerp_rgb(base_bg, scale_rgb(col, 1.35), glow)
                            sp_list[i][0] = max(0.0, heat - 0.035)
                            colors_out.append(RGBColor(*c))
                        else:
                            colors_out.append(RGBColor(*base_bg))

                elif mode == "wave":
                    # Slow, dreamy aurora drift across the keyboard & lightbar
                    for i in range(n_leds):
                        pos = (i / max(8.0, n_leds / 2.0) - tick * 0.18 + d_idx * 0.5) % n_pal
                        idx1 = int(math.floor(pos)) % n_pal
                        idx2 = (idx1 + 1) % n_pal
                        frac = pos - math.floor(pos)
                        smooth_t = (1.0 - math.cos(frac * math.pi)) * 0.5
                        c = lerp_rgb(pal[idx1], pal[idx2], smooth_t)
                        colors_out.append(RGBColor(*c))

                elif mode == "rave":
                    # Upbeat (but comfortable!) multi-color party bounce
                    for i in range(n_leds):
                        pos = (i * 0.18 + tick * 0.65) % n_pal
                        idx1 = int(math.floor(pos)) % n_pal
                        idx2 = (idx1 + 1) % n_pal
                        frac = pos - math.floor(pos)
                        base = lerp_rgb(pal[idx1], pal[idx2], frac)
                        pulse = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(tick * 2.2 + i * 0.45))
                        c = scale_rgb(base, pulse * 1.2)
                        colors_out.append(RGBColor(*c))

                dev.set_colors(colors_out, fast=False)

            tick += 0.08
            time.sleep(0.09)

        except Exception:
            time.sleep(1.5)
            cli, devices = connect_ready()

if __name__ == "__main__":
    main()
