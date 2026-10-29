(function () {
  var toggle = document.querySelector('.menu-toggle');
  var nav = document.querySelector('.site-nav');

  if (toggle && nav) {
    var setOpen = function (open) {
      nav.classList.toggle('open', open);
      toggle.setAttribute('aria-expanded', String(open));
    };

    toggle.addEventListener('click', function () {
      setOpen(!nav.classList.contains('open'));
    });

    nav.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () { setOpen(false); });
    });
  }

  document.querySelectorAll('form.contact').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var field = function (name) {
        return (form.elements[name] && form.elements[name].value) || '';
      };
      var subject = encodeURIComponent('Phoenix Rising Group: inquiry from ' + field('name'));
      var body = encodeURIComponent(
        'Name: ' + field('name') +
        '\nEmail: ' + field('email') +
        '\nOrganization: ' + field('org') +
        '\nSector: ' + field('sector') +
        '\n\n' + field('message')
      );
      window.location.href = 'mailto:radwanjama099@gmail.com?subject=' + subject + '&body=' + body;
    });
  });

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!reduceMotion && 'IntersectionObserver' in window) {
    var revealObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          revealObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });

    document.querySelectorAll('.index li, .principles > div').forEach(function (el) {
      el.classList.add('reveal');
      revealObserver.observe(el);
    });
  }
})();
