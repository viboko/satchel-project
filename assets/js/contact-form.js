(() => {
  const form = document.getElementById("contact-form");
  if (!form) return;

  const intro = document.getElementById("contact-intro");
  const successMessage = document.getElementById("contact-success");
  const errorMessage = document.getElementById("contact-error");
  const button = form.querySelector("button[type=submit]");
  const buttonDefaultText = button.textContent;

  form.addEventListener("submit", (event) => {
    event.preventDefault();

    errorMessage.hidden = true;
    button.disabled = true;
    button.textContent = "Sending…";

    fetch(form.action, {
      method: "POST",
      body: new FormData(form),
      headers: { Accept: "application/json" },
    })
      .then((response) => {
        if (response.ok) {
          form.hidden = true;
          intro.hidden = true;
          successMessage.hidden = false;
        } else {
          throw new Error("Form submission failed");
        }
      })
      .catch(() => {
        errorMessage.hidden = false;
        button.disabled = false;
        button.textContent = buttonDefaultText;
      });
  });
})();
