---
layout: home
hide_sidebar: true
title: WasmPatch
description: Compile a C patch to WebAssembly, load it at runtime, and replace Objective-C / Swift methods — no App Store round-trip.
---

<section class="hero">
  <span class="hero__eyebrow reveal"><span class="dot"></span> WebAssembly hot patching for iOS &amp; macOS</span>
  <h1 class="reveal d1">Patch native apps<br><span class="accent">at runtime.</span></h1>
  <p class="hero__lede reveal d2">Compile a tiny C patch to WebAssembly, load it inside your app, and replace Objective-C &amp; Swift methods on the fly — sandboxed, verifiable, and without an App Store round-trip.</p>
  <div class="hero__cta reveal d3">
    <a class="btn btn--primary" href="{{ '/tutorial.html' | relative_url }}">Start the tutorial →</a>
    <a class="btn btn--ghost" href="{{ site.github_repo }}" target="_blank" rel="noopener">View on GitHub</a>
  </div>
</section>

<div class="home__codecard reveal d4" markdown="1">

```c
#include <wasmpatch.h>

WAPObject patched_token(WAPObject self, const char *cmd) {
    return new_objc_nsstring("patched at runtime");
}

int entry() {
    // The registered name is derived from the real symbol —
    // a typo won't compile, never a silent no-op.
    WAP_REPLACE_CLASS(SessionManager, "authToken", patched_token);
    return 0;
}
```

</div>

<section class="section">
  <div class="section__head">
    <p class="section__eyebrow">What you get</p>
    <h2>A real bridge between WebAssembly and the Obj-C runtime</h2>
    <p>Patch logic runs in a wasm interpreter and reaches into the live runtime through a typed bridge.</p>
  </div>
  <div class="features">
    <div class="feature"><div class="feature__icon">↺</div><h3>Method replacement</h3><p>Swap class &amp; instance method implementations at runtime via libffi — callers transparently hit your patch.</p></div>
    <div class="feature"><div class="feature__icon">⌘</div><h3>Swift &amp; Obj-C</h3><p>Hook any Obj-C method, and any <code>@objc dynamic</code> Swift method, with clean Swift APIs.</p></div>
    <div class="feature"><div class="feature__icon">▦</div><h3>Struct bridging</h3><p>Pass &amp; return structs by value — geometry types plus arbitrary structs, unions, and bitfields.</p></div>
    <div class="feature"><div class="feature__icon">⟳</div><h3>Blocks both ways</h3><p>Invoke completion handlers you're handed, and create blocks to pass into Objective-C.</p></div>
    <div class="feature"><div class="feature__icon">⇲</div><h3>Remote delivery</h3><p><code>WAPPatchManager</code> fetches, verifies, caches, and applies patches from your server.</p></div>
    <div class="feature"><div class="feature__icon">🔏</div><h3>Signed &amp; safe</h3><p>SHA-256 integrity plus EC P-256 signature authenticity verified before a patch ever loads.</p></div>
  </div>
</section>

<section class="section">
  <div class="section__head">
    <p class="section__eyebrow">Read next</p>
    <h2>Dig in</h2>
  </div>
  <div class="cards">
    <a class="card" href="{{ '/tutorial.html' | relative_url }}"><span class="card__kicker">Start here</span><h3>Tutorial</h3><p>Install the toolchain, write a patch, build it, and load it — Obj-C and Swift.</p><span class="card__arrow">→</span></a>
    <a class="card" href="{{ '/concepts/how-it-works.html' | relative_url }}"><span class="card__kicker">Concept</span><h3>How it works</h3><p>The wasm interpreter, the export bridge, and libffi-driven method replacement.</p><span class="card__arrow">→</span></a>
    <a class="card" href="{{ '/guides/objc.html' | relative_url }}"><span class="card__kicker">Guide</span><h3>Objective-C in depth</h3><p>Type encodings, calling conventions, arguments and return values, real patterns.</p><span class="card__arrow">→</span></a>
    <a class="card" href="{{ '/guides/swift.html' | relative_url }}"><span class="card__kicker">Guide</span><h3>Swift in depth</h3><p>Dispatch, <code>@objc dynamic</code>, name mangling, value-type bridging, and limits.</p><span class="card__arrow">→</span></a>
    <a class="card" href="{{ '/guides/remote-delivery.html' | relative_url }}"><span class="card__kicker">Delivery</span><h3>Remote delivery</h3><p>Fetch, verify, cache, and apply patches safely from your backend.</p><span class="card__arrow">→</span></a>
    <a class="card" href="{{ '/concepts/security.html' | relative_url }}"><span class="card__kicker">Safety</span><h3>Security model</h3><p>The sandbox boundary, signing, the threat model, and production guidance.</p><span class="card__arrow">→</span></a>
  </div>
</section>

<div class="home__foot">
  MIT-licensed · <a href="{{ site.github_repo }}" target="_blank" rel="noopener">github.com/everettjf/WasmPatch</a>
</div>
