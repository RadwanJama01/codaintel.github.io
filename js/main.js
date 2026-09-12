(function () {
  const toggle = document.querySelector('.menu-toggle');
  const nav = document.querySelector('.site-nav');

  if (toggle && nav) {
    toggle.addEventListener('click', function () {
      nav.classList.toggle('open');
      const expanded = nav.classList.contains('open');
      toggle.setAttribute('aria-expanded', expanded);
    });

    nav.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        nav.classList.remove('open');
        toggle.setAttribute('aria-expanded', 'false');
      });
    });
  }

  document.querySelectorAll('form.contact').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      const name = (form.name && form.name.value) || '';
      const email = (form.email && form.email.value) || '';
      const org = (form.org && form.org.value) || '';
      const role = (form.role && form.role.value) || '';
      const interest = (form.interest && form.interest.value) || '';
      const subject = encodeURIComponent('Phoenix Rising Group — inquiry from ' + name);
      const body = encodeURIComponent(
        'Name: ' + name +
        '\nEmail: ' + email +
        '\nOrganization: ' + org +
        '\nRole: ' + role +
        '\n\n' + interest
      );
      window.location.href = 'mailto:radwanjama099@gmail.com?subject=' + subject + '&body=' + body;
    });
  });

  const fills = document.querySelectorAll('.metric-fill');
  if (fills.length && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.style.width = entry.target.dataset.width || entry.target.style.width;
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.3 });

    fills.forEach(function (fill) {
      const target = fill.dataset.width;
      if (target) {
        fill.style.width = '0%';
        observer.observe(fill);
      }
    });
  }

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!reduceMotion && 'IntersectionObserver' in window) {
    var revealables = document.querySelectorAll('.hero .spine, .eval-card, .card, .about-aside, .timeline');
    var revealObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          revealObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });

    revealables.forEach(function (el) {
      el.classList.add('reveal');
      revealObserver.observe(el);
    });
  }
})();