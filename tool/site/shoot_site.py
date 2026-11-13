"""Screenshot the local site in headless Chrome at given scroll offsets.
usage: shoot_site.py OUTDIR PROFILE URL W H DPR label:scrollY[:wait] ..."""
import base64, json, subprocess, sys, time, urllib.request
import websocket

OUT, PROFILE, URL, W, H, DPR = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5]), float(sys.argv[6])
SHOTS = [a.split(":") for a in sys.argv[7:]]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
port = 9341
proc = subprocess.Popen([CHROME, "--headless=new", f"--remote-debugging-port={port}", f"--user-data-dir={PROFILE}",
                         f"--window-size={W},{H}", "--hide-scrollbars", "--no-first-run", "--remote-allow-origins=*", "about:blank"])
try:
    for _ in range(60):
        try:
            page = next(t for t in json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json")) if t["type"] == "page")
            break
        except Exception:
            time.sleep(0.25)
    ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=60)
    mid = [0]

    def call(m, **p):
        mid[0] += 1
        ws.send(json.dumps({"id": mid[0], "method": m, "params": p}))
        while True:
            r = json.loads(ws.recv())
            if r.get("id") == mid[0]:
                return r.get("result", r)

    def js(expr):
        return call("Runtime.evaluate", expression=expr, awaitPromise=True, returnByValue=True).get("result", {}).get("value")

    call("Page.enable")
    call("Emulation.setDeviceMetricsOverride", width=W, height=H, deviceScaleFactor=DPR, mobile=W < 700)
    import os
    call("Emulation.setEmulatedMedia", features=[{"name": "prefers-color-scheme", "value": os.environ.get("SCHEME", "light")}])
    call("Page.navigate", url=URL)
    time.sleep(4.5)
    for s in SHOTS:
        label, y = s[0], int(s[1])
        wait = float(s[2]) if len(s) > 2 else 1.6
        js(f"window.scrollTo({{top:{y},behavior:'instant'}})")
        time.sleep(wait)
        r = call("Page.captureScreenshot", format="jpeg", quality=80)
        open(f"{OUT}/{label}.jpg", "wb").write(base64.b64decode(r["data"]))
        print("shot", label, js("JSON.stringify({sy:scrollY,h:document.documentElement.scrollHeight,sw:document.documentElement.scrollWidth,iw:innerWidth})"), flush=True)
    print("errors:", js("JSON.stringify(window.__errs||[])"))
    ws.close()
finally:
    proc.terminate()
