gsap.registerPlugin(ScrollTrigger);

const prefersReducedMotion = window.matchMedia(
  "(prefers-reduced-motion: reduce)"
).matches;

if (!prefersReducedMotion) {
  const heroTimeline = gsap.timeline({
    defaults: { ease: "power3.out", duration: 0.9 },
  });

  heroTimeline
    .from(".nav", { y: -40, opacity: 0 })
    .from(".brand", { opacity: 0, y: -10 }, "-=0.5")
    .from(".nav-links a", { opacity: 0, y: -10, stagger: 0.08 }, "-=0.5")
    .from(".hero-left > *", { opacity: 0, y: 30, stagger: 0.1 }, "-=0.4")
    .from(".piano-card", { opacity: 0, y: 60, rotateX: 10, rotateY: -8 }, "-=0.7")
    .from(".showcase-ribbon span", { opacity: 0, y: 16, stagger: 0.04 }, "-=0.45")
    .from(".keyboard .key", { opacity: 0, y: 8, stagger: 0.015 }, "-=0.5");

  gsap.to(".brand", {
    scrollTrigger: {
      trigger: ".hero",
      start: "top top",
      end: "bottom top",
      scrub: 0.8,
    },
    y: -8,
    scale: 0.98,
  });

  gsap.to(".piano-card", {
    y: 10,
    rotateY: 2,
    rotateX: -1,
    duration: 4,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut",
  });

  gsap.to(".meter-fill", {
    width: "92%",
    duration: 3,
    yoyo: true,
    repeat: -1,
    ease: "sine.inOut",
  });

  gsap.to(".pulse-dot", {
    scale: 1.7,
    opacity: 0.18,
    duration: 1.3,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut",
  });

  gsap.to(".orb-1", {
    y: 40,
    x: -20,
    duration: 10,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut",
  });

  gsap.to(".orb-2", {
    y: -30,
    x: 30,
    duration: 12,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut",
  });

  gsap.to(".orb-3", {
    y: 25,
    x: 18,
    duration: 9,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut",
  });

  gsap.to(".orb", {
    scrollTrigger: {
      trigger: "body",
      start: "top top",
      end: "bottom top",
      scrub: 1.2,
    },
    yPercent: -10,
    xPercent: 6,
    ease: "none",
  });

  gsap.to(".marquee-track", {
    xPercent: -25,
    duration: 18,
    repeat: -1,
    ease: "none",
  });

  gsap.to(".piano-card", {
    scrollTrigger: {
      trigger: ".hero",
      start: "top 65%",
      end: "bottom top",
      scrub: 1,
    },
    y: -24,
    rotateX: 2,
  });

  gsap.utils.toArray(".feature-card").forEach((card, index) => {
    gsap.from(card, {
      opacity: 0,
      y: 44,
      rotateX: 8,
      duration: 0.75,
      ease: "power2.out",
      delay: index * 0.03,
      scrollTrigger: {
        trigger: card,
        start: "top 82%",
      },
    });
  });

  const insightsTimeline = gsap.timeline({
    scrollTrigger: {
      trigger: ".insights",
      start: "top 75%",
      end: "bottom 60%",
      scrub: 1,
    },
  });

  insightsTimeline
    .from(".insights-left", { opacity: 0, x: -50, duration: 1 })
    .from(".insight-panel", { opacity: 0, y: 36, stagger: 0.2 }, "-=0.5")
    .from(".mini-bars span", { scaleX: 0, transformOrigin: "left", stagger: 0.08 }, "-=0.45");

  gsap.utils.toArray(".roadmap-card").forEach((card, index) => {
    gsap.from(card, {
      opacity: 0,
      y: 60,
      scale: 0.96,
      rotateY: index % 2 === 0 ? -4 : 4,
      duration: 0.9,
      ease: "power3.out",
      scrollTrigger: {
        trigger: card,
        start: "top 84%",
      },
    });
  });

  ScrollTrigger.create({
    trigger: ".ecosystem",
    start: "top top+=70",
    end: "bottom bottom-=80",
    pin: ".ecosystem-title",
    pinSpacing: false,
  });

  gsap.utils.toArray(".experience-card").forEach((card, index) => {
    gsap.from(card, {
      opacity: 0,
      y: 30,
      duration: 0.6,
      ease: "power2.out",
      delay: index * 0.05,
      scrollTrigger: {
        trigger: card,
        start: "top 85%",
      },
    });
  });
}

const demoButton = document.getElementById("listen-demo");
const demoAudio = document.getElementById("demo-audio");

if (demoButton && demoAudio) {
  let playing = false;
  demoButton.addEventListener("click", () => {
    if (playing) {
      demoAudio.pause();
      demoAudio.currentTime = 0;
      demoButton.textContent = "Hear The Gyro";
      playing = false;
      return;
    }
    demoAudio.play();
    demoButton.textContent = "Stop Audio";
    playing = true;
  });

  demoAudio.addEventListener("ended", () => {
    demoButton.textContent = "Hear The Gyro";
    playing = false;
  });
}
