(function () {
  // TODO: When VoiceDoc provides the counsellor UI URL, set EMPLOI_ASSIST_UI_URL
  // here only. Every [data-emploi-ui] control then becomes "Open live demo".
  // Do NOT use https://voicedoc-emploi-api.fly.dev — that host is API-only.
  var EMPLOI_ASSIST_UI_URL = "";

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
  });
})();
