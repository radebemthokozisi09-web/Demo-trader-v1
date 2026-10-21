# Demo-trader-v1
Demo trader robot 
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#07111f">
  <title>DEMO TRADER</title>

  <style>
    * { box-sizing: border-box; }

    body {
      margin: 0;
      padding: 18px;
      background: #07111f;
      color: #f4f7fb;
      font-family: Arial, sans-serif;
    }

    main {
      max-width: 650px;
      margin: auto;
    }

    header {
      text-align: center;
      padding: 20px 0;
    }

    header h1 {
      color: #35e0b0;
      letter-spacing: 3px;
      margin-bottom: 8px;
    }

    .subtitle {
      color: #9aabc2;
      font-size: 13px;
    }

    .status {
      display: inline-block;
      padding: 7px 12px;
      border-radius: 20px;
      background: #302716;
      color: #ffd27a;
      font-size: 12px;
    }

    .card {
      background: #101d30;
      border: 1px solid #23354d;
      border-radius: 15px;
      padding: 18px;
      margin: 15px 0;
    }

    h2 {
      font-size: 17px;
      margin-top: 0;
    }

    label {
      display: block;
      margin: 15px 0 7px;
      color: #b8c7db;
      font-size: 13px;
    }

    select, input, button {
      width: 100%;
      padding: 13px;
      border-radius: 9px;
      font-size: 15px;
    }

    select, input {
      background: #07111f;
      color: white;
      border: 1px solid #354964;
    }

    button {
      border: none;
      margin-top: 15px;
      background: #35e0b0;
      color: #07111f;
      font-weight: bold;
      cursor: pointer;
    }

    button.secondary {
      background: #263851;
      color: white;
    }

    button.danger {
      background: #7f2935;
      color: white;
    }

    .muted {
      color: #9aabc2;
      font-size: 13px;
      line-height: 1.6;
    }

    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }

    .metric {
      background: #07111f;
      border-radius: 10px;
      padding: 13px;
    }

    .metric small {
      display: block;
      color: #9aabc2;
      margin-bottom: 8px;
    }

    .metric strong {
      font-size: 15px;
    }

    .green { color: #35e0b0; }
    .yellow { color: #ffd27a; }

    .notice {
      background: #302716;
      border-radius: 9px;
      padding: 12px;
      color: #ffd27a;
      font-size: 12px;
      line-height: 1.6;
    }

    footer {
      text-align: center;
      color: #71839c;
      font-size: 11px;
      padding: 22px 0;
    }
  </style>
</head>

<body>
<main>

  <header>
    <h1>DEMO TRADER</h1>
    <div class="subtitle">SMART MARKET ANALYSIS</div>
    <p><span class="status">● LIVE TRADING DISABLED</span></p>
    <p class="muted">Version 1.0 · Mobile Trading Dashboard</p>
  </header>

  <section class="card">
    <h2>Market Scanner</h2>
    <p class="muted">
      Choose an instrument and configure your analysis.
      Real market data is not connected yet.
    </p>

    <label for="broker">Broker</label>
    <select id="broker">
      <option value="XM">XM</option>
      <option value="RCG">RCG Markets</option>
    </select>

    <label for="platform">Trading platform</label>
    <select id="platform">
      <option value="MT5">MetaTrader 5</option>
      <option value="MT4">MetaTrader 4</option>
    </select>

    <label for="market">Market</label>
    <select id="market">
      <option value="XAUUSD">Gold (XAUUSD)</option>
      <option value="XAGUSD">Silver (XAGUSD)</option>
      <option value="EURUSD">EUR/USD</option>
      <option value="GBPUSD">GBP/USD</option>
      <option value="USDJPY">USD/JPY</option>
      <option value="AUDUSD">AUD/USD</option>
      <option value="USDCAD">USD/CAD</option>
      <option value="USDCHF">USD/CHF</option>
      <option value="NZDUSD">NZD/USD</option>
      <option value="NAS100">NASDAQ 100</option>
      <option value="US30">Dow Jones 30</option>
      <option value="US500">S&P 500</option>
      <option value="GER40">Germany 40</option>
    </select>

    <label for="timeframe">Entry timeframe</label>
    <select id="timeframe">
      <option value="M1">M1 — 1 minute</option>
      <option value="M5">M5 — 5 minutes</option>
      <option value="M15">M15 — 15 minutes</option>
      <option value="M30">M30 — 30 minutes</option>
      <option value="H1">H1 — 1 hour</option>
      <option value="D1">D1 — Daily</option>
    </select>

    <label for="strategy">Strategy</label>
    <select id="strategy">
      <option value="ALL">ICT + CRT + SMC + Indicators</option>
      <option value="ICT_CRT">ICT + CRT</option>
      <option value="SMC">Smart Money Concepts</option>
      <option value="INDICATORS">Technical Indicators</option>
    </select>

    <button id="scanButton">CHECK CONFIGURATION</button>
  </section>

  <section class="card">
    <h2>Analysis Status</h2>
    <div class="metric">
      <small>Scanner result</small>
      <strong id="signal" class="yellow">WAITING FOR REAL DATA</strong>
    </div>
    <p id="marketInfo" class="muted">No market has been analysed.</p>
    <p id="reason" class="muted">
      A valid signal requires real prices and implemented strategy rules.
    </p>
  </section>

  <section class="card">
    <h2>Position Settings</h2>
    <p class="muted">
      These are saved interface settings only. They do not place orders.
    </p>

    <label for="lotSize">Manual lot size</label>
    <input id="lotSize" type="number" min="0.01" max="100" step="0.01" value="0.01">

    <label for="risk">Maximum planned risk per trade (%)</label>
    <input id="risk" type="number" min="0.1" max="1" step="0.1" value="0.5">

    <label for="rr">Target risk-to-reward ratio</label>
    <select id="rr">
      <option value="2">1:2</option>
      <option value="3" selected>1:3</option>
      <option value="4">1:4</option>
    </select>

    <button id="saveButton">SAVE SETTINGS ON THIS DEVICE</button>
    <p id="settingsStatus" class="muted">Settings have not been saved.</p>
  </section>

  <section class="card">
    <h2>Connection Status</h2>

    <div class="grid">
      <div class="metric">
        <small>Market data</small>
        <strong class="yellow">Not connected</strong>
      </div>

      <div class="metric">
        <small>Broker account</small>
        <strong class="yellow">Not connected</strong>
      </div>

      <div class="metric">
        <small>Strategy engine</small>
        <strong class="yellow">Not implemented</strong>
      </div>

      <div class="metric">
        <small>Order execution</small>
        <strong class="yellow">Disabled</strong>
      </div>
    </div>

    <button class="danger" id="stopButton">STOP ROBOT</button>

    <p id="robotStatus" class="muted">
      No trading process is running. The stop button disables this dashboard's
      scan action; it cannot close broker positions.
    </p>
  </section>

  <section class="card">
    <h2>Safety Notice</h2>
    <div class="notice">
      This is an early development version. It does not receive live prices,
      analyse actual market conditions, connect to MT4/MT5, or place orders.
      Live execution must not be enabled until the broker bridge and risk
      controls are implemented and tested.
    </div>
  </section>

  <footer>DEMO TRADER · DEVELOPMENT BUILD</footer>

</main>

<script>
  let stopped = false;

  const scanButton = document.getElementById("scanButton");
  const signal = document.getElementById("signal");

  scanButton.addEventListener("click", function () {
    if (stopped) {
      signal.textContent = "SCANNER STOPPED";
      return;
    }

    const broker = document.getElementById("broker").value;
    const platform = document.getElementById("platform").value;
    const market = document.getElementById("market").value;
    const timeframe = document.getElementById("timeframe").value;
    const strategy = document.getElementById("strategy").value;

    signal.textContent = "NO SIGNAL — NO LIVE DATA";

    document.getElementById("marketInfo").textContent =
      broker + " | " + platform + " | " + market +
      " | " + timeframe + " | " + strategy;

    document.getElementById("reason").textContent =
      "Configuration selected. Real price data, strategy calculations, " +
      "and broker connectivity are not implemented yet.";
  });

  document.getElementById("saveButton").addEventListener("click", function () {
    const lot = Number(document.getElementById("lotSize").value);
    const risk = Number(document.getElementById("risk").value);
    const rr = document.getElementById("rr").value;
    const status = document.getElementById("settingsStatus");

    if (!Number.isFinite(lot) || lot < 0.01 || lot > 100 ||
        !Number.isFinite(risk) || risk < 0.1 || risk > 1) {
      status.textContent =
        "Invalid settings. Lot size must be 0.01–100 and risk 0.1%–1%.";
      return;
    }

    const settings = { lot, risk, rr };

    try {
      localStorage.setItem("demoTraderSettings", JSON.stringify(settings));
      status.textContent =
        "Settings saved on this device. No trades were placed.";
    } catch (error) {
      status.textContent =
        "Could not save settings in this browser.";
    }
  });

  try {
    const saved = JSON.parse(localStorage.getItem("demoTraderSettings"));

    if (saved) {
      document.getElementById("lotSize").value = saved.lot;
      document.getElementById("risk").value = saved.risk;
      document.getElementById("rr").value = saved.rr;
      document.getElementById("settingsStatus").textContent =
        "Previously saved settings loaded.";
    }
  } catch (error) {
    // Invalid or unavailable local settings are ignored.
  }

  document.getElementById("stopButton").addEventListener("click", function () {
    stopped = true;
    scanButton.disabled = true;
    scanButton.style.opacity = "0.5";
    signal.textContent = "SCANNER STOPPED";
    document.getElementById("robotStatus").textContent =
      "Dashboard scanning disabled. No broker connection exists.";
  });
</script>

</body>
</html>