// Matrix Rain Effect
export class MatrixEffect {
    constructor(canvasId) {
        this.canvas = document.getElementById(canvasId);
        this.ctx = this.canvas.getContext('2d');
        this.matrix = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789@#$%^&*()*&^%+-/~{[|`]}";
        this.matrixArray = this.matrix.split("");
        this.fontSize = 10;
        this.drops = [];
        
        this.init();
        this.setupEventListeners();
        this.start();
    }

    init() {
        this.setCanvasSize();
        this.initDrops();
    }

    setCanvasSize() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }

    initDrops() {
        this.drops = [];
        this.columns = this.canvas.width / this.fontSize;
        for(let x = 0; x < this.columns; x++) {
            this.drops[x] = 1;
        }
    }

    draw() {
        this.ctx.fillStyle = 'rgba(10, 14, 39, 0.04)';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

        this.ctx.fillStyle = '#10b981';
        this.ctx.font = this.fontSize + 'px monospace';

        for(let i = 0; i < this.drops.length; i++) {
            const text = this.matrixArray[Math.floor(Math.random() * this.matrixArray.length)];
            this.ctx.fillText(text, i * this.fontSize, this.drops[i] * this.fontSize);

            if(this.drops[i] * this.fontSize > this.canvas.height && Math.random() > 0.975) {
                this.drops[i] = 0;
            }
            this.drops[i]++;
        }
    }

    start() {
        this.interval = setInterval(() => this.draw(), 35);
    }

    stop() {
        if (this.interval) {
            clearInterval(this.interval);
        }
    }

    setupEventListeners() {
        window.addEventListener('resize', () => {
            this.setCanvasSize();
            this.initDrops();
        });
    }
}