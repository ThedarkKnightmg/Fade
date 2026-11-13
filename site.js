(function(){
var ok=['uz','ru','en'],P=new URLSearchParams(location.search),l=P.get('lang');
try{if(ok.indexOf(l)<0)l=localStorage.getItem('fade-lang')}catch(e){}
if(ok.indexOf(l)<0){var n=(navigator.language||'').slice(0,2);l=n==='ru'?'ru':n==='en'?'en':'uz'}
var titles={uz:document.title,ru:document.title,en:document.title};
function set(x){document.body.className=x;document.documentElement.lang=x;
 document.querySelectorAll('.langs button').forEach(function(b){b.classList.toggle('on',b.dataset.set===x);b.setAttribute('aria-pressed',b.dataset.set===x)});
 try{localStorage.setItem('fade-lang',x)}catch(e){}}
document.querySelectorAll('.langs button').forEach(function(b){b.onclick=function(){set(b.dataset.set)}});set(l);
var els=document.querySelectorAll('.reveal');
if(!('IntersectionObserver' in window)){els.forEach(function(e){e.classList.add('in')});return}
var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('in');io.unobserve(e.target)}})},{threshold:.15,rootMargin:'0px 0px -40px 0px'});
els.forEach(function(e){io.observe(e)});
})();
