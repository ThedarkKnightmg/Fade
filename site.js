(function () {
  'use strict';
  var html = document.documentElement;
  var reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  var fine = matchMedia('(hover: hover) and (pointer: fine)').matches;
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var clamp = function (v, a, b) { return v < a ? a : v > b ? b : v; };
  var fx = { burst: function () {} };   // real particle burst is wired in once motion is on
  var langHooks = [];

  /* ── language ── */
  var LANGS = ['uz', 'ru', 'en'], lang;
  (function () {
    var q = new URLSearchParams(location.search).get('lang');
    lang = LANGS.indexOf(q) >= 0 ? q : null;
    try { if (!lang) lang = localStorage.getItem('fade-lang'); } catch (e) {}
    if (LANGS.indexOf(lang) < 0) {
      var n = (navigator.language || '').slice(0, 2);
      lang = n === 'ru' ? 'ru' : n === 'en' ? 'en' : 'uz';
    }
  })();
  function setLang(x) {
    lang = x;
    document.body.className = x;
    html.lang = x;
    $$('.langs button').forEach(function (b) {
      var on = b.dataset.set === x;
      b.classList.toggle('on', on);
      b.setAttribute('aria-pressed', on);
    });
    try { localStorage.setItem('fade-lang', x); } catch (e) {}
    langHooks.forEach(function (f) { f(); });
    if (window.ScrollTrigger) ScrollTrigger.refresh();
  }
  $$('.langs button').forEach(function (b) { b.addEventListener('click', function () { setLang(b.dataset.set); }); });
  setLang(lang);

  /* ── demo: pick a time, a ticket prints (works with or without motion) ── */
  $$('[data-demo="book"]').forEach(function (b) {
    var days = $('.days', b), dayBtns = $$('.days button', b), slots = $$('.slots button', b);
    var day = 1, picked = null, timer;
    function print() {
      if (!picked) return;
      b.classList.remove('printed');
      $('.pticket', b).classList.remove('done');
      clearTimeout(timer);
      timer = setTimeout(function () {
        $('[data-out="day"]', b).innerHTML = dayBtns[day].innerHTML;
        $('[data-out="time"]', b).textContent = picked.textContent;
        b.classList.add('printed');
        setTimeout(function () {
          $('.pticket', b).classList.add('done');
          var r = $('.pticket', b).getBoundingClientRect();
          fx.burst(r.left + r.width / 2, r.top + 10, 16);
        }, reduce ? 0 : 1000);
      }, reduce ? 0 : 260);
    }
    dayBtns.forEach(function (d, i) {
      d.addEventListener('click', function () {
        day = i; days.dataset.on = i;
        dayBtns.forEach(function (x, k) { x.classList.toggle('on', k === i); });
        print();
      });
    });
    slots.forEach(function (s) {
      s.addEventListener('click', function () {
        picked = s;
        slots.forEach(function (x) { x.classList.toggle('on', x === s); });
        print();
      });
    });
  });

  /* ── demo: accept requests, the day fills and earnings count up ── */
  $$('[data-demo="accept"]').forEach(function (d) {
    var reqs = $$('.req', d), rows = $$('.trow', d), earnEl = $('[data-earn]', d), earnBox = $('.earn', d);
    var total = 0, shown = 0;
    var fmt = function (n) { return n.toLocaleString('ru-RU').replace(/ /g, ' '); };
    function layout() {
      var k = 0;
      reqs.forEach(function (r) { if (r.classList.contains('gone')) r.removeAttribute('data-pos'); else r.dataset.pos = k++; });
      d.classList.toggle('done', k === 0);
    }
    function count(to) {
      var from = shown, t0 = performance.now();
      if (reduce) { shown = to; earnEl.textContent = fmt(to); return; }
      (function f(now) {
        var p = Math.min((now - t0) / 700, 1); p = 1 - Math.pow(1 - p, 3);
        shown = Math.round(from + (to - from) * p);
        earnEl.textContent = fmt(shown);
        if (p < 1) requestAnimationFrame(f);
      })(t0);
    }
    reqs.forEach(function (r, i) {
      $('button', r).addEventListener('click', function () {
        if (r.classList.contains('gone')) return;
        r.classList.add('gone');
        rows[i].classList.add('full');
        total += +r.dataset.price; count(total);
        earnBox.classList.remove('bump'); void earnBox.offsetWidth; earnBox.classList.add('bump');
        var rr = rows[i].getBoundingClientRect();
        fx.burst(rr.left + rr.width * .6, rr.top + rr.height / 2, 12);
        layout();
      });
    });
    $('[data-reset]', d).addEventListener('click', function () {
      total = 0; count(0);
      reqs.forEach(function (r) { r.classList.remove('gone'); });
      rows.forEach(function (r) { r.classList.remove('full'); });
      layout();
    });
    layout();
  });

  /* ── FAQ: smooth open/close ── */
  $$('.qa').forEach(function (d) {
    var s = $('summary', d), a = $('.qa-a', d);
    s.addEventListener('click', function (e) {
      if (!html.classList.contains('js')) return;
      e.preventDefault();
      if (d.open) {
        d.classList.remove('is-open');
        a.addEventListener('transitionend', function f() { a.removeEventListener('transitionend', f); if (!d.classList.contains('is-open')) d.open = false; });
      } else {
        d.open = true;
        requestAnimationFrame(function () { requestAnimationFrame(function () { d.classList.add('is-open'); }); });
      }
    });
  });

  /* ── header state ── */
  var top = $('.top');
  function headerState() { top.classList.toggle('scrolled', scrollY > 10); }
  addEventListener('scroll', headerState, { passive: true }); headerState();

  if (reduce || !window.gsap || !window.ScrollTrigger) {
    html.classList.remove('js', 'intro');
    return;
  }
  gsap.registerPlugin(ScrollTrigger);

  var css = getComputedStyle(html);
  var ACC = css.getPropertyValue('--accent').trim() || '#2e8bff';
  var INK = css.getPropertyValue('--ink').trim() || '#121418';
  var GOLD = css.getPropertyValue('--gold').trim() || '#ffd25e';

  /* ── clippings: one shared particle layer for every cut on the page ── */
  var P = (function () {
    var cv = $('.clips'), ctx = cv.getContext('2d'), list = [], running = false, last = 0;
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    function size() { cv.width = innerWidth * dpr; cv.height = innerHeight * dpr; }
    size(); addEventListener('resize', size);
    function frame(t) {
      var dt = Math.min((t - last) / 1000, .05); last = t;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, innerWidth, innerHeight);
      ctx.lineCap = 'round';
      for (var i = list.length - 1; i >= 0; i--) {
        var p = list[i]; p.age += dt;
        if (p.age > p.life || p.y > innerHeight + 40) { list.splice(i, 1); continue; }
        p.vy += p.g * dt; p.vx *= (1 - 1.4 * dt);
        p.x += p.vx * dt; p.y += p.vy * dt; p.rot += p.vr * dt;
        var dx = Math.cos(p.rot) * p.len / 2, dy = Math.sin(p.rot) * p.len / 2;
        ctx.globalAlpha = 1 - Math.pow(p.age / p.life, 3);
        ctx.strokeStyle = p.color; ctx.lineWidth = p.w;
        ctx.beginPath(); ctx.moveTo(p.x - dx, p.y - dy);
        ctx.quadraticCurveTo(p.x + dy * .35, p.y - dx * .35, p.x + dx, p.y + dy);
        ctx.stroke();
      }
      ctx.globalAlpha = 1;
      if (list.length) requestAnimationFrame(frame); else running = false;
    }
    return {
      add: function (o) {
        if (list.length > 520) return;
        o.age = 0; list.push(o);
        if (!running) { running = true; last = performance.now(); requestAnimationFrame(frame); }
      }
    };
  })();
  fx.burst = function (x, y, n, colors, power) {
    colors = colors || [ACC, GOLD, INK];
    for (var i = 0; i < n; i++) {
      var a = Math.random() * Math.PI * 2, sp = (power || 260) * (.35 + Math.random());
      P.add({ x: x, y: y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp - 150, g: 900, rot: Math.random() * 6.28, vr: (Math.random() - .5) * 16,
        len: 6 + Math.random() * 10, w: 2.2, color: colors[i % colors.length], life: .7 + Math.random() * .6 });
    }
  };

  /* ── the clipper: one actor that opens the page and trims the headline ── */
  var CL = (function () {
    var el = $('.clipper'), inner = $('.clipper-in'), dir = 1;
    return {
      show: function (scale) { gsap.killTweensOf(el); gsap.set(el, { autoAlpha: 1, scale: scale || 1, transformOrigin: '0 0' }); el.classList.add('on'); },
      hide: function () { el.classList.remove('on'); gsap.to(el, { autoAlpha: 0, duration: .25, overwrite: true }); },
      at: function (x, y, d) {
        gsap.set(el, { x: x, y: y });
        if (d && d !== dir) { dir = d; inner.style.transform = d < 0 ? 'scaleX(-1)' : ''; }
      }
    };
  })();

  /* ── split text into masked words / chars ── */
  function split(el, chars) {
    (function walk(node) {
      Array.prototype.slice.call(node.childNodes).forEach(function (n) {
        if (n.nodeType === 3) {
          var frag = document.createDocumentFragment();
          n.textContent.split(/(\s+)/).forEach(function (part) {
            if (!part) return;
            if (/^\s+$/.test(part)) { frag.appendChild(document.createTextNode(' ')); return; }
            var w = document.createElement('span'); w.className = 'w';
            if (chars) {
              Array.from(part).forEach(function (ch) { var c = document.createElement('span'); c.className = 'c'; c.textContent = ch; w.appendChild(c); });
            } else {
              var i = document.createElement('span'); i.className = 'wi'; i.textContent = part; w.appendChild(i);
            }
            frag.appendChild(w);
          });
          n.parentNode.replaceChild(frag, n);
        } else if (n.nodeType === 1 && n.tagName !== 'BR' && n.tagName !== 'A') walk(n);
      });
    })(el);
  }
  $$('.h-split').forEach(function (h) { split(h, true); });
  $$('.split').forEach(function (h) { split(h, false); });
  var cur = function (sel, root) { return $$('[data-l="' + lang + '"] ' + sel, root); };

  /* ── intro: the page is shaved open, stripe by stripe ── */
  var navArrive = false;
  try { navArrive = sessionStorage.getItem('fade-nav') === '1'; sessionStorage.removeItem('fade-nav'); } catch (e) {}
  var playIntro = html.classList.contains('intro');
  var introDur = 0;
  function bandsFor(ov, withWord) {
    var N = innerHeight > innerWidth ? 4 : 3, H = innerHeight, bh = Math.ceil(H / N), out = [];
    for (var i = 0; i < N; i++) {
      var b = document.createElement('div'); b.className = 'intro-band';
      b.style.top = (i * bh) + 'px'; b.style.height = (bh + 1) + 'px'; b.style.clipPath = 'inset(0 0 0 0)';
      if (withWord) { var w = document.createElement('div'); w.className = 'intro-word'; w.textContent = 'Fade'; w.style.top = (H / 2 - i * bh) + 'px'; w.style.opacity = 1; b.appendChild(w); }
      ov.appendChild(b); out.push({ el: b, top: i * bh, h: bh });
    }
    return out;
  }
  if (playIntro) {
    var ov = $('.intro-ov'), word = $('.intro-word', ov), W = innerWidth;
    var itl = gsap.timeline();
    var per = navArrive ? .3 : .4, bands;
    if (!navArrive) itl.fromTo(word, { opacity: 0, y: 14 }, { opacity: 1, y: 0, duration: .5, ease: 'expo.out' }).to({}, { duration: .12 });
    itl.add(function () {
      bands = bandsFor(ov, !navArrive);
      word.style.display = 'none'; ov.style.background = 'none';
      CL.show(innerWidth < 700 ? 1.3 : 1.9);
    });
    var N0 = innerHeight > innerWidth ? 4 : 3;
    for (var bi = 0; bi < N0; bi++) (function (i) {
      var st = { e: 0 }, dir = i % 2 ? -1 : 1;
      itl.to(st, { e: 1, duration: per, ease: 'power2.inOut', onUpdate: function () {
        var b = bands[i]; if (!b) return;
        var x = dir > 0 ? -150 + (W + 300) * st.e : W + 150 - (W + 300) * st.e;
        CL.at(x, b.top + b.h / 2, dir);
        var p = clamp(x / W, 0, 1) * 100;
        b.el.style.clipPath = dir > 0 ? 'inset(0 0 0 ' + p + '%)' : 'inset(0 ' + (100 - p) + '% 0 0)';
        if (x > 0 && x < W) for (var k = 0; k < 2; k++)
          P.add({ x: x, y: b.top + Math.random() * b.h, vx: -dir * (120 + Math.random() * 260), vy: -160 + Math.random() * 200, g: 800, rot: Math.random() * 6.28,
            vr: (Math.random() - .5) * 14, len: 8 + Math.random() * 12, w: 2.4, color: k ? '#ffffff' : '#bcd9ff', life: .6 + Math.random() * .5 });
      } });
    })(bi);
    itl.add(function () { html.classList.remove('intro'); ov.remove(); CL.hide(); });
    introDur = itl.duration();
  } else {
    html.classList.remove('intro');
  }

  /* leaving for the other page: stripes close in, the next page shaves them off */
  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('a[href]');
    if (!a || e.defaultPrevented || e.metaKey || e.ctrlKey || e.shiftKey || e.button || a.target === '_blank') return;
    var u; try { u = new URL(a.href, location.href); } catch (err) { return; }
    if (u.origin !== location.origin) return;
    var page = function (p) { p = p.split('/').pop(); return p === '' ? 'index.html' : p; };
    var to = page(u.pathname);
    if (!/^(index|barbers)\.html$/.test(to) || to === page(location.pathname)) return;
    e.preventDefault();
    try { sessionStorage.setItem('fade-nav', '1'); } catch (err) {}
    var o = document.createElement('div'); o.className = 'intro-ov show out'; o.style.background = 'none';
    document.body.appendChild(o);
    var bs = bandsFor(o, false);
    bs.forEach(function (b, i) { b.el.style.clipPath = i % 2 ? 'inset(0 0 0 100%)' : 'inset(0 100% 0 0)'; });
    gsap.to(bs.map(function (b) { return b.el; }), { clipPath: 'inset(0 0% 0 0%)', duration: .42, ease: 'power3.inOut', stagger: .05,
      onComplete: function () { location.href = a.href; } });
  });
  addEventListener('pageshow', function (e) {
    if (!e.persisted) return;
    $$('.intro-ov.out').forEach(function (o) { o.remove(); });
    try { sessionStorage.removeItem('fade-nav'); } catch (err) {}
  });

  /* ── the shaggy headline: hair grows on the letters, you trim it ── */
  function makeHair(hero, h1, copy) {
    var cv = $('.hair', hero), hint = $('.trim-hint', hero), toast = $('.fresh', hero);
    var ctx = cv.getContext('2d'), dpr = Math.min(window.devicePixelRatio || 1, 2);
    var S = [], left = 0, R = 20, lw = 2, fs = 60;
    var done = false, grown = false, auto = false, clipping = false, raf = 0, t0 = performance.now();
    var wind = 0, lastX = 0, lastDir = 1, idle = 0;
    var PAD = { t: 76, s: 26, b: 14 };

    function build() {
      S = [];
      var hr = h1.getBoundingClientRect(), cr = copy.getBoundingClientRect();
      var w = hr.width + PAD.s * 2, h = hr.height + PAD.t + PAD.b;
      cv.style.left = (hr.left - cr.left - PAD.s) + 'px'; cv.style.top = (hr.top - cr.top - PAD.t) + 'px';
      cv.style.width = w + 'px'; cv.style.height = h + 'px';
      cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr);
      var cs = getComputedStyle(h1); fs = parseFloat(cs.fontSize);
      var lh = parseFloat(cs.lineHeight) || fs * .96;
      var font = cs.fontWeight + ' ' + fs + 'px ' + cs.fontFamily;
      var oc = document.createElement('canvas'), o = oc.getContext('2d', { willReadFrequently: true });
      o.font = font;
      var m = o.measureText('Hg'), A = m.fontBoundingBoxAscent || fs * 1.01, D = m.fontBoundingBoxDescent || fs * .35;
      var baseOff = (lh - (A + D)) / 2 + A, oy = Math.round(fs * .35);
      var step = Math.max(1.9, fs * .026), bx = hr.left - PAD.s, by = hr.top - PAD.t;
      R = Math.max(18, fs * .3); lw = Math.max(1.5, fs * .024);
      cur('.c', h1).forEach(function (c) {
        var ch = c.textContent; if (!ch.trim()) return;
        var r = c.getBoundingClientRect(); if (r.width < 1) return;
        var cw = Math.ceil(r.width + fs * .3), chh = Math.ceil(lh + fs * .7);
        oc.width = cw; oc.height = chh;
        o.font = font; o.textBaseline = 'alphabetic'; o.fillStyle = '#000'; o.fillText(ch, 0, oy + baseOff);
        var d = o.getImageData(0, 0, cw, chh).data, color = getComputedStyle(c).color, em = !!c.closest('em'), line = Math.round(r.top - hr.top);
        for (var x = 1; x < r.width - .5; x += step) {
          var xi = Math.round(x);
          for (var y = 0; y < chh; y++) {
            if (d[(y * cw + xi) * 4 + 3] > 110) {
              S.push({ x: r.left - bx + x, y: r.top - by + (y - oy) + 1.5, L: fs * (.17 + Math.random() * .21), a: -Math.PI / 2 + (Math.random() - .5) * 1.05,
                k: (Math.random() - .5) * 1.2, ph: Math.random() * 6.28, g: 0, cut: false, c: color, em: em, line: line });
              break;
            }
          }
        }
      });
      left = S.length;
    }

    function draw(now) {
      raf = 0;
      var t = (now - t0) / 1000;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, cv.width, cv.height);
      ctx.lineCap = 'round'; ctx.lineWidth = lw;
      wind *= .9;
      var groups = {};
      for (var i = 0; i < S.length; i++) { var s = S[i]; if (s.cut || s.g < .02) continue; (groups[s.c] = groups[s.c] || []).push(s); }
      for (var col in groups) {
        ctx.strokeStyle = col; ctx.beginPath();
        var g = groups[col];
        for (var j = 0; j < g.length; j++) {
          var q = g[j], len = q.L * q.g, a = q.a + Math.sin(t * 1.7 + q.ph) * .09 + wind;
          ctx.moveTo(q.x, q.y);
          ctx.quadraticCurveTo(q.x + Math.cos(a + q.k) * len * .55, q.y + Math.sin(a + q.k) * len * .55, q.x + Math.cos(a) * len, q.y + Math.sin(a) * len);
        }
        ctx.stroke();
      }
      if (!done && scrollY < hero.offsetHeight) raf = requestAnimationFrame(draw);
    }
    function loop() { if (!raf && !done) raf = requestAnimationFrame(draw); }

    function trimAt(vx, vy, force, filter) {
      var r = cv.getBoundingClientRect(), lx = vx - r.left, ly = vy - r.top, n = 0;
      for (var i = 0; i < S.length; i++) {
        var s = S[i];
        if (s.cut || s.g < .5 || (filter && !filter(s))) continue;
        var dx = s.x - lx; if (dx > R || dx < -R) continue;
        if (!force && (ly < s.y - s.L - 22 || ly > s.y + 28)) continue;
        s.cut = true; left--; n++;
        P.add({ x: r.left + s.x + Math.cos(s.a) * s.L * .6, y: r.top + s.y + Math.sin(s.a) * s.L * .6, vx: (Math.random() - .5) * 200 + lastDir * 70,
          vy: -70 - Math.random() * 150, g: 950, rot: s.a, vr: (Math.random() - .5) * 16, len: s.L * .75, w: lw, color: s.c, life: .8 + Math.random() * .6 });
      }
      if (n && left <= 0) finish();
      return n;
    }

    function autoPass(filter, cb) {
      var groups = {};
      S.forEach(function (s) { if (!s.cut && filter(s)) (groups[s.line] = groups[s.line] || []).push(s); });
      var keys = Object.keys(groups).sort(function (a, b) { return a - b; });
      if (!keys.length) { if (cb) cb(); return; }
      auto = true; lastDir = 1; CL.show(fs < 60 ? .8 : 1.1);
      var tl = gsap.timeline({ onComplete: function () { auto = false; CL.hide(); if (cb) cb(); } });
      keys.forEach(function (k) {
        var g = groups[k], minX = 1e9, maxX = -1e9, ys = [];
        g.forEach(function (s) { if (s.x < minX) minX = s.x; if (s.x > maxX) maxX = s.x; ys.push(s.y); });
        ys.sort(function (a, b) { return a - b; });
        var y = ys[ys.length >> 1], st = { e: 0 };
        tl.to(st, { e: 1, duration: clamp((maxX - minX) / 650, .45, 1.1), ease: 'power1.inOut', onUpdate: function () {
          var r = cv.getBoundingClientRect(), x = minX - 30 + (maxX - minX + 70) * st.e;
          CL.at(r.left + x, r.top + y, 1);
          trimAt(r.left + x, r.top + y, true, function (s) { return s.line == k && filter(s); });
        } });
      });
    }

    function place(el, dy) {
      var em = $('[data-l="' + lang + '"] em', h1) || h1;
      var er = em.getBoundingClientRect(), cr = copy.getBoundingClientRect(), w = el.offsetWidth, hh = el.offsetHeight;
      return { x: clamp(er.right - cr.left - w * .75, 0, Math.max(0, cr.width - w)), y: er.top - cr.top - hh - fs * .34 + (dy || 0) };
    }
    function showHint() {
      if (done) return;
      var p = place(hint);
      gsap.fromTo(hint, { x: p.x, y: p.y + 12, autoAlpha: 0, scale: .8 }, { y: p.y, autoAlpha: 1, scale: 1, duration: .7, ease: 'expo.out' });
      clearTimeout(idle);
      idle = setTimeout(function () { if (!done && !auto) autoPass(function () { return true; }); }, 9000);
    }
    function finish(silent) {
      if (done) return;
      done = true; clearTimeout(idle);
      S.forEach(function (s) { s.cut = true; });
      gsap.to(hint, { autoAlpha: 0, scale: .8, duration: .2, overwrite: true });
      hero.classList.add('lit');
      html.classList.remove('clipping'); clipping = false;
      if (!auto) CL.hide();
      gsap.to(cv, { autoAlpha: 0, duration: .4 });
      if (silent) return;
      var p = place(toast, -4), tr = copy.getBoundingClientRect();
      gsap.timeline()
        .fromTo(toast, { x: p.x, y: p.y + 14, autoAlpha: 0, scale: .7 }, { y: p.y, autoAlpha: 1, scale: 1, duration: .6, ease: 'expo.out' })
        .to(toast, { autoAlpha: 0, y: p.y - 14, duration: .5, ease: 'power2.in' }, '+=1.5');
      fx.burst(tr.left + p.x + toast.offsetWidth / 2, tr.top + p.y + 10, 22, [ACC, GOLD, INK], 320);
    }

    function onMove(e) {
      if (done || !grown || auto) return;
      var r = cv.getBoundingClientRect();
      var inside = e.clientX > r.left - 10 && e.clientX < r.right + 10 && e.clientY > r.top - 6 && e.clientY < r.bottom + 30;
      if (!inside) { if (clipping) { clipping = false; CL.hide(); html.classList.remove('clipping'); } return; }
      var dxm = e.clientX - lastX;
      if (Math.abs(dxm) > 2) lastDir = dxm > 0 ? 1 : -1;
      wind = clamp(wind + dxm * .004, -.5, .5); lastX = e.clientX;
      if (!clipping) { clipping = true; CL.show(fs < 60 ? .8 : 1.1); html.classList.add('clipping'); }
      CL.at(e.clientX, e.clientY, lastDir);
      if (trimAt(e.clientX, e.clientY, false)) { clearTimeout(idle); gsap.to(hint, { autoAlpha: 0, duration: .25, overwrite: true }); }
    }
    function onLeave() { if (clipping) { clipping = false; CL.hide(); html.classList.remove('clipping'); } }
    hero.addEventListener('pointermove', onMove);
    hero.addEventListener('pointerleave', onLeave);
    hero.addEventListener('pointerup', function (e) { if (e.pointerType !== 'mouse') onLeave(); });
    hero.addEventListener('pointercancel', onLeave);

    addEventListener('scroll', function () {
      if (done || !grown) return;
      if (scrollY > hero.offsetHeight) { finish(true); return; }
      if (scrollY > 90 && !auto) autoPass(function () { return true; });
    }, { passive: true });

    function rebuild() { if (done || !grown) return; build(); S.forEach(function (s) { s.g = 1; }); loop(); if (hint.style.visibility !== 'hidden') showHint(); }
    var rz; addEventListener('resize', function () { clearTimeout(rz); rz = setTimeout(rebuild, 250); });
    langHooks.push(function () { setTimeout(rebuild, 30); });

    return {
      start: function () {
        var go = function () {
          if (scrollY > 90) { hero.classList.add('lit'); done = true; return; }
          build(); grown = true; loop();
          gsap.to(S, { g: 1, duration: .9, ease: 'expo.out', stagger: { amount: .55 } });
          gsap.delayedCall(1.25, function () {
            if (done) return;
            if (auto) return;
            autoPass(function (s) { return !s.em; }, showHint);
          });
        };
        if (document.fonts && document.fonts.status !== 'loaded') document.fonts.ready.then(go); else go();
      }
    };
  }

  /* ── hero entrance ── */
  var hero = $('.hero');
  if (hero) {
    var h1 = $('h1', hero), copy = $('.hero-copy', hero);
    var hair = makeHair(hero, h1, copy);
    var tl = gsap.timeline({ delay: playIntro ? Math.max(0, introDur - .45) : .15, defaults: { ease: 'expo.out' } });
    tl.from(cur('.c', h1), { yPercent: 115, rotate: 7, duration: 1.05, stagger: .014 })
      .from($('.eyebrow', hero), { y: 18, autoAlpha: 0, duration: .8 }, 0)
      .from([$('.lead', hero)].concat($$('.cta-row > *', hero), $$('.ticks li', hero)), { y: 26, autoAlpha: 0, duration: .9, stagger: .06 }, .35)
      .from($('.pole', hero), { scaleY: 0, transformOrigin: '50% 100%', duration: 1.3 }, .1)
      .from($('.phone-wrap', hero), { y: 160, rotate: -10, autoAlpha: 0, duration: 1.4 }, .2)
      .from($$('.sticker', hero), { scale: 0, rotate: -50, autoAlpha: 0, duration: 1.1, stagger: .12 }, .65)
      .from($('.ticket', hero), { x: 40, autoAlpha: 0, duration: 1 }, .95)
      .add(function () { var t = $('.ticket', hero); if (t) t.classList.add('done'); }, 1.25)
      .from($('.scroll-hint', hero), { autoAlpha: 0, duration: .6 }, 1.2)
      .add(function () { hair.start(); }, 1.6);
    hero.style.visibility = 'visible';

    gsap.to($$('.sticker', hero), { yPercent: function (i, el) { return -60 * (parseFloat(el.dataset.depth) || 1); }, ease: 'none',
      scrollTrigger: { trigger: hero, start: 'top top', end: 'bottom top', scrub: true } });
    gsap.to($('.phone-wrap', hero), { y: 90, ease: 'none', scrollTrigger: { trigger: hero, start: 'top top', end: 'bottom top', scrub: true } });
    gsap.to($('.pole', hero), { y: -60, rotate: 22, ease: 'none', scrollTrigger: { trigger: hero, start: 'top top', end: 'bottom top', scrub: true } });

    if (fine) {
      var art = $('.hero-art', hero), ph = $('.hero-phone', hero);
      var rx = gsap.quickTo(ph, 'rotationX', { duration: .8, ease: 'power3' });
      var ry = gsap.quickTo(ph, 'rotationY', { duration: .8, ease: 'power3' });
      var sts = $$('.sticker', hero).map(function (s) { return { x: gsap.quickTo(s, 'x', { duration: 1, ease: 'power3' }), y: gsap.quickTo(s, 'y', { duration: 1, ease: 'power3' }), d: parseFloat(s.dataset.depth) || 1 }; });
      hero.addEventListener('pointermove', function (e) {
        var r = art.getBoundingClientRect();
        var px = (e.clientX - r.left) / r.width - .5, py = (e.clientY - r.top) / r.height - .5;
        ry(clamp(px, -1, 1) * 16); rx(-clamp(py, -1, 1) * 12);
        sts.forEach(function (s) { s.x(px * 40 * s.d); s.y(py * 40 * s.d); });
      });
      hero.addEventListener('pointerleave', function () { rx(0); ry(0); sts.forEach(function (s) { s.x(0); s.y(0); }); });
    }
  }

  /* ── headings: words rise out of a mask ── */
  $$('.split').forEach(function (h) {
    LANGS.forEach(function (l) {
      var words = $$('[data-l="' + l + '"] .wi', h);
      if (!words.length) return;
      gsap.from(words, { yPercent: 110, rotate: 4, duration: 1, ease: 'expo.out', stagger: .045, scrollTrigger: { trigger: h, start: 'top 86%' } });
    });
  });
  $$('.fade-up').forEach(function (el) {
    gsap.from(el, { y: 30, autoAlpha: 0, duration: 1, ease: 'expo.out', scrollTrigger: { trigger: el, start: 'top 88%' } });
  });

  /* ── marquee: endless, speeds up and leans with scroll velocity ── */
  $$('.marquee').forEach(function (m) {
    var tracks = $$('.mq-track', m);
    var loop = gsap.to(tracks, { xPercent: -50, duration: 34, ease: 'none', repeat: -1 });
    var skew = gsap.quickTo(tracks, 'skewX', { duration: .5, ease: 'power3' });
    var idleT;
    ScrollTrigger.create({ trigger: m, start: 'top bottom', end: 'bottom top', onUpdate: function (self) {
      var v = self.getVelocity(), dir = self.direction;
      gsap.to(loop, { timeScale: dir * (1 + Math.min(Math.abs(v) / 300, 6)), duration: .2, overwrite: true });
      skew(clamp(-v / 250, -10, 10));
      clearTimeout(idleT);
      idleT = setTimeout(function () { gsap.to(loop, { timeScale: dir, duration: 1.2, overwrite: true }); skew(0); }, 140);
    } });
    gsap.to($$('.mq-dot', m), { rotate: 360, duration: 6, repeat: -1, ease: 'none' });
  });

  /* ── showcase: pinned phone spins like a barber chair between steps ── */
  $$('.show').forEach(function (sec) {
    var steps = $$('.sstep', sec), screens = $$('.scr', sec), bar = $('.show-bar i', sec), tk = $('.show-ticket', sec), phone = $('.show-phone', sec);
    var n = steps.length;
    gsap.set($('.show-stage', sec), { perspective: 1300 });
    gsap.set(steps.slice(1), { autoAlpha: 0, y: 50 });
    gsap.set(screens.slice(1), { autoAlpha: 0 });
    if (tk) gsap.set(tk, { autoAlpha: 0, x: -30, scale: .9 });
    var tl = gsap.timeline({ defaults: { ease: 'power2.inOut', duration: 1 },
      scrollTrigger: { trigger: sec, start: 'top top', end: '+=' + (n * 90) + '%', pin: true, scrub: .7,
        snap: { snapTo: 'labelsDirectional', duration: { min: .2, max: .6 }, delay: .05, ease: 'power2.inOut' } } });
    tl.addLabel('s0').to({}, { duration: .4 });
    for (var i = 1; i < n; i++) {
      tl.to(steps[i - 1], { autoAlpha: 0, y: -50, duration: .5 })
        .to(phone, { rotationY: -90, duration: .5, ease: 'power2.in' }, '<')
        .set(screens[i - 1], { autoAlpha: 0 })
        .set(screens[i], { autoAlpha: 1 })
        .fromTo(phone, { rotationY: 90 }, { rotationY: 0, duration: .5, ease: 'power2.out', immediateRender: false })
        .to(steps[i], { autoAlpha: 1, y: 0, duration: .5 }, '<')
        .fromTo($('.snum', steps[i]), { xPercent: -30 }, { xPercent: 0, duration: .5 }, '<');
      if (tk && i === n - 1) tl.to(tk, { autoAlpha: 1, x: 0, scale: 1, duration: .4, ease: 'expo.out', onComplete: function () { tk.classList.add('done'); } }, '>-.15');
      tl.addLabel('s' + i).to({}, { duration: .4 });
    }
    tl.fromTo(bar, { scaleX: 1 / n }, { scaleX: 1, ease: 'none', duration: tl.duration() }, 0);
    gsap.from($('.phone-rise', sec), { y: 120, rotate: 6, autoAlpha: 0, duration: 1.2, ease: 'expo.out', scrollTrigger: { trigger: sec, start: 'top 75%' } });
    gsap.to($('.show-glow', sec), { scale: 1.25, duration: 3, yoyo: true, repeat: -1, ease: 'sine.inOut' });
  });

  /* ── scissors cut along the dashed line ── */
  $$('.cut').forEach(function (c) {
    var sc = $('.cut-sc', c), dn = $('.cut-done', c), track = $('.cut-track', c);
    gsap.timeline({ scrollTrigger: { trigger: c, start: 'top 90%', end: 'top 30%', scrub: .6 } })
      .to(sc, { x: function () { return track.offsetWidth - sc.offsetWidth + 8; }, ease: 'none' }, 0)
      .to(dn, { scaleX: 1, ease: 'none' }, 0);
  });

  /* ── AI scan ── */
  var scanEl = $('.scan');
  if (scanEl) {
    gsap.timeline({ scrollTrigger: { trigger: scanEl, start: 'top 75%' } })
      .from(scanEl, { scale: .85, autoAlpha: 0, duration: 1.2, ease: 'expo.out' })
      .to($$('.scan-mesh line', scanEl), { strokeDashoffset: 0, duration: 1.4, stagger: .06, ease: 'power2.out' }, .3)
      .from($$('.scan-mesh circle', scanEl), { scale: 0, duration: .6, stagger: .07, ease: 'expo.out' }, .3)
      .from($$('.scan-tag', scanEl), { y: 24, autoAlpha: 0, scale: .9, duration: .9, stagger: .2, ease: 'expo.out' }, .9);
    gsap.to($$('.scan-tag', scanEl), { y: -8, duration: 2.2, yoyo: true, repeat: -1, ease: 'sine.inOut', stagger: .6 });
    var cyc = $('.cycle', scanEl);
    if (cyc) {
      var cw = cyc.dataset.words.split('|'), ck = 0;
      setInterval(function () {
        ck = (ck + 1) % cw.length;
        gsap.timeline().to(cyc, { yPercent: -60, autoAlpha: 0, duration: .25, ease: 'power2.in' })
          .add(function () { cyc.textContent = cw[ck]; })
          .fromTo(cyc, { yPercent: 60, autoAlpha: 0 }, { yPercent: 0, autoAlpha: 1, duration: .45, ease: 'expo.out' });
      }, 2200);
    }
    gsap.to('.ai-in', { y: -40, ease: 'none', scrollTrigger: { trigger: '.ai', start: 'top bottom', end: 'bottom top', scrub: true } });
  }

  /* ── demos slide in ── */
  $$('.booth, .desk').forEach(function (b) {
    gsap.from(b, { y: 90, rotate: -3, autoAlpha: 0, duration: 1.2, ease: 'expo.out', scrollTrigger: { trigger: b, start: 'top 82%' } });
  });

  /* ── punch card ── */
  var punch = $('.punch');
  if (punch) {
    gsap.timeline({ scrollTrigger: { trigger: punch, start: 'top 72%' } })
      .from(punch, { rotate: -6, y: 80, autoAlpha: 0, duration: 1.2, ease: 'expo.out' })
      .from($$('.holes i b', punch).slice(0, 11), { scale: 2.4, autoAlpha: 0, rotate: -40, duration: .5, ease: 'expo.out', stagger: .09 }, .4)
      .to(punch, { keyframes: [{ rotate: 2.8, duration: .08 }, { rotate: 2, duration: .2 }] }, '>-.1');
  }

  /* ── cards / steps / band / final ── */
  $$('.perks').forEach(function (g) {
    gsap.from($$('.perk', g), { y: 60, autoAlpha: 0, rotate: 2, duration: 1, stagger: .08, ease: 'expo.out', scrollTrigger: { trigger: g, start: 'top 82%' } });
  });
  $$('.join').forEach(function (j) {
    gsap.from($$('li', j), { x: 40, autoAlpha: 0, duration: .9, stagger: .12, ease: 'expo.out', scrollTrigger: { trigger: j, start: 'top 80%' } });
  });
  $$('.faq').forEach(function (f) {
    gsap.from($$('.qa', f), { y: 30, autoAlpha: 0, duration: .8, stagger: .06, ease: 'expo.out', scrollTrigger: { trigger: f, start: 'top 85%' } });
  });
  $$('.band').forEach(function (b) {
    gsap.from(b, { clipPath: 'inset(12% 8% 12% 8% round 36px)', duration: 1.4, ease: 'expo.out', scrollTrigger: { trigger: b, start: 'top 85%' } });
  });
  $$('.final').forEach(function (f) {
    gsap.fromTo($('.final-word', f), { backgroundPosition: '100% 0', scale: .9 }, { backgroundPosition: '0% 0', scale: 1, ease: 'none',
      scrollTrigger: { trigger: f, start: 'top bottom', end: 'center center', scrub: true } });
    gsap.from($('.btn-play', f), { y: 30, autoAlpha: 0, duration: 1, ease: 'expo.out', scrollTrigger: { trigger: f, start: 'top 60%' } });
  });

  /* ── barber-pole reading progress ── */
  gsap.to('.progress', { scaleX: 1, ease: 'none', scrollTrigger: { start: 0, end: 'max', scrub: .3 } });

  /* ── desktop: cursor, snips on click, magnetic buttons, tilting cards ── */
  if (fine) {
    var ring = $('.cursor'), dot = $('.cursor-dot');
    var mx = gsap.quickTo(ring, 'x', { duration: .45, ease: 'power3' }), my = gsap.quickTo(ring, 'y', { duration: .45, ease: 'power3' });
    var dx = gsap.quickTo(dot, 'x', { duration: .08 }), dy = gsap.quickTo(dot, 'y', { duration: .08 });
    addEventListener('pointermove', function (e) { if (e.pointerType === 'mouse') html.classList.add('has-cursor'); mx(e.clientX); my(e.clientY); dx(e.clientX); dy(e.clientY); });
    addEventListener('pointerdown', function (e) { ring.classList.add('down'); if (e.pointerType === 'mouse') fx.burst(e.clientX, e.clientY, 7, [ACC, INK, GOLD], 190); });
    addEventListener('pointerup', function () { ring.classList.remove('down'); });
    document.addEventListener('pointerover', function (e) { if (e.target.closest && e.target.closest('a,button,summary')) ring.classList.add('hover'); });
    document.addEventListener('pointerout', function (e) { if (e.target.closest && e.target.closest('a,button,summary')) ring.classList.remove('hover'); });
    html.addEventListener('pointerleave', function () { html.classList.remove('has-cursor'); });

    $$('.mag').forEach(function (b) {
      var bx = gsap.quickTo(b, 'x', { duration: .5, ease: 'power3' }), by = gsap.quickTo(b, 'y', { duration: .5, ease: 'power3' });
      b.addEventListener('pointermove', function (e) {
        var r = b.getBoundingClientRect();
        bx((e.clientX - r.left - r.width / 2) * .3); by((e.clientY - r.top - r.height / 2) * .4);
      });
      b.addEventListener('pointerleave', function () { bx(0); by(0); });
    });
    $$('.tilt-card').forEach(function (c) {
      var tx = gsap.quickTo(c, 'rotationY', { duration: .6, ease: 'power3' }), ty = gsap.quickTo(c, 'rotationX', { duration: .6, ease: 'power3' });
      gsap.set(c, { transformPerspective: 800 });
      c.addEventListener('pointermove', function (e) {
        var r = c.getBoundingClientRect();
        tx(((e.clientX - r.left) / r.width - .5) * 12); ty(-((e.clientY - r.top) / r.height - .5) * 12);
      });
      c.addEventListener('pointerleave', function () { tx(0); ty(0); });
    });
  }

  addEventListener('load', function () { ScrollTrigger.refresh(); });
})();
