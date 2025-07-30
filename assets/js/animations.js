// assets/js/animations.js

// Intersection Observer for scroll animations
class ScrollAnimations {
    constructor() {
        this.observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -100px 0px'
        };
        
        this.init();
    }
    
    init() {
        // Create observer
        this.observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animated');
                    
                    // Add stagger effect for children
                    const children = entry.target.querySelectorAll('.stagger-item');
                    children.forEach((child, index) => {
                        setTimeout(() => {
                            child.classList.add('animated');
                        }, index * 100);
                    });
                    
                    // Unobserve after animation (optional)
                    // this.observer.unobserve(entry.target);
                }
            });
        }, this.observerOptions);
        
        // Observe elements
        this.observeElements();
    }
    
    observeElements() {
        // Observe all sections
        const sections = document.querySelectorAll('section');
        sections.forEach(section => {
            section.style.opacity = '0';
            section.style.transform = 'translateY(30px)';
            section.style.transition = 'all 0.6s ease';
            this.observer.observe(section);
        });
        
        // Observe timeline items
        const timelineItems = document.querySelectorAll('.timeline-item');
        timelineItems.forEach((item, index) => {
            item.style.opacity = '0';
            item.style.transform = 'translateY(30px)';
            item.style.transition = `all 0.6s ease ${index * 0.1}s`;
            this.observer.observe(item);
        });
        
        // Observe skill categories
        const skillCategories = document.querySelectorAll('.skill-category');
        skillCategories.forEach((category, index) => {
            category.style.opacity = '0';
            category.style.transform = 'translateY(20px)';
            category.style.transition = `all 0.5s ease ${index * 0.1}s`;
            this.observer.observe(category);
        });
        
        // Observe project cards
        const projectCards = document.querySelectorAll('.project-card');
        projectCards.forEach((card, index) => {
            card.style.opacity = '0';
            card.style.transform = 'translateY(20px) scale(0.95)';
            card.style.transition = `all 0.5s ease ${index * 0.1}s`;
            this.observer.observe(card);
        });
    }
    
    destroy() {
        this.observer.disconnect();
    }
}

// Smooth Scroll Implementation
class SmoothScroll {
    constructor() {
        this.init();
    }
    
    init() {
        // Handle anchor links
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', (e) => {
                e.preventDefault();
                
                const targetId = anchor.getAttribute('href');
                if (targetId === '#') return;
                
                const target = document.querySelector(targetId);
                if (target) {
                    this.scrollToElement(target);
                }
            });
        });
        
        // Add scroll-to-top button functionality if exists
        const scrollTopBtn = document.querySelector('.scroll-to-top');
        if (scrollTopBtn) {
            scrollTopBtn.addEventListener('click', () => {
                this.scrollToTop();
            });
            
            // Show/hide scroll-to-top button
            window.addEventListener('scroll', () => {
                if (window.pageYOffset > 300) {
                    scrollTopBtn.classList.add('visible');
                } else {
                    scrollTopBtn.classList.remove('visible');
                }
            });
        }
    }
    
    scrollToElement(element) {
        const offset = 80; // Offset for fixed header
        const elementPosition = element.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - offset;
        
        window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
        });
    }
    
    scrollToTop() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    }
}

// Parallax Effect
class ParallaxEffect {
    constructor() {
        this.elements = document.querySelectorAll('.parallax');
        this.init();
    }
    
    init() {
        if (this.elements.length === 0) return;
        
        // Check if device supports parallax (not mobile)
        if (window.innerWidth > 768 && !('ontouchstart' in window)) {
            window.addEventListener('scroll', () => this.handleScroll());
            window.addEventListener('resize', () => this.handleScroll());
        }
    }
    
    handleScroll() {
        const scrolled = window.pageYOffset;
        
        this.elements.forEach(element => {
            const speed = element.dataset.speed || 0.5;
            const yPos = -(scrolled * speed);
            element.style.transform = `translateY(${yPos}px)`;
        });
    }
}

// Touch/Swipe Handler
class TouchHandler {
    constructor() {
        this.touchStartY = 0;
        this.touchEndY = 0;
        this.init();
    }
    
    init() {
        document.addEventListener('touchstart', (e) => {
            this.touchStartY = e.changedTouches[0].screenY;
        });
        
        document.addEventListener('touchend', (e) => {
            this.touchEndY = e.changedTouches[0].screenY;
            this.handleSwipe();
        });
    }
    
    handleSwipe() {
        const swipeThreshold = 50;
        const diff = this.touchStartY - this.touchEndY;
        
        if (Math.abs(diff) > swipeThreshold) {
            if (diff > 0) {
                // Swipe up
                this.onSwipeUp();
            } else {
                // Swipe down
                this.onSwipeDown();
            }
        }
    }
    
    onSwipeUp() {
        // Custom swipe up behavior
        console.log('Swiped up');
    }
    
    onSwipeDown() {
        // Custom swipe down behavior
        console.log('Swiped down');
    }
}

// Hover Effects Enhancement
class HoverEffects {
    constructor() {
        this.init();
    }
    
    init() {
        // Add tilt effect to cards
        const cards = document.querySelectorAll('.project-card, .skill-category');
        
        cards.forEach(card => {
            card.addEventListener('mousemove', (e) => {
                const rect = card.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;
                
                const centerX = rect.width / 2;
                const centerY = rect.height / 2;
                
                const rotateX = (y - centerY) / 10;
                const rotateY = (centerX - x) / 10;
                
                card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateZ(10px)`;
            });
            
            card.addEventListener('mouseleave', () => {
                card.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) translateZ(0)';
            });
        });
    }
}

// Loading Animation
class LoadingAnimation {
    constructor() {
        this.init();
    }
    
    init() {
        window.addEventListener('load', () => {
            document.body.classList.add('loaded');
            
            // Remove loading screen if exists
            const loader = document.querySelector('.loader');
            if (loader) {
                setTimeout(() => {
                    loader.style.opacity = '0';
                    setTimeout(() => {
                        loader.style.display = 'none';
                    }, 300);
                }, 500);
            }
        });
    }
}

// Initialize all animations when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Initialize animations
    const scrollAnimations = new ScrollAnimations();
    const smoothScroll = new SmoothScroll();
    const parallaxEffect = new ParallaxEffect();
    const touchHandler = new TouchHandler();
    const hoverEffects = new HoverEffects();
    const loadingAnimation = new LoadingAnimation();
    
    // Expose to global scope if needed
    window.animations = {
        scrollAnimations,
        smoothScroll,
        parallaxEffect,
        touchHandler,
        hoverEffects,
        loadingAnimation
    };
});
