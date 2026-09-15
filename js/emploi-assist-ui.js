(function () {
  // Single swap-in for the counsellor UI. Keep this and the [data-emploi-ui]
  // hrefs in sync. Do NOT use https://voicedoc-emploi-api.fly.dev — API-only.
  var EMPLOI_ASSIST_UI_URL = "https://voicedoc-emploi.vercel.app";

  if (!EMPLOI_ASSIST_UI_URL) return;

  document.querySelectorAll("[data-emploi-ui]").forEach(function (el) {
    var link = el;
    if (el.tagName !== "A") {
      link = document.createElement("a");
      link.className = el.className;
      el.parentNode.replaceChild(link, el);
    }

    link.href = EMPLOI_ASSIST_UI_URL;
    link.target = "_blank";
    link.rel = "noopener";
    link.textContent = "Open live demo";
    link.classList.remove("btn-disabled");
    link.removeAttribute("aria-disabled");
    if (!link.classList.contains("btn-primary")) {
      link.classList.add("btn-primary");
    }
  });
})();
