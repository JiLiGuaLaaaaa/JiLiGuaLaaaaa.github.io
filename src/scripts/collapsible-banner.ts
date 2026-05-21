const banners = Array.from(document.querySelectorAll<HTMLElement>("[data-collapsible-banner]"));

const updateBanners = () => {
  const shouldCollapse = window.scrollY > 36;
  for (const banner of banners) {
    banner.classList.toggle("is-collapsed", shouldCollapse);
  }
};

if (banners.length > 0) {
  updateBanners();
  window.addEventListener("scroll", updateBanners, { passive: true });
}
