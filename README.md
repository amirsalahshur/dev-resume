# Amir Salahshur - Portfolio Website

A modern, responsive portfolio website showcasing the work and skills of Amir Salahshur, a Full Stack Developer & DevOps Engineer. Built with modern web technologies and best practices.

## 🚀 Features

- **Modern Architecture**: Modular CSS and ES6 JavaScript modules
- **Responsive Design**: Optimized for all devices and screen sizes
- **Interactive Elements**: Matrix background effect and typing animations
- **Performance Optimized**: Built with Vite for fast development and production builds
- **Accessibility**: WCAG compliant with proper semantic HTML and ARIA labels
- **SEO Optimized**: Meta tags, structured data, and semantic markup
- **Progressive Enhancement**: Works with JavaScript disabled

## 🛠️ Tech Stack

### Frontend
- **HTML5**: Semantic markup with accessibility in mind
- **CSS3**: Modern CSS with custom properties, Grid, and Flexbox
- **JavaScript (ES6+)**: Modular architecture with ES6 modules
- **Canvas API**: For interactive matrix background effect

### Build Tools
- **Vite**: Fast build tool and development server
- **ESLint**: Code linting and quality assurance
- **Prettier**: Code formatting
- **Terser**: JavaScript minification

### Development
- **Node.js**: Runtime environment
- **npm**: Package management
- **Git**: Version control

## 📁 Project Structure

```
portfolio/
├── src/
│   ├── index.html                 # Main HTML file
│   ├── styles/
│   │   ├── base/
│   │   │   ├── _reset.css        # CSS reset and base styles
│   │   │   ├── _typography.css   # Typography styles
│   │   │   └── _variables.css    # CSS custom properties
│   │   ├── components/
│   │   │   ├── _header.css       # Header component styles
│   │   │   ├── _hero.css         # Hero section styles
│   │   │   ├── _skills.css       # Skills section styles
│   │   │   ├── _timeline.css     # Timeline component styles
│   │   │   ├── _projects.css     # Projects section styles
│   │   │   ├── _contact.css      # Contact section styles
│   │   │   └── _footer.css       # Footer component styles
│   │   ├── layout/
│   │   │   └── _grid.css         # Layout and grid systems
│   │   ├── utils/
│   │   │   ├── _animations.css   # Animations and transitions
│   │   │   └── _responsive.css   # Responsive design utilities
│   │   └── main.css              # Main CSS file (imports all others)
│   ├── scripts/
│   │   ├── modules/
│   │   │   ├── matrix-effect.js       # Matrix background effect
│   │   │   ├── typing-effect.js       # Typing animation effect
│   │   │   ├── smooth-scroll.js       # Smooth scrolling functionality
│   │   │   └── intersection-observer.js # Scroll animations
│   │   └── main.js               # Main JavaScript file
│   └── assets/
│       └── images/               # Image assets
├── dist/                         # Production build output
├── .gitignore                    # Git ignore rules
├── package.json                  # Project dependencies and scripts
├── vite.config.js               # Vite configuration
└── README.md                    # Project documentation
```

## 🚀 Getting Started

### Prerequisites

- **Node.js** (v18.0.0 or higher)
- **npm** (v8.0.0 or higher)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/amirsalahshur/dev-resume.git
   cd dev-resume
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start development server**
   ```bash
   npm run dev
   ```

   The site will be available at `http://localhost:3000`

### Development

- **Development server**: `npm run dev`
- **Build for production**: `npm run build`
- **Preview production build**: `npm run preview`
- **Lint code**: `npm run lint`
- **Format code**: `npm run format`
- **Clean build directory**: `npm run clean`

## 🔧 Configuration

### Vite Configuration

The `vite.config.js` file includes:
- **Root directory**: Set to `src/` for cleaner structure
- **Build optimization**: Minification with Terser
- **Development server**: Hot reload and auto-open browser
- **CSS processing**: Source maps and optimization

### Environment Variables

Create a `.env` file in the root directory for environment-specific settings:

```env
# Analytics
VITE_GA_TRACKING_ID=your_google_analytics_id

# Contact Form (if implemented)
VITE_CONTACT_FORM_ENDPOINT=your_form_endpoint

# Deploy URL
VITE_BASE_URL=https://yourdomain.com
```

## 📱 Responsive Design

The website is fully responsive with breakpoints at:
- **Mobile**: < 768px
- **Tablet**: 768px - 1023px
- **Desktop**: ≥ 1024px

### Features by Device
- **Mobile**: Simplified layout, hidden ASCII art, touch-friendly interactions
- **Tablet**: Optimized grid layouts, condensed navigation
- **Desktop**: Full feature set, advanced animations, multi-column layouts

## ♿ Accessibility

- **Semantic HTML**: Proper heading hierarchy and landmark elements
- **ARIA Labels**: Screen reader support for interactive elements
- **Keyboard Navigation**: Full keyboard accessibility
- **Color Contrast**: WCAG AA compliant color ratios
- **Reduced Motion**: Respects `prefers-reduced-motion` setting
- **High Contrast**: Support for `prefers-contrast: high`

## 🎨 Customization

### Updating Content

1. **Personal Information**: Edit `src/index.html`
2. **Styling**: Modify CSS files in `src/styles/`
3. **Animations**: Adjust JavaScript modules in `src/scripts/modules/`

### Color Scheme

Colors are defined as CSS custom properties in `src/styles/base/_variables.css`:

```css
:root {
  --bg-dark: #0a0e27;
  --accent-green: #10b981;
  --accent-blue: #3b82f6;
  /* ... more colors */
}
```

### Typography

Typography settings in `src/styles/base/_typography.css`:
- **Font Family**: JetBrains Mono (monospace)
- **Responsive Sizes**: Using `clamp()` for fluid typography
- **Line Heights**: Optimized for readability

## 🚀 Deployment

### GitHub Pages

```bash
npm run deploy
```

This builds the project and deploys to GitHub Pages using the `gh-pages` package.

### Manual Deployment

1. **Build the project**
   ```bash
   npm run build
   ```

2. **Upload the `dist/` folder** to your web server

### Netlify/Vercel

The project is ready for deployment on modern hosting platforms:
- **Build Command**: `npm run build`
- **Publish Directory**: `dist`

## 🧪 Browser Support

- **Chrome**: ✅ Latest 2 versions
- **Firefox**: ✅ Latest 2 versions
- **Safari**: ✅ Latest 2 versions
- **Edge**: ✅ Latest 2 versions
- **Mobile Browsers**: ✅ iOS Safari, Chrome Mobile

## 📊 Performance

- **Lighthouse Score**: 95+ on all metrics
- **Bundle Size**: < 50KB gzipped
- **First Paint**: < 1.5s
- **Interactive**: < 2.5s

### Optimization Features
- **Code Splitting**: Modular JavaScript architecture
- **CSS Optimization**: Minified and compressed CSS
- **Image Optimization**: Optimized images and lazy loading
- **Caching**: Proper cache headers for static assets

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Code Style

- **JavaScript**: ESLint with recommended rules
- **CSS**: BEM methodology for naming
- **Commits**: Conventional commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

**Amir Salahshur**
- **Email**: amir@example.com
- **LinkedIn**: [linkedin.com/in/amirsalahshur](https://linkedin.com/in/amirsalahshur)
- **GitHub**: [github.com/amirsalahshur](https://github.com/amirsalahshur)

## 🙏 Acknowledgments

- **Vite**: For the excellent build tool
- **CSS Reset**: Inspired by modern CSS reset techniques
- **Design**: Terminal-inspired aesthetic with modern UX patterns
- **Icons**: Emoji icons for better accessibility and universal support

---

**Built with ❤️ and lots of ☕**