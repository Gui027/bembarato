const reveals = document.querySelectorAll('.reveal');
document.querySelectorAll('.hero .reveal').forEach((item) => item.classList.add('visible'));

if ('IntersectionObserver' in window) {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -30px' });
  reveals.forEach((item) => observer.observe(item));
} else {
  reveals.forEach((item) => item.classList.add('visible'));
}

document.querySelectorAll('.faq-list details').forEach((item) => {
  item.addEventListener('toggle', () => {
    if (!item.open) return;
    document.querySelectorAll('.faq-list details').forEach((other) => {
      if (other !== item) other.open = false;
    });
  });
});

const modal = document.querySelector('.image-modal');
const modalImage = modal.querySelector('img');

document.querySelectorAll('.image-button').forEach((button) => {
  button.addEventListener('click', () => {
    modalImage.src = button.dataset.image;
    modalImage.alt = button.querySelector('img').alt;
    modal.showModal();
  });
});

const testimonialRail = document.querySelector('[data-testimonial-rail]');
document.querySelectorAll('[data-proof-direction]').forEach((button) => {
  button.addEventListener('click', () => {
    const direction = Number(button.dataset.proofDirection);
    testimonialRail.scrollBy({
      left: testimonialRail.clientWidth * 0.82 * direction,
      behavior: 'smooth',
    });
  });
});

const videoTrack = document.querySelector('.video-track');
const videoGroup = videoTrack?.querySelector('.video-group');

if (videoTrack && videoGroup) {
  const videoClone = videoGroup.cloneNode(true);
  videoClone.setAttribute('aria-hidden', 'true');
  videoClone.setAttribute('inert', '');
  videoClone.querySelectorAll('iframe').forEach((frame) => {
    frame.setAttribute('tabindex', '-1');
    frame.removeAttribute('title');
  });
  videoTrack.append(videoClone);
}

modal.querySelector('button').addEventListener('click', () => modal.close());
modal.addEventListener('click', (event) => {
  if (event.target === modal) modal.close();
});
