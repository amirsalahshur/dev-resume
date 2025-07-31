// Matrix Rain Effect

export function initMatrixEffect() {
    const canvas = document.getElementById('matrix');
    const ctx = canvas.getContext('2d');

    // Set canvas size
    function setCanvasSize() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }
    setCanvasSize();

    const matrix = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789@#$%^&*()*&^%+-/~{[|`]}";
    const matrixArray = matrix.split("");

    const fontSize = 10;
    let columns = canvas.width / fontSize;

    let drops = [];
    function initDrops() {
        drops = [];
        columns = canvas.width / fontSize;
        for(let x = 0; x < columns; x++) {
            drops[x] = 1;
        }
    }
    initDrops();

    function draw() {
        ctx.fillStyle = 'rgba(10, 14, 39, 0.04)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        ctx.fillStyle = '#10b981';
        ctx.font = fontSize + 'px monospace';

        for(let i = 0; i < drops.length; i++) {
            const text = matrixArray[Math.floor(Math.random() * matrixArray.length)];
            ctx.fillText(text, i * fontSize, drops[i] * fontSize);

            if(drops[i] * fontSize > canvas.height && Math.random() > 0.975) {
                drops[i] = 0;
            }
            drops[i]++;
        }
    }

    setInterval(draw, 35);

    // Resize canvas on window resize
    window.addEventListener('resize', () => {
        setCanvasSize();
        initDrops();
    });
}