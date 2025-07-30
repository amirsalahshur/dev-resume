// assets/js/typing.js

class TypingEffect {
    constructor(element, options = {}) {
        this.element = element;
        this.texts = options.texts || ['Default text...'];
        this.typeSpeed = options.typeSpeed || 100;
        this.deleteSpeed = options.deleteSpeed || 50;
        this.pauseTime = options.pauseTime || 2000;
        this.loop = options.loop !== undefined ? options.loop : true;
        
        this.textIndex = 0;
        this.charIndex = 0;
        this.isDeleting = false;
        this.isPaused = false;
        
        this.type();
    }
    
    type() {
        if (this.isPaused) return;
        
        const currentText = this.texts[this.textIndex];
        
        if (this.isDeleting) {
            // Remove characters
            this.element.textContent = currentText.substring(0, this.charIndex - 1);
            this.charIndex--;
        } else {
            // Add characters
            this.element.textContent = currentText.substring(0, this.charIndex + 1);
            this.charIndex++;
        }
        
        let timeout = this.isDeleting ? this.deleteSpeed : this.typeSpeed;
        
        // Handle completion of typing
        if (!this.isDeleting && this.charIndex === currentText.length) {
            timeout = this.pauseTime;
            this.isDeleting = true;
        } else if (this.isDeleting && this.charIndex === 0) {
            this.isDeleting = false;
            this.textIndex = (this.textIndex + 1) % this.texts.length;
            timeout = 500; // Small pause before typing next text
        }
        
        setTimeout(() => this.type(), timeout);
    }
    
    pause() {
        this.isPaused = true;
    }
    
    resume() {
        this.isPaused = false;
        this.type();
    }
    
    updateTexts(newTexts) {
        this.texts = newTexts;
    }
    
    reset() {
        this.textIndex = 0;
        this.charIndex = 0;
        this.isDeleting = false;
    }
}

// Initialize typing effect when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const typingElement = document.querySelector('.typing-effect');
    
    if (typingElement) {
        const texts = [
            'Building scalable infrastructure and elegant code solutions...',
            'Automating everything that can be automated...',
            'Turning coffee into cloud infrastructure...',
            'Deploying happiness, one container at a time...',
            'Creating CI/CD pipelines that never sleep...',
            'Orchestrating containers like a symphony...',
            'Writing code that scales to infinity and beyond...',
            'Making the cloud work for you, not against you...'
        ];
        
        const typing = new TypingEffect(typingElement, {
            texts: texts,
            typeSpeed: 80,
            deleteSpeed: 40,
            pauseTime: 2500,
            loop: true
        });
        
        // Expose to global scope if needed
        window.typingEffect = typing;
        
        // Pause typing when page is not visible
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                typing.pause();
            } else {
                typing.resume();
            }
        });
    }
    
    // Add blinking cursor effect
    const style = document.createElement('style');
    style.textContent = `
        .typing-effect::after {
            content: '_';
            animation: blink 1s infinite;
            color: var(--accent-green);
            font-weight: bold;
        }
    `;
    document.head.appendChild(style);
});
