/**
 * Interactive Bézier Curve with Physics Simulation
 * 
 * This implementation includes:
 * 1. Manual cubic Bézier curve mathematics
 * 2. Tangent vector computation using derivatives
 * 3. Spring-damper physics simulation
 * 4. Real-time rendering at 60 FPS
 * 
 * No external libraries used for core functionality
 */

// ============================================================================
// CONSTANTS & CONFIGURATION
// ============================================================================

const CONFIG = {
    // Physics parameters
    springStiffness: 0.15,
    damping: 0.85,
    
    // Visual parameters
    tangentLength: 40,
    tangentCount: 10,
    curveSegments: 100,
    
    // Rendering options
    showTangents: true,
    showControlPoints: true,
    enablePhysics: true,
    showGradient: true,
    
    // Curve parameters
    numCurves: 3,  // Number of chained Bézier curves for rope effect
};

// ============================================================================
// CANVAS SETUP
// ============================================================================

const canvas = document.getElementById('bezierCanvas');
const ctx = canvas.getContext('2d');

// High DPI canvas setup
function resizeCanvas() {
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    
    ctx.scale(dpr, dpr);
    canvas.style.width = rect.width + 'px';
    canvas.style.height = rect.height + 'px';
}

resizeCanvas();
window.addEventListener('resize', resizeCanvas);

// ============================================================================
// VECTOR MATH UTILITIES
// ============================================================================

class Vector2D {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
    
    // Vector addition
    add(v) {
        return new Vector2D(this.x + v.x, this.y + v.y);
    }
    
    // Vector subtraction
    subtract(v) {
        return new Vector2D(this.x - v.x, this.y - v.y);
    }
    
    // Scalar multiplication
    multiply(scalar) {
        return new Vector2D(this.x * scalar, this.y * scalar);
    }
    
    // Vector magnitude
    magnitude() {
        return Math.sqrt(this.x * this.x + this.y * this.y);
    }
    
    // Normalize vector (unit vector)
    normalize() {
        const mag = this.magnitude();
        if (mag === 0) return new Vector2D(0, 0);
        return new Vector2D(this.x / mag, this.y / mag);
    }
    
    // Copy vector
    copy() {
        return new Vector2D(this.x, this.y);
    }
}

// ============================================================================
// CONTROL POINT WITH PHYSICS
// ============================================================================

class PhysicsPoint {
    constructor(x, y, fixed = false) {
        this.position = new Vector2D(x, y);
        this.velocity = new Vector2D(0, 0);
        this.target = new Vector2D(x, y);
        this.fixed = fixed;
    }
    
    /**
     * Update position using spring-damper physics
     * 
     * Spring-Damper Model:
     * acceleration = -k(position - target) - c·velocity
     * 
     * Where:
     * k = spring stiffness (restoring force)
     * c = damping coefficient (resistance)
     */
    update() {
        if (this.fixed || !CONFIG.enablePhysics) {
            this.position = this.target.copy();
            this.velocity = new Vector2D(0, 0);
            return;
        }
        
        // Calculate spring force: F = -k * displacement
        const displacement = this.position.subtract(this.target);
        const springForce = displacement.multiply(-CONFIG.springStiffness);
        
        // Calculate damping force: F = -c * velocity
        const dampingForce = this.velocity.multiply(-CONFIG.damping);
        
        // Total acceleration
        const acceleration = springForce.add(dampingForce);
        
        // Update velocity: v = v + a
        this.velocity = this.velocity.add(acceleration);
        
        // Update position: p = p + v
        this.position = this.position.add(this.velocity);
    }
    
    setTarget(x, y) {
        this.target = new Vector2D(x, y);
    }
}

// ============================================================================
// BÉZIER CURVE MATHEMATICS
// ============================================================================

class CubicBezier {
    constructor(p0, p1, p2, p3) {
        this.p0 = p0;  // Start point (fixed)
        this.p1 = p1;  // First control point (dynamic)
        this.p2 = p2;  // Second control point (dynamic)
        this.p3 = p3;  // End point (fixed)
    }
    
    /**
     * Compute point on Bézier curve at parameter t
     * 
     * Formula: B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
     * 
     * @param {number} t - Parameter value [0, 1]
     * @returns {Vector2D} Point on curve
     */
    getPoint(t) {
        const t2 = t * t;
        const t3 = t2 * t;
        const mt = 1 - t;
        const mt2 = mt * mt;
        const mt3 = mt2 * mt;
        
        // Calculate weighted sum of control points
        const x = mt3 * this.p0.position.x +
                  3 * mt2 * t * this.p1.position.x +
                  3 * mt * t2 * this.p2.position.x +
                  t3 * this.p3.position.x;
        
        const y = mt3 * this.p0.position.y +
                  3 * mt2 * t * this.p1.position.y +
                  3 * mt * t2 * this.p2.position.y +
                  t3 * this.p3.position.y;
        
        return new Vector2D(x, y);
    }
    
    /**
     * Compute tangent vector at parameter t
     * 
     * Derivative: B'(t) = 3(1-t)²(P₁-P₀) + 6(1-t)t(P₂-P₁) + 3t²(P₃-P₂)
     * 
     * @param {number} t - Parameter value [0, 1]
     * @returns {Vector2D} Tangent vector (not normalized)
     */
    getTangent(t) {
        const t2 = t * t;
        const mt = 1 - t;
        const mt2 = mt * mt;
        
        // First term: 3(1-t)²(P₁-P₀)
        const dx1 = this.p1.position.x - this.p0.position.x;
        const dy1 = this.p1.position.y - this.p0.position.y;
        const term1x = 3 * mt2 * dx1;
        const term1y = 3 * mt2 * dy1;
        
        // Second term: 6(1-t)t(P₂-P₁)
        const dx2 = this.p2.position.x - this.p1.position.x;
        const dy2 = this.p2.position.y - this.p1.position.y;
        const term2x = 6 * mt * t * dx2;
        const term2y = 6 * mt * t * dy2;
        
        // Third term: 3t²(P₃-P₂)
        const dx3 = this.p3.position.x - this.p2.position.x;
        const dy3 = this.p3.position.y - this.p2.position.y;
        const term3x = 3 * t2 * dx3;
        const term3y = 3 * t2 * dy3;
        
        return new Vector2D(
            term1x + term2x + term3x,
            term1y + term2y + term3y
        );
    }
    
    /**
     * Update physics for control points
     */
    update() {
        this.p0.update();
        this.p1.update();
        this.p2.update();
        this.p3.update();
    }
}

// ============================================================================
// CURVE CHAIN SYSTEM
// ============================================================================

class BezierChain {
    constructor() {
        this.curves = [];
        this.initialize();
    }
    
    initialize() {
        const width = canvas.getBoundingClientRect().width;
        const height = canvas.getBoundingClientRect().height;
        const centerY = height / 2;
        
        this.curves = [];
        
        // Create chain of connected Bézier curves
        for (let i = 0; i < CONFIG.numCurves; i++) {
            const segmentWidth = width / CONFIG.numCurves;
            const x0 = i * segmentWidth;
            const x3 = (i + 1) * segmentWidth;
            const x1 = x0 + segmentWidth * 0.33;
            const x2 = x0 + segmentWidth * 0.67;
            
            // First and last points are fixed
            const p0 = new PhysicsPoint(x0, centerY, i === 0);
            const p1 = new PhysicsPoint(x1, centerY);
            const p2 = new PhysicsPoint(x2, centerY);
            const p3 = new PhysicsPoint(x3, centerY, i === CONFIG.numCurves - 1);
            
            this.curves.push(new CubicBezier(p0, p1, p2, p3));
        }
    }
    
    update() {
        this.curves.forEach(curve => curve.update());
    }
    
    getAllPoints() {
        const points = [];
        this.curves.forEach(curve => {
            for (let t = 0; t <= 1; t += 1 / CONFIG.curveSegments) {
                points.push(curve.getPoint(t));
            }
        });
        return points;
    }
}

// ============================================================================
// RENDERING ENGINE
// ============================================================================

class Renderer {
    /**
     * Draw the complete Bézier curve
     */
    static drawCurve(chain) {
        const points = chain.getAllPoints();
        if (points.length < 2) return;
        
        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);
        
        if (CONFIG.showGradient) {
            // Create gradient along curve
            const gradient = ctx.createLinearGradient(
                points[0].x, points[0].y,
                points[points.length - 1].x, points[points.length - 1].y
            );
            gradient.addColorStop(0, '#ff6b6b');
            gradient.addColorStop(0.5, '#4ecdc4');
            gradient.addColorStop(1, '#45b7d1');
            
            ctx.strokeStyle = gradient;
        } else {
            ctx.strokeStyle = '#ffffff';
        }
        
        ctx.lineWidth = 4;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        
        // Draw smooth curve
        for (let i = 1; i < points.length; i++) {
            ctx.lineTo(points[i].x, points[i].y);
        }
        
        ctx.stroke();
        
        // Add glow effect
        ctx.shadowBlur = 20;
        ctx.shadowColor = CONFIG.showGradient ? '#4ecdc4' : '#ffffff';
        ctx.stroke();
        ctx.shadowBlur = 0;
    }
    
    /**
     * Draw tangent vectors at multiple points
     */
    static drawTangents(chain) {
        if (!CONFIG.showTangents) return;
        
        const step = 1 / CONFIG.tangentCount;
        
        chain.curves.forEach((curve, curveIndex) => {
            for (let i = 0; i <= CONFIG.tangentCount; i++) {
                const t = i * step;
                const point = curve.getPoint(t);
                const tangent = curve.getTangent(t).normalize();
                
                // Color based on position along curve
                const hue = (curveIndex / CONFIG.numCurves + t) * 180 + 180;
                ctx.strokeStyle = `hsl(${hue}, 70%, 60%)`;
                ctx.lineWidth = 2;
                
                // Draw tangent line
                const endX = point.x + tangent.x * CONFIG.tangentLength;
                const endY = point.y + tangent.y * CONFIG.tangentLength;
                
                ctx.beginPath();
                ctx.moveTo(point.x, point.y);
                ctx.lineTo(endX, endY);
                ctx.stroke();
                
                // Draw arrowhead
                this.drawArrow(point.x, point.y, endX, endY);
            }
        });
    }
    
    /**
     * Draw arrow at end of tangent
     */
    static drawArrow(x1, y1, x2, y2) {
        const angle = Math.atan2(y2 - y1, x2 - x1);
        const arrowLength = 8;
        const arrowAngle = Math.PI / 6;
        
        ctx.beginPath();
        ctx.moveTo(x2, y2);
        ctx.lineTo(
            x2 - arrowLength * Math.cos(angle - arrowAngle),
            y2 - arrowLength * Math.sin(angle - arrowAngle)
        );
        ctx.moveTo(x2, y2);
        ctx.lineTo(
            x2 - arrowLength * Math.cos(angle + arrowAngle),
            y2 - arrowLength * Math.sin(angle + arrowAngle)
        );
        ctx.stroke();
    }
    
    /**
     * Draw control points
     */
    static drawControlPoints(chain) {
        if (!CONFIG.showControlPoints) return;
        
        chain.curves.forEach(curve => {
            const points = [curve.p0, curve.p1, curve.p2, curve.p3];
            
            points.forEach((point, index) => {
                const isFixed = point.fixed;
                const isControl = index === 1 || index === 2;
                
                // Draw connection lines
                if (index > 0) {
                    ctx.strokeStyle = 'rgba(255, 255, 255, 0.2)';
                    ctx.lineWidth = 1;
                    ctx.setLineDash([5, 5]);
                    ctx.beginPath();
                    ctx.moveTo(points[index - 1].position.x, points[index - 1].position.y);
                    ctx.lineTo(point.position.x, point.position.y);
                    ctx.stroke();
                    ctx.setLineDash([]);
                }
                
                // Draw point
                ctx.beginPath();
                ctx.arc(point.position.x, point.position.y, isControl ? 6 : 8, 0, Math.PI * 2);
                
                if (isFixed) {
                    ctx.fillStyle = '#ffffff';
                } else if (isControl) {
                    ctx.fillStyle = '#ff6b6b';
                } else {
                    ctx.fillStyle = '#4ecdc4';
                }
                
                ctx.fill();
                
                // Outline
                ctx.strokeStyle = '#ffffff';
                ctx.lineWidth = 2;
                ctx.stroke();
            });
        });
    }
    
    /**
     * Clear canvas
     */
    static clear() {
        const width = canvas.getBoundingClientRect().width;
        const height = canvas.getBoundingClientRect().height;
        ctx.clearRect(0, 0, width, height);
    }
}

// ============================================================================
// INPUT HANDLING
// ============================================================================

class InputHandler {
    static mouseX = 0;
    static mouseY = 0;
    static isDragging = false;
    
    static initialize(chain) {
        // Mouse move
        canvas.addEventListener('mousemove', (e) => {
            const rect = canvas.getBoundingClientRect();
            this.mouseX = e.clientX - rect.left;
            this.mouseY = e.clientY - rect.top;
            
            this.updateTargets(chain);
        });
        
        // Touch support
        canvas.addEventListener('touchmove', (e) => {
            e.preventDefault();
            const rect = canvas.getBoundingClientRect();
            const touch = e.touches[0];
            this.mouseX = touch.clientX - rect.left;
            this.mouseY = touch.clientY - rect.top;
            
            this.updateTargets(chain);
        }, { passive: false });
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            switch(e.key.toLowerCase()) {
                case 't':
                    CONFIG.showTangents = !CONFIG.showTangents;
                    document.getElementById('showTangents').checked = CONFIG.showTangents;
                    break;
                case 'c':
                    CONFIG.showControlPoints = !CONFIG.showControlPoints;
                    document.getElementById('showControlPoints').checked = CONFIG.showControlPoints;
                    break;
                case 'p':
                    CONFIG.enablePhysics = !CONFIG.enablePhysics;
                    document.getElementById('enablePhysics').checked = CONFIG.enablePhysics;
                    break;
                case 'r':
                    resetSimulation();
                    break;
                case '1':
                    applyPreset('bouncy');
                    break;
                case '2':
                    applyPreset('smooth');
                    break;
                case '3':
                    applyPreset('stiff');
                    break;
                case '4':
                    applyPreset('fluid');
                    break;
            }
        });
    }
    
    static updateTargets(chain) {
        const width = canvas.getBoundingClientRect().width;
        const height = canvas.getBoundingClientRect().height;
        
        // Update control points based on mouse position
        chain.curves.forEach((curve, index) => {
            const progress = index / (CONFIG.numCurves - 1 || 1);
            
            // Create wave effect based on mouse position
            const offsetX = (this.mouseX - width / 2) * 0.3 * (1 - Math.abs(progress - 0.5) * 2);
            const offsetY = (this.mouseY - height / 2) * 0.5;
            
            const centerX1 = curve.p1.target.x;
            const centerX2 = curve.p2.target.x;
            const centerY = height / 2;
            
            curve.p1.setTarget(centerX1 + offsetX, centerY + offsetY * 0.8);
            curve.p2.setTarget(centerX2 + offsetX, centerY + offsetY * 1.2);
        });
    }
}

// ============================================================================
// UI CONTROLS
// ============================================================================

function setupControls(chain) {
    // Spring stiffness
    const springSlider = document.getElementById('springStiffness');
    const springValue = document.getElementById('springValue');
    springSlider.addEventListener('input', (e) => {
        CONFIG.springStiffness = parseFloat(e.target.value);
        springValue.textContent = CONFIG.springStiffness.toFixed(2);
    });
    
    // Damping
    const dampingSlider = document.getElementById('damping');
    const dampingValue = document.getElementById('dampingValue');
    dampingSlider.addEventListener('input', (e) => {
        CONFIG.damping = parseFloat(e.target.value);
        dampingValue.textContent = CONFIG.damping.toFixed(2);
    });
    
    // Tangent length
    const tangentLengthSlider = document.getElementById('tangentLength');
    const tangentLengthValue = document.getElementById('tangentLengthValue');
    tangentLengthSlider.addEventListener('input', (e) => {
        CONFIG.tangentLength = parseInt(e.target.value);
        tangentLengthValue.textContent = CONFIG.tangentLength;
    });
    
    // Tangent count
    const tangentCountSlider = document.getElementById('tangentCount');
    const tangentCountValue = document.getElementById('tangentCountValue');
    tangentCountSlider.addEventListener('input', (e) => {
        CONFIG.tangentCount = parseInt(e.target.value);
        tangentCountValue.textContent = CONFIG.tangentCount;
    });
    
    // Checkboxes
    document.getElementById('showTangents').addEventListener('change', (e) => {
        CONFIG.showTangents = e.target.checked;
    });
    
    document.getElementById('showControlPoints').addEventListener('change', (e) => {
        CONFIG.showControlPoints = e.target.checked;
    });
    
    document.getElementById('enablePhysics').addEventListener('change', (e) => {
        CONFIG.enablePhysics = e.target.checked;
    });
    
    document.getElementById('showGradient').addEventListener('change', (e) => {
        CONFIG.showGradient = e.target.checked;
    });
}

// Preset configurations
function applyPreset(preset) {
    const presets = {
        bouncy: { spring: 0.08, damping: 0.75 },
        smooth: { spring: 0.15, damping: 0.90 },
        stiff: { spring: 0.35, damping: 0.95 },
        fluid: { spring: 0.05, damping: 0.80 }
    };
    
    const config = presets[preset];
    if (config) {
        CONFIG.springStiffness = config.spring;
        CONFIG.damping = config.damping;
        
        document.getElementById('springStiffness').value = config.spring;
        document.getElementById('damping').value = config.damping;
        document.getElementById('springValue').textContent = config.spring.toFixed(2);
        document.getElementById('dampingValue').textContent = config.damping.toFixed(2);
    }
}

// Reset simulation
function resetSimulation() {
    bezierChain.initialize();
    InputHandler.mouseX = canvas.getBoundingClientRect().width / 2;
    InputHandler.mouseY = canvas.getBoundingClientRect().height / 2;
}

// ============================================================================
// ANIMATION LOOP
// ============================================================================

let lastTime = performance.now();
let frameCount = 0;
let fps = 60;

function animate(currentTime) {
    // Update FPS counter
    frameCount++;
    const deltaTime = currentTime - lastTime;
    
    if (deltaTime >= 1000) {
        fps = Math.round((frameCount * 1000) / deltaTime);
        document.getElementById('fps').textContent = fps;
        frameCount = 0;
        lastTime = currentTime;
    }
    
    // Update physics
    bezierChain.update();
    
    // Render
    Renderer.clear();
    Renderer.drawCurve(bezierChain);
    Renderer.drawTangents(bezierChain);
    Renderer.drawControlPoints(bezierChain);
    
    // Continue animation
    requestAnimationFrame(animate);
}

// ============================================================================
// INITIALIZATION
// ============================================================================

// Create curve chain
const bezierChain = new BezierChain();

// Setup input handlers
InputHandler.initialize(bezierChain);

// Setup UI controls
setupControls(bezierChain);

// Start animation
requestAnimationFrame(animate);

console.log('🎨 Bézier Curve Simulator initialized');
console.log('📐 Manual implementation - no external libraries');
console.log('⌨️  Press T, C, P, R or 1-4 for controls');
