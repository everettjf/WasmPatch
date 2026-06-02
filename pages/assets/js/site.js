(function () {
  "use strict";
  var doc = document.documentElement;

  /* ---- Theme toggle ---- */
  var toggle = document.querySelector("[data-theme-toggle]");
  if (toggle) {
    toggle.addEventListener("click", function () {
      var next = doc.getAttribute("data-theme") === "light" ? "dark" : "light";
      doc.setAttribute("data-theme", next);
      try { localStorage.setItem("wap-theme", next); } catch (e) {}
    });
  }

  /* ---- Mobile nav drawer ---- */
  var navToggle = document.querySelector("[data-nav-toggle]");
  var scrim = document.querySelector("[data-nav-scrim]");
  function closeNav() { document.body.classList.remove("nav-open"); }
  if (navToggle) {
    navToggle.addEventListener("click", function () {
      document.body.classList.toggle("nav-open");
    });
  }
  if (scrim) scrim.addEventListener("click", closeNav);
  document.querySelectorAll(".sidebar__nav a").forEach(function (a) {
    a.addEventListener("click", closeNav);
  });

  /* ---- Copy buttons on code blocks ---- */
  document.querySelectorAll("div.highlight").forEach(function (block) {
    var pre = block.querySelector("pre");
    if (!pre) return;
    var btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.type = "button";
    btn.textContent = "Copy";
    btn.addEventListener("click", function () {
      var text = pre.innerText;
      navigator.clipboard.writeText(text).then(function () {
        btn.textContent = "Copied";
        btn.classList.add("copied");
        setTimeout(function () { btn.textContent = "Copy"; btn.classList.remove("copied"); }, 1600);
      });
    });
    block.appendChild(btn);
  });

  /* ---- Heading anchors ---- */
  var body = document.querySelector("[data-doc-body]");
  if (body) {
    body.querySelectorAll("h2[id], h3[id]").forEach(function (h) {
      var a = document.createElement("a");
      a.className = "anchor-link";
      a.href = "#" + h.id;
      a.textContent = "#";
      a.setAttribute("aria-hidden", "true");
      h.insertBefore(a, h.firstChild);
    });
  }

  /* ---- TOC build + scrollspy ---- */
  var tocList = document.querySelector("[data-toc-list]");
  if (body && tocList) {
    var heads = Array.prototype.slice.call(body.querySelectorAll("h2[id], h3[id]"));
    if (heads.length < 2) {
      var toc = document.querySelector("[data-toc]");
      if (toc) toc.style.display = "none";
    } else {
      var links = {};
      heads.forEach(function (h) {
        var a = document.createElement("a");
        a.href = "#" + h.id;
        a.textContent = h.textContent.replace(/^#/, "").trim();
        a.className = h.tagName === "H3" ? "lvl-3" : "lvl-2";
        tocList.appendChild(a);
        links[h.id] = a;
      });
      if ("IntersectionObserver" in window) {
        var current = null;
        var obs = new IntersectionObserver(function (entries) {
          entries.forEach(function (en) {
            if (en.isIntersecting) {
              if (current) current.classList.remove("active");
              current = links[en.target.id];
              if (current) current.classList.add("active");
            }
          });
        }, { rootMargin: "-80px 0px -70% 0px", threshold: 0 });
        heads.forEach(function (h) { obs.observe(h); });
      }
    }
  }
})();
