(function(){
  function animateStat(el){
    var text = el.textContent.trim();
    var m = text.match(/^(\d+(?:\.\d+)?)(.*)$/);
    if (!m) return;
    var target = parseFloat(m[1]);
    var suffix = m[2];
    var isDecimal = m[1].indexOf('.') !== -1;
    var duration = 900;
    var startTime = null;
    function step(ts){
      if (!startTime) startTime = ts;
      var progress = Math.min((ts - startTime) / duration, 1);
      var current = target * progress;
      el.textContent = (isDecimal ? current.toFixed(1) : Math.floor(current)) + suffix;
      if (progress < 1) requestAnimationFrame(step);
      else el.textContent = (isDecimal ? target.toFixed(1) : target) + suffix;
    }
    requestAnimationFrame(step);
  }
  var nums = document.querySelectorAll('.stat-num');
  if (!nums.length) return;
  var seen = new WeakSet();
  var obs = new IntersectionObserver(function(entries){
    entries.forEach(function(entry){
      if (entry.isIntersecting && !seen.has(entry.target)) {
        seen.add(entry.target);
        animateStat(entry.target);
        obs.unobserve(entry.target);
      }
    });
  }, {threshold:0.4});
  nums.forEach(function(el){ obs.observe(el); });
})();
