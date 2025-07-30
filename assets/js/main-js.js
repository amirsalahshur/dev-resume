// assets/js/main.js

// Main Application Controller
class PortfolioApp {
    constructor() {
        this.init();
        this.setupEventListeners();
        this.initializeFeatures();
    }
    
    init() {
        // Check for required features
        this.checkBrowserSupport();
        
        // Set theme
        this.initTheme();
        
        // Performance optimizations
        this.optimizePerformance();
    }
    
    checkBrowserSupport() {
        // Check for IntersectionObserver
        if (!('IntersectionObserver' in window)) {
            console.warn('IntersectionObserver not supported');
            // Load polyfill or fallback
        }
        
        // Check for CSS Grid support
        const supportsGrid = CSS.supports('display', 'grid');
        if (!supportsGrid) {
            document.body.classList.add('no-grid');
        }
    }
    
    initTheme() {
        // Check for saved theme preference
        const savedTheme = localStorage.getItem('theme');
        if (savedTheme) {
            document.body.setAttribute('data-theme', savedTheme);
        }
        
        // Check system preference
        if (!savedTheme && window.matchMedia) {
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            document.body.setAttribute('data-theme', prefersDark ? 'dark' : 'light');
        }
    }
    
    setupEventListeners() {
        // Navigation menu toggle for mobile
        const menuToggle = document.querySelector('.menu-toggle');
        const mobileMenu = document.querySelector('.mobile-menu');
        
        if (menuToggle && mobileMenu) {
            menuToggle.addEventListener('click', () => {
                mobileMenu.classList.toggle('active');
                menuToggle.classList.toggle('active');
            });
            
            // Close menu when clicking outside
            document.addEventListener('click', (e) => {
                if (!menuToggle.contains(e.target) && !mobileMenu.contains(e.target)) {
                    mobileMenu.classList.remove('active');
                    menuToggle.classList.remove('active');
                }
            });
        }
        
        // Form handling
        this.setupFormHandlers();
        
        // Keyboard navigation
        this.setupKeyboardNavigation();
    }
    
    setupFormHandlers() {
        const contactForm = document.querySelector('#contact-form');
        if (contactForm) {
            contactForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                
                // Get form data
                const formData = new FormData(contactForm);
                const data = Object.fromEntries(formData);
                
                // Validate form
                if (this.validateForm(data)) {
                    // Submit form (implement your submission logic)
                    try {
                        await this.submitForm(data);
                        this.showNotification('Message sent successfully!', 'success');
                        contactForm.reset();
                    } catch (error) {
                        this.showNotification('Failed to send message. Please try again.', 'error');
                    }
                }
            });
        }
    }
    
    validateForm(data) {
        // Basic validation
        if (!data.name || !data.email || !data.message) {
            this.showNotification('Please fill in all required fields.', 'error');
            return false;
        }
        
        // Email validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(data.email)) {
            this.showNotification('Please enter a valid email address.', 'error');
            return false;
        }
        
        return true;
    }
    
    async submitForm(data) {
        // Implement your form submission logic here
        // This is a placeholder that simulates an API call
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                // Simulate success/failure
                Math.random() > 0.5 ? resolve() : reject();
            }, 1000);
        });
    }
    
    setupKeyboardNavigation() {
        document.addEventListener('keydown', (e) => {
            // Escape key closes modals/menus
            if (e.key === 'Escape') {
                this.closeAllModals();
            }
            
            // Tab navigation enhancements
            if (e.key === 'Tab') {
                document.body.classList.add('keyboard-nav');
            }
        });
        
        // Remove keyboard navigation indicator on mouse use
        document.addEventListener('mousedown', () => {
            document.body.classList.remove('keyboard-nav');
        });
    }
    
    initializeFeatures() {
        // Lazy loading for images
        this.setupLazyLoading();
        
        // Copy code blocks functionality
        this.setupCodeCopy();
        
        // Analytics (if needed)
        this.initAnalytics();
        
        // Service Worker for offline support
        this.registerServiceWorker();
    }
    
    setupLazyLoading() {
        const images = document.querySelectorAll('img[data-src]');
        
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        img.src = img.dataset.src;
                        img.removeAttribute('data-src');
                        imageObserver.unobserve(img);
                    }
                });
            });
            
            images.forEach(img => imageObserver.observe(img));
        } else {
            // Fallback for browsers without IntersectionObserver
            images.forEach(img => {
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
            });
        }
    }
    
    setupCodeCopy() {
        const codeBlocks = document.querySelectorAll('.code-block');
        
        codeBlocks.forEach(block => {
            const copyButton = document.createElement('button');
            copyButton.className = 'copy-code-btn';
            copyButton.innerHTML = '📋 Copy';
            copyButton.setAttribute('aria-label', 'Copy code');
            
            copyButton.addEventListener('click', async () => {
                const code = block.textContent;
                
                try {
                    await navigator.clipboard.writeText(code);
                    copyButton.innerHTML = '✅ Copied!';
                    setTimeout(() => {
                        copyButton.innerHTML = '📋 Copy';
                    }, 2000);
                } catch (err) {
                    console.error('Failed to copy:', err);
                    this.showNotification('Failed to copy code', 'error');
                }
            });
            
            block.appendChild(copyButton);
        });
    }
    
    initAnalytics() {
        // Initialize analytics if needed
        // Example: Google Analytics, Plausible, etc.
        if (typeof gtag !== 'undefined') {
            gtag('config', 'GA_MEASUREMENT_ID');
        }
    }
    
    registerServiceWorker() {
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('/sw.js')
                    .then(registration => {
                        console.log('SW registered:', registration);
                    })
                    .catch(error => {
                        console.log('SW registration failed:', error);
                    });
            });
        }
    }
    
    optimizePerformance() {
        // Debounce scroll events
        let scrollTimeout;
        window.addEventListener('scroll', () => {
            if (scrollTimeout) {
                window.cancelAnimationFrame(scrollTimeout);
            }
            
            scrollTimeout = window.requestAnimationFrame(() => {
                // Handle scroll-based updates
                this.updateScrollProgress();
            });
        });
        
        // Throttle resize events
        let resizeTimeout;
        window.addEventListener('resize', () => {
            clearTimeout(resizeTimeout);
            resizeTimeout = setTimeout(() => {
                // Handle resize updates
                this.handleResize();
            }, 250);
        });
    }
    
    updateScrollProgress() {
        const scrollProgress = document.querySelector('.scroll-progress');
        if (scrollProgress) {
            const scrollTop = window.pageYOffset;
            const docHeight = document.documentElement.scrollHeight - window.innerHeight;
            const scrollPercent = (scrollTop / docHeight) * 100;
            scrollProgress.style.width = scrollPercent + '%';
        }
    }
    
    handleResize() {
        // Update any size-dependent features
        console.log('Window resized');
    }
    
    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        // Add to DOM
        document.body.appendChild(notification);
        
        // Animate in
        setTimeout(() => {
            notification.classList.add('show');
        }, 10);
        
        // Remove after delay
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => {
                notification.remove();
            }, 300);
        }, 3000);
    }
    
    closeAllModals() {
        // Close any open modals or menus
        document.querySelectorAll('.modal.active').forEach(modal => {
            modal.classList.remove('active');
        });
        
        document.querySelectorAll('.menu.active').forEach(menu => {
            menu.classList.remove('active');
        });
    }
}

// Utility Functions
const utils = {
    // Debounce function
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },
    
    // Throttle function
    throttle(func, limit) {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    },
    
    // Format date
    formatDate(date) {
        const options = { year: 'numeric', month: 'long', day: 'numeric' };
        return new Date(date).toLocaleDateString(undefined, options);
    },
    
    // Check if element is in viewport
    isInViewport(element) {
        const rect = element.getBoundingClientRect();
        return (
            rect.top >= 0 &&
            rect.left >= 0 &&
            rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
            rect.right <= (window.innerWidth || document.documentElement.clientWidth)
        );
    }
};

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.portfolioApp = new PortfolioApp();
    });
} else {
    window.portfolioApp = new PortfolioApp();
}

// Export utilities
window.utils = utils;