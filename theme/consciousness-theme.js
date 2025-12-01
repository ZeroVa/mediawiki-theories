(function () {
  var storageKey = "cc-theme";
  var root = document.documentElement;

  function applyTheme(theme) {
    root.setAttribute("data-theme", theme);
    try {
      localStorage.setItem(storageKey, theme);
    } catch (e) {
      /* ignore */
    }
  }

  function getPreferredTheme() {
    try {
      var stored = localStorage.getItem(storageKey);
      if (stored === "light" || stored === "dark") return stored;
    } catch (e) {
      /* ignore */
    }
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  applyTheme(getPreferredTheme());

  function addToggle() {
    var label = root.getAttribute("data-theme") === "dark" ? "Light mode" : "Dark mode";
    var node = mw.util.addPortletLink("p-personal", "#", label, "pt-cc-theme", "Toggle light/dark theme");
    var anchor = node && node.querySelector ? node.querySelector("a") : node;
    if (!anchor) return;

    anchor.classList.add("cc-theme-toggle");
    anchor.addEventListener("click", function (event) {
      event.preventDefault();
      var next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      applyTheme(next);
      anchor.textContent = next === "dark" ? "Light mode" : "Dark mode";
    });
  }

  mw.loader.using("mediawiki.util").then(function () {
    if (typeof $ === "function") {
      $(addToggle);
    } else {
      addToggle();
    }
  });
})();
