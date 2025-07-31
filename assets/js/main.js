// Main JavaScript File

// Import all components
import { initMatrixEffect } from './components/matrix-effect.js';
import { initTypingEffect } from './components/typing-effect.js';
import { initSmoothScroll } from './components/smooth-scroll.js';
import { initIntersectionObserver } from './utils/intersection-observer.js';

// Initialize all components when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Initialize matrix rain effect
    initMatrixEffect();
    
    // Initialize typing effect
    initTypingEffect();
    
    // Initialize smooth scrolling
    initSmoothScroll();
    
    // Initialize intersection observer for animations
    initIntersectionObserver();
    
    // Initialize touch interactions
    initTouchInteractions();
});

// Touch interactions for mobile
function initTouchInteractions() {
    let touchStartY = 0;
    let touchEndY = 0;

    document.addEventListener('touchstart', (e) => {
        touchStartY = e.changedTouches[0].screenY;
    });

    document.addEventListener('touchend', (e) => {
        touchEndY = e.changedTouches[0].screenY;
        handleSwipe();
    });

    function handleSwipe() {
        if (touchEndY < touchStartY - 50) {
            // Swipe up - can be used for navigation
        }
        if (touchEndY > touchStartY + 50) {
            // Swipe down - can be used for navigation
        }
    }
}