---
title: Curriculum Vitae
created: 2024-07-02
updated: 2026-08-19
hidden: true
---

<p id="cv">Loading CV...</p>

<script>
  document.addEventListener("DOMContentLoaded", async () => {
    try {
      const res = await fetch("https://api.github.com/repos/stepbrobd/cv/releases/latest");
      if (!res.ok) throw new Error("fetch failed");
      const rel = await res.json();
      const date = new Date(rel.published_at).toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      });
      const tgt = document.getElementById("cv");
      tgt.innerHTML =
        `Last updated on ${date}: <a href="https://drive.google.com/viewerng/viewer?embedded=true\u0026url=${
          encodeURIComponent(rel.assets[0].browser_download_url)
        }" target="_blank">preview</a> | <a href="${
          rel.assets[0].browser_download_url
        }" target="_blank">download</a>`;
    } catch (err) {
      document.getElementById("cv").innerHTML = `Error loading CV: ${err.message}`;
    }
  });
</script>

In case you are curious, my [CV](https://github.com/stepbrobd/cv) has an
automated release pipeline. Once the content gets an update, GitHub Actions will
automatically tag and release a new version. This page fetches the latest
release and displays a preview link (using Google Drive's PDF viewer) and a
download link. I opted not to redirect to the asset link since GitHub uses
`Content-Disposition` header to force a file download.

Implementation:

```html
<p id="cv">Loading CV...</p>

<script>
document.addEventListener("DOMContentLoaded", async () => {
  try {
    const res = await fetch(
      "https://api.github.com/repos/stepbrobd/cv/releases/latest",
    );
    if (!res.ok) throw new Error("fetch failed");
    const rel = await res.json();
    const date = new Date(rel.published_at).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
    const tgt = document.getElementById("cv");
    tgt.innerHTML =
      `Last updated on ${date}: <a href="https://drive.google.com/viewerng/viewer?embedded=true&url=${
        encodeURIComponent(rel.assets[0].browser_download_url)
      }" target="_blank">preview</a> | <a href="${
        rel.assets[0].browser_download_url
      }" target="_blank">download</a>`;
  } catch (err) {
    document.getElementById("cv").innerHTML =
      `Error loading CV: ${err.message}`;
  }
});
</script>
```
