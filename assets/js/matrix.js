// assets/js/matrix.js

class MatrixRain {
    constructor(canvasId) {
        this.canvas = document.getElementById(canvasId);
        if (!this.canvas) return;
        
        this.ctx = this.canvas.getContext('2d');
        this.characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789@#$%^&*()*&^%+-/~{[|`]}";
        this.charactersArray = this.characters.split("");
        
        this.fontSize = 10;
        this.columns = 0;
        this.drops = [];
        
        // Initialize
        this.setCanvasSize();
        this.initDrops();
        
        // Event listeners
        window.addEventListener('resize', () => {
            this.setCanvasSize();
            this.initDrops();
        });
        
        // Start animation
        this.animate();
        
        // Performance optimization for mobile
        if (window.innerWidth < 768) {
            this.canvas.style.opacity = '0.02';
        }
    }
    
    setCanvasSize() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }
    
    initDrops() {
        this.columns = this.canvas.width / this.fontSize;
        this.drops = [];
        
        for (let x = 0; x < this.columns; x++) {
            this.drops[x] = 1;
        }
    }
    
    draw() {
        // Semi-transparent background for trail effect
        this.ctx.fillStyle = 'rgba(10, 14, 39, 0.04)';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Green text
        this.ctx.fillStyle = '#10b981';
        this.ctx.font = this.fontSize + 'px monospace';
        
        // Draw characters
        for (let i = 0; i < this.drops.length; i++) {
            const text = this.charactersArray[Math.floor(Math.random() * this.charactersArray.length)];
            const x = i * this.fontSize;
            const y = this.drops[i] * this.fontSize;
            
            this.ctx.fillText(text, x, y);
            
            // Reset drop to top with random delay
            if (y > this.canvas.height && Math.random() > 0.975) {
                this.drops[i] = 0;
            }
            
            this.drops[i]++;
        }
    }
    
    animate() {
        this.draw();
        
        // Use requestAnimationFrame for better performance
        // Fallback to setTimeout for older browsers
        if (window.requestAnimationFrame) {
            setTimeout(() => {
                window.requestAnimationFrame(() => this.animate());
            }, 35);
        } else {
            setTimeout(() => this.animate(), 35);
        }
    }
    
    // Public methods for control
    pause() {
        this.isPaused = true;
    }
    
    resume() {
        this.isPaused = false;
        this.animate();
    }
    
    setOpacity(opacity) {
        this.canvas.style.opacity = opacity;
    }
    
    destroy() {
        // Clean up event listeners
        window.removeEventListener('resize', this.setCanvasSize);
    }
}

// Initialize Matrix Rain when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const matrix = new MatrixRain('matrix');
    
    // Expose to global scope if needed
    window.matrixRain = matrix;
    
    // Performance: Reduce effect on scroll for mobile
    if ('ontouchstart' in window) {
        let scrolling = false;
        let scrollTimeout;
        
        window.addEventListener('scroll', () => {
            if (!scrolling) {
                matrix.setOpacity('0.01');
                scrolling = true;
            }
            
            clearTimeout(scrollTimeout);
            scrollTimeout = setTimeout(() => {
                matrix.setOpacity('0.03');
                scrolling = false;
            }, 150);
        });
    }
    
    // Pause on visibility change to save resources
    document.addEventListener('visibilitychange', () => {
        if (document.hidden) {
            matrix.pause();
        } else {
            matrix.resume();
        }
    });
});
