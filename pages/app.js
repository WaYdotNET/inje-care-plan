(() => {
  const STORAGE_KEY = "injecare_lang";
  const supported = new Set(["it", "en"]);

  function getInitialLang() {
    const fromStorage = (localStorage.getItem(STORAGE_KEY) || "").toLowerCase();
    if (supported.has(fromStorage)) return fromStorage;

    const nav = (navigator.language || "it").toLowerCase();
    if (nav.startsWith("en")) return "en";
    return "it";
  }

  function setLang(lang) {
    if (!supported.has(lang)) return;
    document.documentElement.setAttribute("data-lang", lang);
    localStorage.setItem(STORAGE_KEY, lang);

    const itBtn = document.querySelector("[data-set-lang='it']");
    const enBtn = document.querySelector("[data-set-lang='en']");
    if (itBtn) itBtn.setAttribute("aria-pressed", String(lang === "it"));
    if (enBtn) enBtn.setAttribute("aria-pressed", String(lang === "en"));
  }

  document.addEventListener("click", (e) => {
    const target = e.target;
    if (!(target instanceof Element)) return;
    const btn = target.closest("[data-set-lang]");
    if (!btn) return;
    const lang = btn.getAttribute("data-set-lang");
    if (!lang) return;
    setLang(lang);
  });

  setLang(getInitialLang());
})();
