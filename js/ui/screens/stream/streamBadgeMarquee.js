// Android StreamBadgeChips keeps badges on one clipped row and loops it only on the focused card
// (basicMarquee: 45dp/s, 36dp spacing, default 1.2 s pause between loops). TV CSS is 2px per dp.
const MARQUEE_VELOCITY_PX_PER_S = 90;
const MARQUEE_SPACING_PX = 72;
const MARQUEE_PAUSE_MS = 1200;
const activeRows = new WeakMap();

function badgeRowsOf(card) {
  return Array.from(card?.querySelectorAll?.(".stream-route-card-badges") || []);
}

export function stopStreamBadgeMarquee(card) {
  badgeRowsOf(card).forEach((row) => {
    const animations = activeRows.get(row);
    if (!animations) return;
    animations.forEach((animation) => animation.cancel());
    activeRows.delete(row);
    row.querySelectorAll("[data-badge-marquee-clone]").forEach((clone) => clone.remove());
  });
}

export function startStreamBadgeMarquee(card) {
  badgeRowsOf(card).forEach((row) => {
    if (activeRows.has(row) || row.scrollWidth <= row.clientWidth + 1) return;
    const badges = Array.from(row.children);
    if (!badges.length || typeof badges[0].animate !== "function") return;
    const first = badges[0].getBoundingClientRect();
    const last = badges[badges.length - 1].getBoundingClientRect();
    const distance = last.right - first.left + MARQUEE_SPACING_PX;
    const flexGap = parseFloat(getComputedStyle(row).columnGap) || 0;
    const clones = badges.map((badge, index) => {
      const clone = badge.cloneNode(true);
      clone.setAttribute("data-badge-marquee-clone", "");
      clone.setAttribute("aria-hidden", "true");
      if (index === 0) clone.style.marginLeft = `${MARQUEE_SPACING_PX - flexGap}px`;
      row.appendChild(clone);
      return clone;
    });
    const scrollMs = (distance / MARQUEE_VELOCITY_PX_PER_S) * 1000;
    const duration = MARQUEE_PAUSE_MS + scrollMs;
    const pauseOffset = MARQUEE_PAUSE_MS / duration;
    const keyframes = [
      { transform: "translateX(0)", offset: 0 },
      { transform: "translateX(0)", offset: pauseOffset },
      { transform: `translateX(${-distance}px)`, offset: 1 }
    ];
    activeRows.set(
      row,
      [...badges, ...clones].map((node) =>
        node.animate(keyframes, { duration, iterations: Infinity, easing: "linear" })
      )
    );
  });
}
