const root = document.documentElement;
const boundKey = "collapsibleBannerBound";

const updateBanners = () => {
  const banners = Array.from(document.querySelectorAll<HTMLElement>("[data-collapsible-banner]"));
  const shouldCollapse = window.scrollY > 36;
  for (const banner of banners) {
    banner.classList.toggle("is-collapsed", shouldCollapse);
  }
};

if (!root.dataset[boundKey]) {
  root.dataset[boundKey] = "1";
  updateBanners();
  window.addEventListener("scroll", updateBanners, { passive: true });
  window.addEventListener("resize", updateBanners, { passive: true });
  window.addEventListener("pageshow", updateBanners);
}
