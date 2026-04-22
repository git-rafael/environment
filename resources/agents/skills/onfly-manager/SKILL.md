---
name: onfly-manager
description: Automate corporate travel tasks on the Onfly platform (app.onfly.com). Use this skill whenever the user mentions Onfly, corporate travel booking, flight search on Onfly, or wants to automate any workflow on app.onfly.com — including searching flights, comparing prices, checking reservations, or managing travel approvals. Also trigger when the user asks to "search flights for a trip" in a corporate travel context.
---

# Onfly Manager

Automate corporate travel operations on the Onfly platform (app.onfly.com) using browser automation.

## Dependencies

This skill requires the `agent-browser` skill for all browser interactions. **Before doing anything else**, invoke the `agent-browser` skill to load its full command reference. All browser commands in this guide (`open`, `snapshot`, `fill`, `click`, `eval`, `screenshot`, etc.) come from agent-browser.

## Before You Start

Onfly is a Vue 3 / Quasar app with custom components that fight standard browser automation. This guide documents every workaround discovered through testing — follow them closely or you'll waste time on approaches that don't work.

## Authentication

Onfly requires login. The session must be established once in headed mode, then reused headless.

### First-time login (human-assisted)

```bash
# 1. Close any existing agent-browser session
agent-browser close

# 2. Open Onfly in headed mode so the user can see and interact
agent-browser --headed --session-name onfly open "https://app.onfly.com/"
agent-browser wait --load networkidle

# 3. Tell the user to log in manually, then wait for confirmation

# 4. After user confirms login, save the session state
agent-browser state save /tmp/onfly-auth.json
```

### Subsequent runs (headless)

```bash
agent-browser close
agent-browser --session-name onfly --state /tmp/onfly-auth.json open "https://app.onfly.com/"
agent-browser wait --load networkidle
```

If the session has expired (you land on `/login` instead of `/v2#/home`), re-run the headed login flow and ask the user to log in again.

## Desktop Viewport (Required)

Onfly renders a mobile layout at default viewport (1280x720) with "swipe-up" panels that are extremely difficult to automate. Always set desktop viewport **before** any interaction:

```bash
agent-browser set viewport 1920 1080
```

The mobile layout uses bottom-sheet style dropdowns for airport selection and a different DOM structure. The desktop layout shows all form fields inline and is far more automatable.

## Flight Search

### Step 1: Navigate to the search page

```bash
agent-browser open "https://app.onfly.com/travel/#/travel/booking/search?type=flights"
agent-browser wait --load networkidle
agent-browser wait 2000  # Vue app needs a moment to hydrate
```

### Step 2: Set origin and destination via Pinia store

**Do NOT try to type into the origin/destination combobox fields.** These are custom Vue/Quasar `<q-select>` components that ignore all standard CDP input methods — `fill`, `type`, `press`, `keyboard inserttext`, and native JS `dispatchEvent` all fail to trigger the component's internal search/selection logic.

The only reliable method is to write directly to the Pinia store that backs the form.

```bash
agent-browser eval --stdin <<'EVALEOF'
(function() {
  const pinia = document.querySelector('#q-app').__vue_app__.config.globalProperties.$pinia;
  const state = pinia.state.value['travel.booking.search'];

  state.flightSearchParams.origin = {
    code: "ORIGIN_CODE",
    name: "ORIGIN_NAME",
    type: "Airport",
    isInternational: false,
    lat: ORIGIN_LAT,
    lng: ORIGIN_LNG,
    city: { name: "ORIGIN_CITY", stateCode: "ORIGIN_STATE", countryCode: "BR" }
  };

  state.flightSearchParams.destination = {
    code: "DEST_CODE",
    name: "DEST_NAME",
    type: "Airport",
    isInternational: false,
    lat: DEST_LAT,
    lng: DEST_LNG,
    city: { name: "DEST_CITY", stateCode: "DEST_STATE", countryCode: "BR" }
  };

  return JSON.stringify({
    origin: state.flightSearchParams.origin.code,
    destination: state.flightSearchParams.destination.code
  });
})()
EVALEOF
```

Replace the placeholders with actual airport data. Common Brazilian airports:

| Code | Name | City | State | Lat | Lng |
|------|------|------|-------|-----|-----|
| SDU | Aeroporto Santos Dumont (SDU) | Rio de Janeiro | RJ | -22.9103 | -43.1645 |
| GIG | Aeroporto Internacional do Galeão (GIG) | Rio de Janeiro | RJ | -22.8090 | -43.2506 |
| CGH | Aeroporto de São Paulo/Congonhas (CGH) | São Paulo | SP | -23.6282 | -46.6570 |
| GRU | Aeroporto Internacional de São Paulo/Guarulhos (GRU) | São Paulo | SP | -23.4356 | -46.4731 |
| BSB | Aeroporto Internacional de Brasília (BSB) | Brasília | DF | -15.8711 | -47.9186 |
| CNF | Aeroporto Internacional de Confins (CNF) | Belo Horizonte | MG | -19.6244 | -43.9719 |
| SSA | Aeroporto Internacional de Salvador (SSA) | Salvador | BA | -12.9086 | -38.3225 |
| REC | Aeroporto Internacional do Recife (REC) | Recife | PE | -8.1264 | -34.9236 |
| POA | Aeroporto Internacional de Porto Alegre (POA) | Porto Alegre | RS | -29.9944 | -51.1714 |
| CWB | Aeroporto Internacional de Curitiba (CWB) | Curitiba | PR | -25.5285 | -49.1758 |

If the user requests an airport not in this table, construct the object with the best available information — the critical fields are `code`, `name`, `type`, `lat`, `lng`, and `city`.

After setting the store, wait briefly for Vue reactivity to update the UI:

```bash
agent-browser wait 1000
```

Take a screenshot to verify the form shows the correct airports before proceeding.

### Step 3: Set trip type

```bash
# Take a snapshot to find the current button refs
agent-browser snapshot -i

# Click "Somente ida" for one-way or "Ida e volta" for round-trip
agent-browser click @REF_SOMENTE_IDA   # or @REF_IDA_E_VOLTA
```

The trip type buttons respond fine to standard `click`.

### Step 4: Set the date

The date input field **does** respond to the `fill` command (unlike the airport comboboxes). Find it by snapshot, then fill directly:

```bash
agent-browser snapshot -i
# Look for: textbox "Data" or textbox "Ida"
agent-browser fill @REF_DATE_FIELD "DD/MM/YYYY"
agent-browser press Enter
```

**Do NOT try to use the calendar picker.** It has 4 unlabeled navigation buttons (`<<`, `<`, `>`, `>>`) that are ambiguous in snapshots, and clicking date cells is unreliable. Direct text input is far more reliable.

For round-trip, there will be a second date field ("Volta") — fill it the same way.

### Step 5: Search

```bash
agent-browser snapshot -i
# Find: button "Buscar"
agent-browser click @REF_BUSCAR
agent-browser wait --load networkidle
agent-browser wait 5000  # Results take time to load from airline APIs
```

### Step 6: Read results

```bash
agent-browser screenshot /tmp/onfly-results.png
```

Read the screenshot to extract flight details. Results typically show:
- Airline and flight number (e.g., "Azul AD4845")
- Departure/arrival times and duration
- Number of stops
- Price per passenger (with breakdown: fare + taxes)
- Fare class (e.g., "AZUL", "LIGHT", "PLUS")

For more flights, scroll down:

```bash
agent-browser scroll down 500
agent-browser screenshot /tmp/onfly-results-2.png
```

The page shows a filter panel on the left with:
- Airline filter (checkboxes)
- Price range slider
- Time range slider
- Duration range slider
- Number of stops

To filter by airline, use `snapshot -i -C` to find the checkbox refs and click them.

## Extracting Structured Data

For programmatic extraction instead of screenshots, use `eval` to read the Pinia store after search completes:

```bash
agent-browser eval --stdin <<'EVALEOF'
(function() {
  const pinia = document.querySelector('#q-app').__vue_app__.config.globalProperties.$pinia;
  const flightStore = pinia.state.value['travel.booking.search.flight'];
  return JSON.stringify(flightStore.metadata, null, 2).substring(0, 5000);
})()
EVALEOF
```

## Common Pitfalls

| Problem | Cause | Solution |
|---------|-------|----------|
| Airport combobox doesn't respond to typing | Vue/Quasar custom component ignores CDP events | Use Pinia store manipulation (Step 2) |
| Form shows mobile layout with bottom sheets | Viewport too small | `agent-browser set viewport 1920 1080` |
| Date picker calendar buttons do unexpected things | 4 ambiguous nav buttons (`<<`,`<`,`>`,`>>`) | Use `fill` on the text input instead |
| Login page appears unexpectedly | Session expired | Re-run headed login flow |
| Search returns no results | Airport data incomplete in Pinia | Ensure `code`, `name`, `type`, `city` are all set |
| Page loads but form is empty | Vue hydration not complete | Add `agent-browser wait 2000` after navigation |

## Example: Full Flight Search

User asks: "Search one-way flights from SDU to GRU on May 1st 2026"

```bash
# Setup
agent-browser close
agent-browser --session-name onfly --state /tmp/onfly-auth.json \
  open "https://app.onfly.com/travel/#/travel/booking/search?type=flights"
agent-browser wait --load networkidle
agent-browser set viewport 1920 1080
agent-browser wait 2000

# Set airports via Pinia
agent-browser eval --stdin <<'EVALEOF'
(function() {
  const pinia = document.querySelector('#q-app').__vue_app__.config.globalProperties.$pinia;
  const state = pinia.state.value['travel.booking.search'];
  state.flightSearchParams.origin = {
    code: "SDU", name: "Aeroporto Santos Dumont (SDU)", type: "Airport",
    isInternational: false, lat: -22.9103, lng: -43.1645,
    city: { name: "Rio de Janeiro", stateCode: "RJ", countryCode: "BR" }
  };
  state.flightSearchParams.destination = {
    code: "GRU", name: "Aeroporto Internacional de São Paulo/Guarulhos (GRU)", type: "Airport",
    isInternational: false, lat: -23.4356, lng: -46.4731,
    city: { name: "São Paulo", stateCode: "SP", countryCode: "BR" }
  };
  return JSON.stringify({ origin: "SDU", destination: "GRU" });
})()
EVALEOF

agent-browser wait 1000

# Set one-way trip
agent-browser snapshot -i
# Click the "Somente ida" button (find ref from snapshot)
agent-browser click @REF_SOMENTE_IDA

# Set date
agent-browser snapshot -i
# Find the date textbox and fill it
agent-browser fill @REF_DATE "01/05/2026"
agent-browser press Enter

# Search
agent-browser snapshot -i
agent-browser click @REF_BUSCAR
agent-browser wait --load networkidle
agent-browser wait 5000

# Read results
agent-browser screenshot /tmp/onfly-results.png
# Parse the screenshot and report the cheapest flights to the user
```

After reading the results screenshot, present them to the user in a clear table format with airline, flight number, times, duration, and price — sorted by price (cheapest first).
