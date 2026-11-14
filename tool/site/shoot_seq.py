"""Drive the site in headless Chrome and capture a sequence.
usage: shoot_seq.py OUT PROFILE URL W H DPR step...
steps:  shot:NAME | wait:SECS | scroll:Y | move:x1,y1,x2,y2,steps | click:x,y | js:EXPR | clicksel:CSS
env SCHEME=light|dark"""
import base64, json, os, subprocess, sys, time, urllib.request
import websocket

OUT, PROFILE, URL, W, H, DPR = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5]), float(sys.argv[6])
STEPS = sys.argv[7:]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
port = 9347
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
    call("Emulation.setEmulatedMedia", features=[{"name": "prefers-color-scheme", "value": os.environ.get("SCHEME", "light")}])
    call("Page.addScriptToEvaluateOnNewDocument", source="window.__errs=[];addEventListener('error',function(e){__errs.push(String(e.message)+' @'+e.lineno)});addEventListener('unhandledrejection',function(e){__errs.push('rej '+e.reason)});")
    call("Page.navigate", url=URL)
    for st in STEPS:
        k, _, v = st.partition(":")
        if k == "wait":
            time.sleep(float(v))
        elif k == "shot":
            r = call("Page.captureScreenshot", format="jpeg", quality=82)
            open(f"{OUT}/{v}.jpg", "wb").write(base64.b64decode(r["data"]))
        elif k == "scroll":
            js(f"window.scrollTo({{top:{v},behavior:'instant'}})")
        elif k == "move":
            x1, y1, x2, y2, n = [float(a) for a in v.split(",")]
            n = int(n)
            for i in range(n + 1):
                call("Input.dispatchMouseEvent", type="mouseMoved", x=x1 + (x2 - x1) * i / n, y=y1 + (y2 - y1) * i / n, pointerType="mouse")
                time.sleep(0.012)
        elif k == "click":
            x, y = [float(a) for a in v.split(",")]
            call("Input.dispatchMouseEvent", type="mousePressed", x=x, y=y, button="left", clickCount=1)
            call("Input.dispatchMouseEvent", type="mouseReleased", x=x, y=y, button="left", clickCount=1)
        elif k == "clicksel":
            js(f"(function(){{var e=document.querySelector({json.dumps(v)});e.scrollIntoView({{block:'center',behavior:'instant'}});e.click()}})()")
        elif k == "js":
            print("js>", js(v), flush=True)
    print("errors:", js("JSON.stringify(window.__errs||[])"), "| html:", js("document.documentElement.className"))
    ws.close()
finally:
    proc.terminate()
