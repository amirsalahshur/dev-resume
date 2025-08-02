// Main JavaScript file - imports and initializes all modules
import { MatrixEffect } from './modules/matrix-effect.js';
import { TypingEffect } from './modules/typing-effect.js';
import { initSmoothScroll } from './modules/smooth-scroll.js';
import { initAnimationObserver } from './modules/intersection-observer.js';

// DOM Content Loaded initialization
document.addEventListener('DOMContentLoaded', () => {
    // Initialize Matrix Effect
    const matrixEffect = new MatrixEffect('matrix');

    // Initialize Typing Effect
    const typingTexts = [
        'Building scalable infrastructure and elegant code solutions...',
        'Automating everything that can be automated...',
        'Turning coffee into cloud infrastructure...',
        'Deploying happiness, one container at a time...'
    ];
    
    new TypingEffect('.typing-effect', typingTexts);

    // Initialize Smooth Scroll
    initSmoothScroll();

    // Initialize Animation Observer
    initAnimationObserver();

    // Touch interactions for mobile
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
});