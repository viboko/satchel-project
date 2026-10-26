(() => {
  // Adds a copy button to each code block in a `.run-locally` section: the
  // commands a reader is meant to paste into a terminal. The quoted source
  // code elsewhere in a post isn't meant to be copied, so it gets none.
  const icon = (paths) =>
    `<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true" focusable="false"
      fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
      stroke-linejoin="round">${paths}</svg>`;
  const COPY_ICON = icon(
    '<rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v1"/>',
  );
  const TICK_ICON = icon('<path d="M4 12.5l5 5L20 6.5"/>');
  const LABEL = "Copy these commands";

  document.querySelectorAll(".run-locally .highlighter-rouge").forEach((block) => {
    const pre = block.querySelector("pre");
    if (!pre || !navigator.clipboard) return;

    const button = document.createElement("button");
    button.type = "button";
    button.className = "copy-code";
    button.innerHTML = COPY_ICON;
    button.setAttribute("aria-label", LABEL);
    button.title = LABEL;

    // If the browser won't let the page write to the clipboard, select the
    // commands instead, and try the older copy command on the selection. If
    // that fails too, the selection is left for the reader to copy.
    const copyBySelecting = () => {
      const range = document.createRange();
      range.selectNodeContents(pre);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      return document.execCommand("copy");
    };

    let reset;
    button.addEventListener("click", async () => {
      let copied;
      try {
        await navigator.clipboard.writeText(pre.textContent.trimEnd());
        copied = true;
      } catch {
        copied = copyBySelecting();
      }
      if (copied) {
        button.innerHTML = TICK_ICON;
        button.classList.add("copy-code--done");
        button.setAttribute("aria-label", "Copied");
      } else {
        button.setAttribute("aria-label", "Selected: press Ctrl+C or Cmd+C to copy");
      }
      clearTimeout(reset);
      reset = setTimeout(() => {
        button.innerHTML = COPY_ICON;
        button.classList.remove("copy-code--done");
        button.setAttribute("aria-label", LABEL);
      }, 2000);
    });

    block.classList.add("copy-code__block");
    block.appendChild(button);
  });
})();
