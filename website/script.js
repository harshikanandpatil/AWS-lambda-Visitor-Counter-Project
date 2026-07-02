// Replace this with your actual API Gateway endpoint after deployment
const API_URL = "https://YOUR_API_GATEWAY_URL/prod/count";

/**
 * Animates the counter from `start` to `end` over `duration` ms.
 */
function animateCount(el, start, end, duration = 900) {
  const range = end - start;
  if (range === 0) return;
  const startTime = performance.now();

  function step(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    // Ease-out cubic
    const eased = 1 - Math.pow(1 - progress, 3);
    const current = Math.round(start + range * eased);
    el.textContent = current.toLocaleString();
    if (progress < 1) requestAnimationFrame(step);
  }

  requestAnimationFrame(step);
}

let lastCount = 0;

async function fetchVisitorCount() {
  const countEl = document.getElementById("visitor-count");
  const subEl   = document.getElementById("counter-sub");
  const btn     = document.getElementById("refresh-btn");

  countEl.className = "counter loading";
  countEl.textContent = "—";
  subEl.textContent = "Fetching count\u2026";
  btn.disabled = true;

  try {
    const response = await fetch(API_URL, { method: "GET" });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    const newCount = data.visitorCount;

    countEl.className = "counter";
    animateCount(countEl, lastCount, newCount);

    // Pop animation on update
    countEl.classList.remove("pop");
    void countEl.offsetWidth; // reflow
    countEl.classList.add("pop");

    const now = new Date();
    subEl.textContent = `Last updated at ${now.toLocaleTimeString()}`;
    lastCount = newCount;

  } catch (err) {
    console.error("Failed to fetch visitor count:", err);
    countEl.textContent = "Error";
    countEl.className = "counter error";
    subEl.textContent = "Could not reach the API. Please try again.";
  } finally {
    btn.disabled = false;
  }
}

// Fetch count on page load
document.addEventListener("DOMContentLoaded", fetchVisitorCount);
