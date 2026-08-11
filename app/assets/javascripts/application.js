document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll("[data-sidebar-open]").forEach(function (button) {
    button.addEventListener("click", function () {
      document.body.classList.add("sidebar-open");
    });
  });

  document.querySelectorAll("[data-sidebar-close]").forEach(function (button) {
    button.addEventListener("click", function () {
      document.body.classList.remove("sidebar-open");
    });
  });

  document.querySelectorAll("[data-row-link]").forEach(function (row) {
    row.addEventListener("click", function () {
      window.location.href = row.getAttribute("data-row-link");
    });
  });
});
