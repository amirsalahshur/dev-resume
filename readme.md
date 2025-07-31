# Amir Salahshur Portfolio

A modern, responsive portfolio website for a Full Stack Developer & DevOps Engineer with interactive animations and a terminal-inspired design.

## Features

- **Terminal-Inspired Design**: Unique header with terminal window styling
- **Matrix Rain Effect**: Dynamic canvas animation in the background
- **Typing Animation**: Rotating text display with typewriter effect
- **Responsive Design**: Fully optimized for desktop, tablet, and mobile devices
- **Interactive Elements**: Hover effects, smooth scrolling, and animated sections
- **Modular Architecture**: Clean separation of HTML, CSS, and JavaScript

## Project Structure

```
portfolio/
│
├── index.html                 # Main HTML file
│
├── assets/
│   ├── css/
│   │   ├── main.css          # Main CSS file that imports all others
│   │   ├── components/       # Component-specific styles
│   │   │   ├── header.css
│   │   │   ├── hero.css
│   │   │   ├── skills.css
│   │   │   ├── timeline.css
│   │   │   ├── projects.css
│   │   │   ├── contact.css
│   │   │   └── footer.css
│   │   └── utilities/        # Utility styles
│   │       ├── variables.css
│   │       ├── animations.css
│   │       └── responsive.css
│   │
│   ├── js/
│   │   ├── main.js           # Main JavaScript file
│   │   ├── components/       # Component scripts
│   │   │   ├── matrix-effect.js
│   │   │   ├── typing-effect.js
│   │   │   └── smooth-scroll.js
│   │   └── utils/            # Utility scripts
│   │       └── intersection-observer.js
│   │
│   └── images/               # Image assets (if any)
│
└── README.md                 # This file
```

## Technologies Used

- **HTML5**: Semantic markup
- **CSS3**: Custom properties, Grid, Flexbox, Animations
- **JavaScript**: ES6 modules, Canvas API, Intersection Observer
- **Design**: Responsive, Mobile-first approach

## Features in Detail

### Matrix Rain Effect
- Canvas-based animation
- Customizable characters and speed
- Performance-optimized for mobile devices

### Typing Effect
- Multiple rotating messages
- Smooth typing and deleting animations
- Customizable speed and messages

### Responsive Design
- Fluid typography using `clamp()`
- Responsive spacing system
- Optimized layouts for all screen sizes

### Accessibility
- Proper semantic HTML
- Reduced motion support
- High contrast mode support
- Keyboard navigation

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers

## Getting Started

1. Clone the repository
2. Open `index.html` in a web browser
3. No build process required!

## Customization

### Colors
Edit the CSS variables in `assets/css/utilities/variables.css`:
```css
:root {
    --bg-dark: #0a0e27;
    --accent-green: #10b981;
    /* ... */
}
```

### Content
- Update personal information in `index.html`
- Modify typing messages in `assets/js/components/typing-effect.js`
- Add/remove skills, projects, and experiences as needed

### Styling
- Component styles are separated for easy modification
- Responsive breakpoints can be adjusted in `responsive.css`

## Performance Considerations

- Matrix effect reduces opacity on mobile for better performance
- Lazy loading for images (when added)
- Optimized animations with `transform` and `opacity`
- Minimal JavaScript for better load times

## License

MIT License - feel free to use this template for your own portfolio!

## Author

Amir Salahshur - Full Stack Developer & DevOps Engineer