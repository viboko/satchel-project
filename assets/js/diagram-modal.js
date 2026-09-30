// Renders the page's mermaid diagrams, then lets each one be opened full
// size in a modal dialog, since many render too small to read in the page.
(() => {
  // Mermaid gives some shapes (e.g. sequence-diagram actor figures) ids
  // that aren't unique, even within one diagram. Nothing refers to them, so
  // give each clashing element its own numbered id.
  const dedupeIds = (svgs) => {
    const counts = new Map();
    document.querySelectorAll("[id]").forEach((el) => {
      counts.set(el.id, (counts.get(el.id) || 0) + 1);
    });

    let n = 0;
    svgs.forEach((svg) => {
      svg.querySelectorAll("[id]").forEach((el) => {
        if (counts.get(el.id) > 1) el.id = `${svg.id}-${el.id}-${++n}`;
      });
    });
  };

  const buildDialog = () => {
    const dialog = document.createElement("dialog");
    dialog.className = "diagram-modal";
    dialog.setAttribute("aria-label", "Diagram");
    dialog.innerHTML = `
      <div class="diagram-modal__bar">
        <button type="button" class="button diagram-modal__close">Close</button>
      </div>
      <div class="diagram-modal__body"></div>`;
    document.body.append(dialog);
    return dialog;
  };

  const setUp = (diagrams) => {
    const dialog = buildDialog();
    const body = dialog.querySelector(".diagram-modal__body");
    let current = null;

    // Put the open diagram back in the page.
    const restore = () => {
      if (!current) return;
      const svg = body.querySelector("svg");
      current.insertBefore(svg, current.firstChild);
      current.style.height = "";
      current.focus();
      current = null;
    };

    const open = (diagram) => {
      // In case the dialog was closed with Escape and the close event
      // hasn't fired yet.
      restore();

      const svg = diagram.querySelector("svg");
      if (!svg) return;

      // Move (rather than copy) the svg, so its ids stay unique on the page,
      // and hold the diagram's place so the page doesn't reflow behind.
      diagram.style.height = `${diagram.offsetHeight}px`;
      body.append(svg);
      current = diagram;

      const title = svg.querySelector("title");
      dialog.setAttribute("aria-label", title ? title.textContent : "Diagram");
      dialog.showModal();
    };

    const close = () => {
      dialog.close();
      restore();
    };

    // Escape closes the dialog without going through close(). The event
    // fires asynchronously, so ignore it if a diagram has been opened since.
    dialog.addEventListener("close", () => {
      if (!dialog.open) restore();
    });

    dialog.querySelector(".diagram-modal__close").addEventListener("click", close);

    // A click on the backdrop lands on the dialog element itself, since its
    // content fills the visible box.
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) close();
    });

    diagrams.forEach((diagram) => {
      // Make the diagram itself a button, for keyboard users. A button's
      // content is hidden from assistive tech, so label it with the
      // diagram's title and description.
      const svg = diagram.querySelector("svg");
      const title = svg && svg.querySelector("title");
      const desc = svg && svg.querySelector("desc");
      diagram.tabIndex = 0;
      diagram.setAttribute("role", "button");
      diagram.setAttribute(
        "aria-label",
        title ? `Enlarge diagram: ${title.textContent}` : "Enlarge diagram",
      );
      if (desc && desc.id) diagram.setAttribute("aria-describedby", desc.id);
      diagram.addEventListener("keydown", (event) => {
        if (event.key !== "Enter" && event.key !== " ") return;
        event.preventDefault();
        open(diagram);
      });

      diagram.classList.add("mermaid--expandable");
      diagram.addEventListener("click", () => open(diagram));
    });
  };

  document.addEventListener("DOMContentLoaded", async () => {
    const diagrams = Array.from(document.querySelectorAll(".mermaid"));
    if (diagrams.length === 0 || !window.mermaid) return;

    await window.mermaid.run({ nodes: diagrams });
    dedupeIds(diagrams.map((diagram) => diagram.querySelector("svg")).filter(Boolean));
    setUp(diagrams);
  });
})();
