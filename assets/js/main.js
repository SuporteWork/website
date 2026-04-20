(function() {
  "use strict";

  /**
   * Header toggle
   */
  const headerToggleBtn = document.querySelector('.header-toggle');
  const header = document.querySelector('#header');

  if (headerToggleBtn) {
    function headerToggle() {
      if (!header) return;

      const isOpen = header.classList.toggle('header-show');
      headerToggleBtn.classList.toggle('bi-list');
      headerToggleBtn.classList.toggle('bi-x');
      headerToggleBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    }
    headerToggleBtn.addEventListener('click', headerToggle);
  }

  /**
   * Hide mobile nav on same-page/hash links
   */
  document.querySelectorAll('#navmenu a').forEach(navmenu => {
    navmenu.addEventListener('click', () => {
      if (headerToggleBtn && document.querySelector('.header-show')) {
        headerToggleBtn.click();
      }
    });
  });

  /**
   * Scroll top button
   */
  const scrollTop = document.querySelector('.scroll-top');
  function toggleScrollTop() {
    if (scrollTop) {
      window.scrollY > 100 ? scrollTop.classList.add('active') : scrollTop.classList.remove('active');
    }
  }
  if (scrollTop) {
    scrollTop.addEventListener('click', (e) => {
      e.preventDefault();
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
  }
  document.addEventListener('scroll', toggleScrollTop, { passive: true });

  /**
   * Navmenu Scrollspy
   */
  const navmenulinks = document.querySelectorAll('.navmenu a');
  function navmenuScrollspy() {
    navmenulinks.forEach(navmenulink => {
      if (!navmenulink.hash) return;
      let section = document.querySelector(navmenulink.hash);
      if (!section) return;
      let position = window.scrollY + 200;
      if (position >= section.offsetTop && position <= (section.offsetTop + section.offsetHeight)) {
        document.querySelectorAll('.navmenu a.active').forEach(link => link.classList.remove('active'));
        navmenulink.classList.add('active');
      } else {
        navmenulink.classList.remove('active');
      }
    })
  }
  document.addEventListener('scroll', navmenuScrollspy, { passive: true });

  /**
   * Init typed.js
   */
  const selectTyped = document.querySelector('.typed');
  if (selectTyped && typeof Typed !== 'undefined') {
    let typed_strings = selectTyped.getAttribute('data-typed-items');
    typed_strings = typed_strings.split(',').map((item) => item.trim()).filter(Boolean);
    new Typed('.typed', {
      strings: typed_strings,
      loop: true,
      typeSpeed: 100,
      backSpeed: 50,
      backDelay: 2000
    });
  }

  /**
   * Functions to run on window load
   */
  function onWindowLoad() {
    // Preloader
    const preloader = document.querySelector('#preloader');
    if (preloader) {
      preloader.remove();
    }

    // Update copyright year
    const copyrightYear = document.querySelector('#copyright-year');
    if (copyrightYear) {
      copyrightYear.textContent = new Date().getFullYear();
    }

    // Scroll top button visibility
    toggleScrollTop();

    // AOS init
    if (typeof AOS !== 'undefined') {
      AOS.init({
        duration: 600,
        easing: 'ease-in-out',
        once: true,
        mirror: false,
        disable: () => window.matchMedia('(prefers-reduced-motion: reduce)').matches
      });
    }

    // Navmenu scrollspy activation
    navmenuScrollspy();

    // Hash link scrolling
    if (window.location.hash) {
      let section = null;
      try {
        section = document.querySelector(window.location.hash);
      } catch (_) {
        section = null;
      }

      if (section) {
        setTimeout(() => {
          let scrollMarginTop = parseInt(getComputedStyle(section).scrollMarginTop, 10) || 0;
          window.scrollTo({
            top: section.offsetTop - scrollMarginTop,
            behavior: 'smooth'
          });
        }, 100);
      }
    }
  }
  window.addEventListener('load', onWindowLoad);

})();
