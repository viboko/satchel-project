(() => {
  const countWords = (text) => text.split(/\s+/).filter(Boolean).length;

  document.querySelectorAll("[data-word-limit]").forEach((answer) => {
    const counter = answer.querySelector(".word-count");
    if (!counter) return;

    const limit = Number(answer.dataset.wordLimit);

    const update = () => {
      // Join blocks with spaces, since textContent runs paragraphs and list
      // items together, and leave out the counter itself.
      const text = Array.from(answer.children)
        .filter((child) => child !== counter)
        .map((child) => child.textContent)
        .join(" ");
      const words = countWords(text);

      counter.textContent = `(${words} of ${limit} words)`;
      counter.classList.toggle("word-count--over", words > limit);
    };

    update();
  });
})();
