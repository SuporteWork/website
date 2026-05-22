(function () {
  'use strict';

  const MOBILE_NAV_MQ = window.matchMedia('(max-width: 1199px)');
  const headerToggleBtn = document.querySelector('.header-toggle');
  const header = document.querySelector('#header');
  const navmenu = document.querySelector('#navmenu');
  const main = document.querySelector('#main');
  let mobileNavTrigger = null;

  function isMobileNav() {
    return MOBILE_NAV_MQ.matches;
  }

  function setMobileNavOpen(isOpen) {
    if (!header || !headerToggleBtn) return;

    header.classList.toggle('header-show', isOpen);
    headerToggleBtn.classList.toggle('bi-list', !isOpen);
    headerToggleBtn.classList.toggle('bi-x', isOpen);
    headerToggleBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    headerToggleBtn.setAttribute('aria-label', isOpen ? 'Fechar menu de navegação' : 'Abrir menu de navegação');

    if (isOpen) {
      mobileNavTrigger = document.activeElement;
      main?.setAttribute('inert', '');
      const firstLink = navmenu?.querySelector('a');
      firstLink?.focus();
    } else {
      main?.removeAttribute('inert');
      if (mobileNavTrigger) {
        mobileNavTrigger.focus();
        mobileNavTrigger = null;
      }
    }
  }

  function closeMobileNav() {
    if (header?.classList.contains('header-show')) {
      setMobileNavOpen(false);
    }
  }

  if (headerToggleBtn) {
    headerToggleBtn.addEventListener('click', () => {
      setMobileNavOpen(!header?.classList.contains('header-show'));
    });
  }

  document.querySelectorAll('#navmenu a').forEach((link) => {
    link.addEventListener('click', () => {
      if (isMobileNav()) {
        closeMobileNav();
      }
    });
  });

  document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape' || !isMobileNav() || !header?.classList.contains('header-show')) {
      return;
    }
    e.preventDefault();
    closeMobileNav();
  });

  if (navmenu && header) {
    navmenu.addEventListener('keydown', (e) => {
      if (e.key !== 'Tab' || !isMobileNav() || !header.classList.contains('header-show')) {
        return;
      }

      const focusable = navmenu.querySelectorAll('a[href]');
      if (!focusable.length) return;

      const first = focusable[0];
      const last = focusable[focusable.length - 1];

      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    });
  }

  const skipLink = document.querySelector('.skip-link');
  if (skipLink && main) {
    skipLink.addEventListener('click', () => {
      main.focus({ preventScroll: false });
    });
  }

  const scrollTop = document.querySelector('.scroll-top');

  function toggleScrollTop() {
    if (scrollTop) {
      window.scrollY > 100 ? scrollTop.classList.add('active') : scrollTop.classList.remove('active');
    }
  }

  if (scrollTop) {
    scrollTop.addEventListener('click', () => {
      const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      window.scrollTo({
        top: 0,
        behavior: prefersReducedMotion ? 'auto' : 'smooth'
      });
    });
  }

  const navmenulinks = document.querySelectorAll('.navmenu a');

  function navmenuScrollspy() {
    navmenulinks.forEach((navmenulink) => {
      if (!navmenulink.hash) return;
      const section = document.querySelector(navmenulink.hash);
      if (!section) return;
      const position = window.scrollY + 200;
      if (position >= section.offsetTop && position <= section.offsetTop + section.offsetHeight) {
        document.querySelectorAll('.navmenu a.active').forEach((link) => link.classList.remove('active'));
        navmenulink.classList.add('active');
      } else {
        navmenulink.classList.remove('active');
      }
    });
  }

  let scrollTicking = false;

  function onScroll() {
    if (!scrollTicking) {
      requestAnimationFrame(() => {
        toggleScrollTop();
        navmenuScrollspy();
        scrollTicking = false;
      });
      scrollTicking = true;
    }
  }

  document.addEventListener('scroll', onScroll, { passive: true });

  function initTyped() {
    const selectTyped = document.querySelector('.typed');
    if (!selectTyped) return;

    const typedItems = (selectTyped.getAttribute('data-typed-items') || '')
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);

    if (!typedItems.length) return;

    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    if (prefersReducedMotion || typeof Typed === 'undefined') {
      selectTyped.textContent = typedItems[0];
      return;
    }

    new Typed('.typed', {
      strings: typedItems,
      loop: true,
      typeSpeed: 100,
      backSpeed: 50,
      backDelay: 2000
    });
  }

  function onWindowLoad() {
    const copyrightYear = document.querySelector('#copyright-year');
    if (copyrightYear) {
      copyrightYear.textContent = new Date().getFullYear();
    }

    toggleScrollTop();
    initTyped();

    if (typeof AOS !== 'undefined') {
      AOS.init({
        duration: 600,
        easing: 'ease-in-out',
        once: true,
        mirror: false,
        disable: () => window.matchMedia('(prefers-reduced-motion: reduce)').matches
      });
    }

    navmenuScrollspy();

    if (window.location.hash) {
      let section = null;
      try {
        section = document.querySelector(window.location.hash);
      } catch (_) {
        section = null;
      }

      if (section) {
        setTimeout(() => {
          const scrollMarginTop = parseInt(getComputedStyle(section).scrollMarginTop, 10) || 0;
          const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
          window.scrollTo({
            top: section.offsetTop - scrollMarginTop,
            behavior: prefersReducedMotion ? 'auto' : 'smooth'
          });
        }, 100);
      }
    }
  }

  window.addEventListener('load', onWindowLoad);
})();
