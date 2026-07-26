# SHADE — Solar Harvest Assessment & Data Evaluator

Android app for the SHADE solar assessment system. It connects to a self-powered ESP32 sensor node
over WiFi, streams live irradiance readings, and projects what a full-scale solar installation would
generate and save at that specific location.

Solar resource maps tell you how much sun a region gets on average. They don't tell you how much sun
*your* roof gets, once mountains, buildings, and trees are in the way. SHADE is a self-sufficient
node you leave in place across all four seasons to measure that directly — and this app is how you
read it.

**ECE 499: Design Project 2 — University of Victoria, Group 16 (2025)**

---

## Table of Contents

- [System Overview](#system-overview)
- [Screens](#screens)
- [How the Projection Works](#how-the-projection-works)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Connecting to a SHADE Node](#connecting-to-a-shade-node)
- [API Contract](#api-contract)
- [Developing Without Hardware](#developing-without-hardware)
- [Building for Release](#building-for-release)
- [Project Structure](#project-structure)
- [Known Limitations](#known-limitations)
- [Roadmap](#roadmap)
- [Team](#team)
- [License](#license)

---

## System Overview

SHADE is three layers: hardware, firmware, and this app. There is **no cloud infrastructure and no
router required** — the ESP32 broadcasts its own WiFi access point and serves data directly to the
phone. A node dropped in a field with no connectivity works exactly the same as one on a rooftop.

```
   ┌──────────────────────────────────────┐
   │  SHADE Node                          │
   │                                      │
   │   Solar panel ──┬──→ voltage divider │
   │                 │         ↓ GPIO35   │
   │                 │      [ ESP32 ]     │
   │                 │         │          │
   │                 └──→ LiPo charger    │   self-powered:
   │                      → 18650 cell    │   the panel it measures
   │                                      │   also charges the battery
   │   SoftAP "ESP-Solar"                 │
   │   HTTP server :80  GET /solar        │
   └──────────────┬───────────────────────┘
                  │  JSON, polled at 1 Hz
                  ↓
   ┌──────────────────────────────────────┐
   │  This app (Flutter, Android)         │
   │                                      │
   │   solar_index → projected power      │
   │       ↓                              │
   │   sqflite (local history)            │
   │       ↓                              │
   │   fl_chart (live + historical view)  │
   └──────────────────────────────────────┘
```

The node is self-sustaining by design: the same panel being measured charges the onboard 18650 LiPo,
so the device can be deployed for a full year without intervention. That's the gap it fills —
handheld irradiance meters give you a momentary reading, and battery-powered loggers eventually die.

---

## Screens

### Home — Live

Polls the node once per second and displays:

- **Solar Index** — normalised irradiance reading from the node (0–1)
- **Projected Power** — what a full installation would produce right now, given your settings
- **Money Saved** — running savings at BC Hydro rates
- A continuously updating line chart

### Home — History

Reads back the local SQLite log with **Daily / Weekly / Monthly / Yearly** range toggles, charting
accumulated savings over time. This is the payoff view — the whole point of leaving a node deployed
for a season is this curve.

### Settings — System Setup

Configures the projection model:

| Setting | Notes |
| --- | --- |
| Total Roof Area (m²) | Area available for the hypothetical installation |
| Panel Type | Preset selection (e.g. 300 W panel) |
| Panel Efficiency | 0.0–1.0, under Advanced Settings |
| Enable MPPT | Applies the maximum-power-point correction factor |
| Estimated System Power | Computed output, shown live as you edit |

### Network Diagnostics

Enter the node's IP address and tap **Ping ESP**. Confirms the phone can see the ESP32's server
before you go hunting for bugs elsewhere — worth its weight during field testing.

---

## How the Projection Works

The node's panel is small. The installation you're considering is not. The app scales between them.

**1. Measured power** from the node's panel:

```
P = I·V
```

**2. Scale to the target installation** by relative efficiency and area:

```
P_future = P_SHADE · (η_future / η_SHADE) · (A_future / A_SHADE)
```

**3. Apply the MPPT correction factor**, since the node's panel isn't operating at its maximum power
point but a real installation with a maximum power point tracker would be:

```
correction = P_max(SHADE) / P_measured(SHADE)
```

The caveat worth stating plainly: step 3 only holds if the real installation actually uses an MPPT
controller. That's what the **Enable MPPT** toggle is for.

Savings are then computed from projected generation against BC Hydro electricity pricing.

---

## Tech Stack

| | |
| --- | --- |
| Framework | Flutter |
| Language | Dart (SDK `^3.8.1`) |
| Target | Android (see [Known Limitations](#known-limitations)) |
| Node firmware | C++ / Arduino on ESP32 |

| Package | Version | Role |
| --- | --- | --- |
| `http` | `^0.13.6` | GET requests to the node's `/solar` endpoint |
| `sqflite` | `^2.3.0` | Local SQLite store for logged readings |
| `path_provider` | `^2.1.0` | Resolves the on-device database path |
| `path` | `^1.8.0` | Path joining |
| `fl_chart` | `^0.63.0` | Live and historical charts |
| `shared_preferences` | `^2.2.2` | Persists the system-setup settings |
| `intl` | `^0.18.1` | Date and currency formatting |
| `flutter_lints` | `^5.0.0` | Lint rules (dev) |

> **Note:** `http`, `fl_chart`, and `intl` are each a major version or more behind current, while the
> SDK constraint and `flutter_lints` are up to date. Run `flutter pub outdated` before resuming work
> — `http` 1.x and `fl_chart` 1.x both carry breaking changes.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart `^3.8.1`
- Android Studio, plus an emulator or a physical Android device
- A SHADE node — or see [Developing Without Hardware](#developing-without-hardware)

```bash
flutter doctor        # verify toolchain
```

### Run

```bash
git clone https://github.com/BenDNKennedy/SHADE_FLUTTER_APP.git
cd SHADE_FLUTTER_APP

flutter pub get
flutter run
```

The app was primarily developed against an emulator, but release APKs have been built and verified
on real Android hardware talking to a live node.

---

## Connecting to a SHADE Node

The ESP32 runs in **access point mode** — it creates its own network rather than joining an existing
one. Your phone connects to the node directly.

1. Power on the node: switch **S2** for the ESP32, **S1** for the solar panel.
2. On your phone, join the WiFi network **`ESP-Solar`** (password `s3cretPW`).
3. Open **Network Diagnostics** in the app and enter the node's AP address — **`192.168.4.1`** by
   default. The exact address is printed to the ESP32's serial monitor at boot.
4. Tap **Ping ESP**. On success, the Live tab begins streaming at 1 Hz.

Because the node is its own access point, your phone has no internet connection while connected to
it. This is expected — nothing in the app requires one.

> **Security:** the SSID and password are hardcoded in the firmware and appear in the published
> project report, so treat them as public. Change them and load them from a gitignored config header
> before any deployment beyond a demo.

---

## API Contract

The node exposes a single endpoint:

```http
GET http://192.168.4.1/solar
```

```json
{ "solar_index": 0.680 }
```

| | |
| --- | --- |
| Default address | `192.168.4.1` (SoftAP) |
| Port | 80 |
| Refresh rate | 1 Hz |
| ADC pin | GPIO35 (ADC1_CH7) |
| ADC resolution | 12-bit, 0–4095 |
| Reference voltage | 3.3 V |
| Response precision | 3 decimal places |

`solar_index` is the raw ADC reading normalised against full scale (`adcRaw / 4095`) — near 0 in
darkness, near 1 in full sun.

---

## Developing Without Hardware

Any server satisfying the contract above will drive the app. To iterate on the UI without a node:

```python
# fake_node.py — python3 fake_node.py
import json, math, time
from http.server import BaseHTTPRequestHandler, HTTPServer

class Node(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/solar":
            self.send_error(404); return
        # smooth day-like curve so the charts have something to draw
        idx = round((math.sin(time.time() / 20) + 1) / 2, 3)
        body = json.dumps({"solar_index": idx}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass

HTTPServer(("0.0.0.0", 80), Node).serve_forever()
```

Run it on your development machine and point Network Diagnostics at that machine's LAN IP. On the
Android emulator, the host is reachable at `10.0.2.2`.

---

## Building for Release

```bash
flutter build apk --release          # APK
flutter build appbundle --release    # Play Store bundle
```

---

## Project Structure

```
SHADE_FLUTTER_APP/
├── lib/                    # Dart source — screens, HTTP client, database, models
├── android/                # Android platform project
├── ios/                    # iOS platform project (scaffolded, not validated)
├── test/                   # Tests
├── pubspec.yaml            # Dependencies and metadata
└── analysis_options.yaml   # Lint configuration
```

---

## Known Limitations

- **Android only.** An `ios/` directory exists from the Flutter scaffold, but the app was only ever
  built and tested on Android devices and emulators. Treat iOS as unverified.
- **One node at a time.** The app talks to a single ESP32. Accurately characterising partial shading
  really wants several nodes reporting simultaneously.
- **No shading geometry.** With one measurement point there's no way to model how shade moves across
  an array through the day; the projection scales a single reading by area and efficiency.
- **Savings assume BC Hydro pricing**, which is hardcoded rather than configurable.
- **2.4 GHz range.** Inherited from the ESP32's WiFi — walls and distance attenuate it, which matters
  when the node is outdoors and you're not.
- **No internet while connected.** A consequence of AP mode; the phone is on the node's network.

---

## Roadmap

1. **Multi-node support.** The highest-value extension: several nodes as points in a sensor array,
   with a hub coordinating them, enabling real shading-geometry modelling and panel layout
   optimisation.
2. **Cross-platform.** iOS, macOS, Windows, and Linux, so users aren't required to own an Android
   device.
3. **Configurable electricity pricing** instead of hardcoded BC Hydro rates.
4. **Sub-GHz radio** in place of 2.4 GHz, for better range and lower power draw given how little data
   is actually transmitted.
5. **Dependency upgrades** — `http` and `fl_chart` to current majors.

---

## Team

Group 16 · Faculty supervisor: Dr. Mihai Sima

| | |
| --- | --- |
| **Ben Kennedy** | Flutter app (UI and backend), ESP32 firmware, software repository management |
| **Dylan Davis** | Flutter app (UI and backend), ESP32 firmware |
| **Chase Westlake** | Schematic design, component selection, PCB review, assembly, budget |
| **Kaden Taylor** | Hardware selection, PCB layout and routing, assembly and testing, 3D-printed enclosures |
| **Philip Shuck** | Solar panel sizing and scaling, MPPT calculations, scope management, project website |

---

## License

Developed as coursework for ECE 499 at the University of Victoria. No license file is currently
included, so all rights are reserved by default — add one if you intend the code to be reusable.
