(function () {
  'use strict';
  var html = document.documentElement;
  var reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  var fine = matchMedia('(hover: hover) and (pointer: fine)').matches;
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };

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
    if (window.ScrollTrigger) ScrollTrigger.refresh();
  }
  $$('.langs button').forEach(function (b) { b.addEventListener('click', function () { setLang(b.dataset.set); }); });
  setLang(lang);

  /* ── FAQ: smooth open/close (works without GSAP) ── */
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
  function onScroll() { top.classList.toggle('scrolled', scrollY > 10); }
  addEventListener('scroll', onScroll, { passive: true }); onScroll();

  if (reduce || !window.gsap || !window.ScrollTrigger) {
    html.classList.remove('js', 'intro');
    return;
  }
  gsap.registerPlugin(ScrollTrigger);

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

  /* ── intro: a scissor cut opens the page ── */
  var playIntro = html.classList.contains('intro');
  var introTL = gsap.timeline({ paused: !playIntro });
  if (playIntro) {
    var ov = $('.intro-ov');
    introTL
      .to('.intro-word', { opacity: 1, duration: .35, ease: 'power2.out' }, 0)
      .fromTo('.intro-word', { scale: .92 }, { scale: 1, duration: .9, ease: 'expo.out' }, 0)
      .to('.intro-sc', { x: function () { return innerWidth + 40; }, duration: .85, ease: 'power2.inOut' }, .15)
      .to('.intro-line', { scaleX: 1, duration: .85, ease: 'power2.inOut' }, .15)
      .to('.intro-word', { opacity: 0, y: -10, duration: .25 }, .78)
      .to('.intro-a', { yPercent: -101, duration: .9, ease: 'expo.inOut' }, .95)
      .to('.intro-b', { yPercent: 101, duration: .9, ease: 'expo.inOut' }, .95)
      .to('.intro-line', { opacity: 0, duration: .2 }, .95)
      .add(function () { html.classList.remove('intro'); ov.remove(); });
  } else {
    html.classList.remove('intro');
  }

  /* ── hero entrance ── */
  var hero = $('.hero');
  if (hero) {
    var tl = gsap.timeline({ delay: playIntro ? 1.15 : .15, defaults: { ease: 'expo.out' } });
    tl.from(cur('.c', $('h1', hero)), { yPercent: 115, rotate: 7, duration: 1.1, stagger: .016 })
      .from($('.eyebrow', hero), { y: 18, autoAlpha: 0, duration: .8 }, 0)
      .add(function () { hero.classList.add('lit'); }, .55)
      .from([$('.lead', hero)].concat($$('.cta-row > *', hero), $$('.ticks li', hero)), { y: 26, autoAlpha: 0, duration: .9, stagger: .06 }, .35)
      .from($('.pole', hero), { scaleY: 0, transformOrigin: '50% 100%', duration: 1.3 }, .1)
      .from($('.phone-wrap', hero), { y: 160, rotate: -10, autoAlpha: 0, duration: 1.4 }, .2)
      .from($$('.sticker', hero), { scale: 0, rotate: -50, autoAlpha: 0, duration: 1.1, stagger: .12 }, .65)
      .from($('.ticket', hero), { x: 40, autoAlpha: 0, duration: 1 }, .95)
      .add(function () { var t = $('.ticket', hero); if (t) t.classList.add('done'); }, 1.25)
      .from($('.scroll-hint', hero), { autoAlpha: 0, duration: .6 }, 1.2);
    hero.style.visibility = 'visible';

    /* scroll: stickers drift, phone sinks, copy lifts away */
    gsap.to($$('.sticker', hero), { yPercent: function (i, el) { return -60 * (parseFloat(el.dataset.depth) || 1); }, ease: 'none',
      scrollTrigger: { trigger: hero, start: 'top top', end: 'bottom top', scrub: true } });
    gsap.to($('.phone-wrap', hero), { y: 90, ease: 'none', scrollTrigger: { trigger: hero, start: 'top top', end: 'bottom top', scrub: true } });
    gsap.to($('.pole', hero), { y: -60, rotate: 22, ease: 'none', scrollTrigger: { trigger: hero, start: 'top top', end: 'bottom top', scrub: true } });

    /* pointer: phone tilts toward the cursor, stickers parallax */
    if (fine) {
      var art = $('.hero-art', hero), ph = $('.hero-phone', hero);
      var rx = gsap.quickTo(ph, 'rotationX', { duration: .8, ease: 'power3' });
      var ry = gsap.quickTo(ph, 'rotationY', { duration: .8, ease: 'power3' });
      var sts = $$('.sticker', hero).map(function (s) { return { x: gsap.quickTo(s, 'x', { duration: 1, ease: 'power3' }), y: gsap.quickTo(s, 'y', { duration: 1, ease: 'power3' }), d: parseFloat(s.dataset.depth) || 1 }; });
      hero.addEventListener('pointermove', function (e) {
        var r = art.getBoundingClientRect();
        var px = (e.clientX - r.left) / r.width - .5, py = (e.clientY - r.top) / r.height - .5;
        ry(px * 16); rx(-py * 12);
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
      gsap.from(words, { yPercent: 110, rotate: 4, duration: 1, ease: 'expo.out', stagger: .045,
        scrollTrigger: { trigger: h, start: 'top 86%' } });
    });
  });
  $$('.fade-up, .lead:not(.hero .lead)').forEach(function (el) {
    gsap.from(el, { y: 30, autoAlpha: 0, duration: 1, ease: 'expo.out', scrollTrigger: { trigger: el, start: 'top 88%' } });
  });

  /* ── marquee: endless, speeds up and skews with scroll velocity ── */
  $$('.marquee').forEach(function (m) {
    var tracks = $$('.mq-track', m);
    var loop = gsap.to(tracks, { xPercent: -50, duration: 34, ease: 'none', repeat: -1 });
    var skew = gsap.quickTo(tracks, 'skewX', { duration: .5, ease: 'power3' });
    var idle;
    ScrollTrigger.create({ trigger: m, start: 'top bottom', end: 'bottom top', onUpdate: function (self) {
      var v = self.getVelocity(), dir = self.direction;
      gsap.to(loop, { timeScale: dir * (1 + Math.min(Math.abs(v) / 300, 6)), duration: .2, overwrite: true });
      skew(gsap.utils.clamp(-10, 10, -v / 250));
      clearTimeout(idle);
      idle = setTimeout(function () { gsap.to(loop, { timeScale: dir, duration: 1.2, overwrite: true }); skew(0); }, 140);
    } });
    gsap.to($$('.mq-dot', m), { rotate: 360, duration: 6, repeat: -1, ease: 'none' });
  });

  /* ── showcase: phone pinned, screens + steps change with scroll ── */
  $$('.show').forEach(function (sec) {
    var steps = $$('.sstep', sec), screens = $$('.scr', sec), bar = $('.show-bar i', sec), tk = $('.show-ticket', sec);
    var n = steps.length;
    gsap.set(steps.slice(1), { autoAlpha: 0, y: 50 });
    gsap.set(screens.slice(1), { autoAlpha: 0, scale: 1.08 });
    if (tk) gsap.set(tk, { autoAlpha: 0, x: -30, scale: .9 });
    var tl = gsap.timeline({ defaults: { ease: 'power2.inOut', duration: 1 },
      scrollTrigger: { trigger: sec, start: 'top top', end: '+=' + (n * 90) + '%', pin: true, scrub: .7,
        snap: { snapTo: 'labelsDirectional', duration: { min: .2, max: .6 }, delay: .05, ease: 'power2.inOut' } } });
    tl.addLabel('s0').to({}, { duration: .4 });
    for (var i = 1; i < n; i++) {
      tl.to(steps[i - 1], { autoAlpha: 0, y: -50 })
        .to(screens[i - 1], { autoAlpha: 0, scale: .94 }, '<')
        .to(steps[i], { autoAlpha: 1, y: 0 }, '<.15')
        .to(screens[i], { autoAlpha: 1, scale: 1 }, '<')
        .fromTo($('.snum', steps[i]), { xPercent: -30 }, { xPercent: 0 }, '<');
      if (tk && i === n - 1) tl.to(tk, { autoAlpha: 1, x: 0, scale: 1, ease: 'expo.out', onComplete: function () { tk.classList.add('done'); } }, '<.4');
      tl.addLabel('s' + i).to({}, { duration: .4 });
    }
    tl.fromTo(bar, { scaleX: 1 / n }, { scaleX: 1, ease: 'none', duration: tl.duration() }, 0);
    gsap.from($('.show-phone', sec), { y: 120, rotate: 6, autoAlpha: 0, duration: 1.2, ease: 'expo.out', scrollTrigger: { trigger: sec, start: 'top 75%' } });
    gsap.to($('.show-glow', sec), { scale: 1.25, duration: 3, yoyo: true, repeat: -1, ease: 'sine.inOut' });
  });

  /* ── scissors cut along the dashed line ── */
  $$('.cut').forEach(function (c) {
    var sc = $('.cut-sc', c), done = $('.cut-done', c), track = $('.cut-track', c);
    var tl = gsap.timeline({ scrollTrigger: { trigger: c, start: 'top 90%', end: 'top 30%', scrub: .6 } });
    tl.to(sc, { x: function () { return track.offsetWidth - sc.offsetWidth + 8; }, ease: 'none' }, 0)
      .to(done, { scaleX: 1, ease: 'none' }, 0);
  });

  /* ── AI scan: mesh draws itself, dots pop, styles cycle ── */
  var scanEl = $('.scan');
  if (scanEl) {
    var stl = gsap.timeline({ scrollTrigger: { trigger: scanEl, start: 'top 75%' } });
    stl.from(scanEl, { scale: .85, autoAlpha: 0, duration: 1.2, ease: 'expo.out' })
      .to($$('.scan-mesh line', scanEl), { strokeDashoffset: 0, duration: 1.4, stagger: .06, ease: 'power2.out' }, .3)
      .from($$('.scan-mesh circle', scanEl), { scale: 0, duration: .6, stagger: .07, ease: 'expo.out' }, .3)
      .from($$('.scan-tag', scanEl), { y: 24, autoAlpha: 0, scale: .9, duration: .9, stagger: .2, ease: 'expo.out' }, .9);
    gsap.to($$('.scan-tag', scanEl), { y: -8, duration: 2.2, yoyo: true, repeat: -1, ease: 'sine.inOut', stagger: .6 });
    var cyc = $('.cycle', scanEl);
    if (cyc) {
      var words = cyc.dataset.words.split('|'), k = 0;
      setInterval(function () {
        k = (k + 1) % words.length;
        gsap.timeline().to(cyc, { yPercent: -60, autoAlpha: 0, duration: .25, ease: 'power2.in' })
          .add(function () { cyc.textContent = words[k]; })
          .fromTo(cyc, { yPercent: 60, autoAlpha: 0 }, { yPercent: 0, autoAlpha: 1, duration: .45, ease: 'expo.out' });
      }, 2200);
    }
    gsap.to($('.ai-in', document), { y: -40, ease: 'none', scrollTrigger: { trigger: '.ai', start: 'top bottom', end: 'bottom top', scrub: true } });
  }

  /* ── punch card: each visit stamps a hole ── */
  var punch = $('.punch');
  if (punch) {
    var holes = $$('.holes i b', punch).slice(0, 11);
    gsap.timeline({ scrollTrigger: { trigger: punch, start: 'top 72%' } })
      .from(punch, { rotate: -6, y: 80, autoAlpha: 0, duration: 1.2, ease: 'expo.out' })
      .from(holes, { scale: 2.4, autoAlpha: 0, rotate: -40, duration: .5, ease: 'expo.out', stagger: .09,
        onStart: function () {} }, .4)
      .to(punch, { keyframes: [{ rotate: 2.8, duration: .08 }, { rotate: 2, duration: .2 }] }, '>-.1');
  }

  /* ── cards / steps / band / final ── */
  gsap.utils.toArray('.perks').forEach(function (g) {
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
    var w = $('.final-word', f);
    gsap.fromTo(w, { backgroundPosition: '100% 0', scale: .9 }, { backgroundPosition: '0% 0', scale: 1, ease: 'none',
      scrollTrigger: { trigger: f, start: 'top bottom', end: 'center center', scrub: true } });
    gsap.from($('.btn-play', f), { y: 30, autoAlpha: 0, duration: 1, ease: 'expo.out', scrollTrigger: { trigger: f, start: 'top 60%' } });
  });

  /* ── reading progress ── */
  gsap.to('.progress', { scaleX: 1, ease: 'none', scrollTrigger: { start: 0, end: 'max', scrub: .3 } });

  /* ── desktop: custom cursor, magnetic buttons, tilting cards ── */
  if (fine) {
    var ring = $('.cursor'), dot = $('.cursor-dot');
    var mx = gsap.quickTo(ring, 'x', { duration: .45, ease: 'power3' }), my = gsap.quickTo(ring, 'y', { duration: .45, ease: 'power3' });
    var dx = gsap.quickTo(dot, 'x', { duration: .08 }), dy = gsap.quickTo(dot, 'y', { duration: .08 });
    addEventListener('pointermove', function (e) { if (e.pointerType === 'mouse') html.classList.add('has-cursor'); mx(e.clientX); my(e.clientY); dx(e.clientX); dy(e.clientY); });
    addEventListener('pointerdown', function () { ring.classList.add('down'); });
    addEventListener('pointerup', function () { ring.classList.remove('down'); });
    document.addEventListener('pointerover', function (e) { if (e.target.closest('a,button,summary')) ring.classList.add('hover'); });
    document.addEventListener('pointerout', function (e) { if (e.target.closest('a,button,summary')) ring.classList.remove('hover'); });
    document.addEventListener('pointerleave', function () { html.classList.remove('has-cursor'); });
    document.addEventListener('pointerenter', function () { html.classList.add('has-cursor'); });

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
