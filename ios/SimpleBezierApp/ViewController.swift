// ============================================================================
// Interactive Bézier Curve with Physics Simulation - iOS Implementation
// ============================================================================
// Date: December 15, 2025
// Complete manual implementation matching web version
//
// Mathematical Foundations:
// - Cubic Bézier: B(t) = (1−t)³P₀ + 3(1−t)²tP₁ + 3(1−t)t²P₂ + t³P₃
// - Tangent (First Derivative): B'(t) = 3(1−t)²(P₁−P₀) + 6(1−t)t(P₂−P₁) + 3t²(P₃−P₂)
// - Spring-Damper Physics: F = -k·x - c·v
// - Euler Integration: v(t+Δt) = v(t) + a·Δt, p(t+Δt) = p(t) + v·Δt
//
// NO UIBezierPath or animation frameworks - 100% manual implementation
// ============================================================================

import UIKit

// MARK: - Configuration

/// Global physics and visual configuration
struct PhysicsConfig {
    // Physics parameters
    var springStiffness: CGFloat = 0.15     // Spring constant (k)
    var damping: CGFloat = 0.85             // Damping coefficient (c)
    var enablePhysics: Bool = true
    
    // Visual parameters
    var tangentLength: CGFloat = 40         // Length of tangent arrows in pixels
    var tangentCount: Int = 10              // Number of tangents per curve
    var curveSegments: Int = 100            // Sampling points per curve
    
    // Toggles
    var showTangents: Bool = true
    var showControlPoints: Bool = true
    var showGradient: Bool = true
    
    // System
    var numCurves: Int = 3                  // Number of chained curves
    
    static var `default`: PhysicsConfig {
        return PhysicsConfig()
    }
}

// MARK: - Vector2D (Mathematical Foundation)

/// 2D Vector for position, velocity, and force calculations
struct Vector2D {
    var x: CGFloat
    var y: CGFloat
    
    init(_ x: CGFloat, _ y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    // Vector addition: V₁ + V₂ = (x₁ + x₂, y₁ + y₂)
    func add(_ other: Vector2D) -> Vector2D {
        return Vector2D(x + other.x, y + other.y)
    }
    
    // Vector subtraction: V₁ - V₂ = (x₁ - x₂, y₁ - y₂)
    func subtract(_ other: Vector2D) -> Vector2D {
        return Vector2D(x - other.x, y - other.y)
    }
    
    // Scalar multiplication: k·V = (k·x, k·y)
    func multiply(_ scalar: CGFloat) -> Vector2D {
        return Vector2D(x * scalar, y * scalar)
    }
    
    // Magnitude: |V| = √(x² + y²)
    func magnitude() -> CGFloat {
        return sqrt(x * x + y * y)
    }
    
    // Normalize: V̂ = V / |V|
    func normalize() -> Vector2D {
        let mag = magnitude()
        if mag < 1e-10 { // Avoid division by zero
            return Vector2D(0, 0)
        }
        return Vector2D(x / mag, y / mag)
    }
    
    func copy() -> Vector2D {
        return Vector2D(x, y)
    }
    
    func toCGPoint() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
}

// MARK: - PhysicsPoint

/// Individual control point with spring-damper physics simulation
class PhysicsPoint {
    var position: Vector2D          // Current position
    var velocity: Vector2D          // Current velocity
    var target: Vector2D            // Desired position (set by user interaction)
    var isFixed: Bool               // Fixed points don't move
    
    init(x: CGFloat, y: CGFloat, fixed: Bool = false) {
        self.position = Vector2D(x, y)
        self.velocity = Vector2D(0, 0)
        self.target = Vector2D(x, y)
        self.isFixed = fixed
    }
    
    /// Update physics simulation one frame
    /// Implements spring-damper system:
    /// - Spring force: Fs = -k·(position - target)
    /// - Damping force: Fd = -c·velocity
    /// - Total force: F = Fs + Fd
    /// - Acceleration: a = F (assuming mass = 1)
    func update(config: PhysicsConfig) {
        // Fixed points don't move
        if isFixed || !config.enablePhysics {
            position = target.copy()
            velocity = Vector2D(0, 0)
            return
        }
        
        // Calculate displacement from target
        let displacement = position.subtract(target)
        
        // Hooke's Law: F = -k·x
        let springForce = displacement.multiply(-config.springStiffness)
        
        // Damping: F = -c·v (opposes velocity)
        let dampingForce = velocity.multiply(-config.damping)
        
        // Newton's Second Law: F = ma (with mass = 1)
        let acceleration = springForce.add(dampingForce)
        
        // Euler integration
        velocity = velocity.add(acceleration)
        position = position.add(velocity)
    }
    
    func setTarget(_ x: CGFloat, _ y: CGFloat) {
        target = Vector2D(x, y)
    }
}

// MARK: - CubicBezier

/// Single cubic Bézier curve segment with manual mathematical implementation
class CubicBezier {
    var p0: PhysicsPoint  // Start point
    var p1: PhysicsPoint  // First control point
    var p2: PhysicsPoint  // Second control point
    var p3: PhysicsPoint  // End point
    
    init(p0: PhysicsPoint, p1: PhysicsPoint, p2: PhysicsPoint, p3: PhysicsPoint) {
        self.p0 = p0
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
    }
    
    /// Calculate point on curve at parameter t using cubic Bézier formula
    /// B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
    /// where t ∈ [0, 1]
    func getPoint(t: CGFloat) -> Vector2D {
        // Pre-calculate powers for efficiency
        let t2 = t * t           // t²
        let t3 = t2 * t          // t³
        let mt = 1 - t           // (1-t)
        let mt2 = mt * mt        // (1-t)²
        let mt3 = mt2 * mt       // (1-t)³
        
        // Calculate x-coordinate using Bézier formula
        let x = mt3 * p0.position.x +              // Term 1: (1-t)³P₀
                3 * mt2 * t * p1.position.x +      // Term 2: 3(1-t)²tP₁
                3 * mt * t2 * p2.position.x +      // Term 3: 3(1-t)t²P₂
                t3 * p3.position.x                 // Term 4: t³P₃
        
        // Calculate y-coordinate (same formula)
        let y = mt3 * p0.position.y +
                3 * mt2 * t * p1.position.y +
                3 * mt * t2 * p2.position.y +
                t3 * p3.position.y
        
        return Vector2D(x, y)
    }
    
    /// Calculate tangent vector (first derivative) at parameter t
    /// B'(t) = 3(1-t)²(P₁-P₀) + 6(1-t)t(P₂-P₁) + 3t²(P₃-P₂)
    /// The result represents instantaneous direction and speed at point t
    func getTangent(t: CGFloat) -> Vector2D {
        let t2 = t * t
        let mt = 1 - t
        let mt2 = mt * mt
        
        // Term 1: 3(1-t)²(P₁-P₀)
        let dx1 = p1.position.x - p0.position.x
        let dy1 = p1.position.y - p0.position.y
        let term1x = 3 * mt2 * dx1
        let term1y = 3 * mt2 * dy1
        
        // Term 2: 6(1-t)t(P₂-P₁)
        let dx2 = p2.position.x - p1.position.x
        let dy2 = p2.position.y - p1.position.y
        let term2x = 6 * mt * t * dx2
        let term2y = 6 * mt * t * dy2
        
        // Term 3: 3t²(P₃-P₂)
        let dx3 = p3.position.x - p2.position.x
        let dy3 = p3.position.y - p2.position.y
        let term3x = 3 * t2 * dx3
        let term3y = 3 * t2 * dy3
        
        // Sum all terms
        return Vector2D(
            term1x + term2x + term3x,
            term1y + term2y + term3y
        )
    }
    
    func update(config: PhysicsConfig) {
        p0.update(config: config)
        p1.update(config: config)
        p2.update(config: config)
        p3.update(config: config)
    }
}

// MARK: - BezierChain

/// Chain of connected Bézier curves (P₃ of curve N = P₀ of curve N+1)
class BezierChain {
    var curves: [CubicBezier] = []
    
    init(numCurves: Int, width: CGFloat, height: CGFloat) {
        initializeChain(numCurves: numCurves, width: width, height: height)
    }
    
    private func initializeChain(numCurves: Int, width: CGFloat, height: CGFloat) {
        curves.removeAll()
        
        let segmentWidth = width / CGFloat(numCurves)
        let centerY = height / 2
        
        for i in 0..<numCurves {
            let startX = CGFloat(i) * segmentWidth
            let endX = CGFloat(i + 1) * segmentWidth
            
            // Create control points
            let p0 = PhysicsPoint(x: startX, y: centerY, fixed: i == 0)
            let p1 = PhysicsPoint(x: startX + segmentWidth * 0.33, y: centerY - 50)
            let p2 = PhysicsPoint(x: startX + segmentWidth * 0.67, y: centerY + 50)
            let p3 = PhysicsPoint(x: endX, y: centerY, fixed: i == numCurves - 1)
            
            // If not first curve, connect to previous curve's end point
            if i > 0 {
                curves[i - 1].p3 = p0
            }
            
            let curve = CubicBezier(p0: p0, p1: p1, p2: p2, p3: p3)
            curves.append(curve)
        }
    }
    
    func update(config: PhysicsConfig) {
        for curve in curves {
            curve.update(config: config)
        }
    }
    
    func getAllPoints() -> [PhysicsPoint] {
        var points: [PhysicsPoint] = []
        for curve in curves {
            if points.isEmpty {
                points.append(curve.p0)
            }
            points.append(curve.p1)
            points.append(curve.p2)
            points.append(curve.p3)
        }
        return points
    }
}

// MARK: - BezierCanvasView

/// Custom view for rendering Bézier curves with manual Core Graphics
class BezierCanvasView: UIView {
    var bezierChain: BezierChain!
    var config: PhysicsConfig
    
    init(config: PhysicsConfig) {
        self.config = config
        super.init(frame: .zero)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeChain() {
        bezierChain = BezierChain(numCurves: config.numCurves, width: bounds.width, height: bounds.height)
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), let chain = bezierChain else { return }
        
        // Draw main curves
        drawCurves(ctx: ctx, chain: chain)
        
        // Draw tangent vectors
        if config.showTangents {
            drawTangents(ctx: ctx, chain: chain)
        }
        
        // Draw control points
        if config.showControlPoints {
            drawControlPoints(ctx: ctx, chain: chain)
        }
    }
    
    /// Draw all Bézier curves with gradient or solid color
    private func drawCurves(ctx: CGContext, chain: BezierChain) {
        for (curveIndex, curve) in chain.curves.enumerated() {
            let path = UIBezierPath()
            
            // Sample curve at regular intervals (NO UIBezierPath curve methods!)
            var points: [CGPoint] = []
            for i in 0...config.curveSegments {
                let t = CGFloat(i) / CGFloat(config.curveSegments)
                let point = curve.getPoint(t: t)
                points.append(point.toCGPoint())
            }
            
            // Build path manually
            if let first = points.first {
                path.move(to: first)
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
            
            // Draw with neon gradient effect
            ctx.saveGState()
            
            // Set line style
            ctx.setLineWidth(4)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            
            // Create neon colors based on curve index: #22D3EE, #A78BFA, #F472B6
            let neonColors = [
                UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1.0), // #22D3EE Cyan
                UIColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 1.0), // #A78BFA Purple
                UIColor(red: 0.96, green: 0.45, blue: 0.71, alpha: 1.0)  // #F472B6 Pink
            ]
            let color = neonColors[curveIndex % neonColors.count]
            ctx.setStrokeColor(color.cgColor)
            
            // Add intense neon glow effect
            ctx.setShadow(offset: .zero, blur: 20, color: color.cgColor)
            
            ctx.addPath(path.cgPath)
            ctx.strokePath()
            
            ctx.restoreGState()
        }
    }
    
    /// Draw tangent vectors as arrows with color gradient
    private func drawTangents(ctx: CGContext, chain: BezierChain) {
        for (curveIndex, curve) in chain.curves.enumerated() {
            for i in 0..<config.tangentCount {
                let t = CGFloat(i) / CGFloat(config.tangentCount - 1)
                
                // Get point and tangent
                let point = curve.getPoint(t: t)
                let tangent = curve.getTangent(t: t).normalize()
                
                // Calculate arrow end point
                let endPoint = Vector2D(
                    point.x + tangent.x * config.tangentLength,
                    point.y + tangent.y * config.tangentLength
                )
                
                // Color based on neon accents matching curve colors
                let neonColors = [
                    UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 0.9), // #22D3EE Cyan
                    UIColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 0.9), // #A78BFA Purple
                    UIColor(red: 0.96, green: 0.45, blue: 0.71, alpha: 0.9)  // #F472B6 Pink
                ]
                
                // Blend between curve color and next color based on t
                let currentColorIndex = curveIndex % neonColors.count
                let nextColorIndex = (curveIndex + 1) % neonColors.count
                
                // Simple interpolation for smooth gradient
                let color = t < 0.5 ? neonColors[currentColorIndex] : neonColors[nextColorIndex]
                
                // Draw arrow
                drawArrow(ctx: ctx, from: point.toCGPoint(), to: endPoint.toCGPoint(), color: color)
            }
        }
    }
    
    /// Draw an arrow from one point to another
    private func drawArrow(ctx: CGContext, from: CGPoint, to: CGPoint, color: UIColor) {
        ctx.saveGState()
        
        // Draw line
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(2)
        ctx.setLineCap(.round)
        
        ctx.move(to: from)
        ctx.addLine(to: to)
        ctx.strokePath()
        
        // Draw arrowhead
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowAngle: CGFloat = .pi / 6 // 30 degrees
        let arrowLength: CGFloat = 8
        
        let point1 = CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        )
        let point2 = CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        )
        
        ctx.setFillColor(color.cgColor)
        ctx.move(to: to)
        ctx.addLine(to: point1)
        ctx.addLine(to: point2)
        ctx.closePath()
        ctx.fillPath()
        
        ctx.restoreGState()
    }
    
    /// Draw control points and connecting lines
    private func drawControlPoints(ctx: CGContext, chain: BezierChain) {
        ctx.saveGState()
        
        // Draw connecting lines first (behind points)
        ctx.setStrokeColor(UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 0.2).cgColor) // #F8FAFC subtle
        ctx.setLineWidth(1.5)
        ctx.setLineDash(phase: 0, lengths: [5, 5])
        
        for curve in chain.curves {
            ctx.move(to: curve.p0.position.toCGPoint())
            ctx.addLine(to: curve.p1.position.toCGPoint())
            ctx.addLine(to: curve.p2.position.toCGPoint())
            ctx.addLine(to: curve.p3.position.toCGPoint())
        }
        ctx.strokePath()
        
        // Draw control points
        ctx.setLineDash(phase: 0, lengths: [])
        
        for curve in chain.curves {
            // P0 and P3 (endpoints) - #F8FAFC light slate, larger
            if curve.p0.isFixed {
                drawControlPoint(ctx: ctx, point: curve.p0.position.toCGPoint(), 
                               color: UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1.0), radius: 8)
            }
            if curve.p3.isFixed {
                drawControlPoint(ctx: ctx, point: curve.p3.position.toCGPoint(), 
                               color: UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1.0), radius: 8)
            }
            
            // P1 and P2 (control points) - pink and cyan
            drawControlPoint(ctx: ctx, point: curve.p1.position.toCGPoint(), 
                           color: UIColor(red: 0.96, green: 0.45, blue: 0.71, alpha: 1.0), radius: 6) // #F472B6
            drawControlPoint(ctx: ctx, point: curve.p2.position.toCGPoint(), 
                           color: UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1.0), radius: 6) // #22D3EE Cyan
        }
        
        ctx.restoreGState()
    }
    
    private func drawControlPoint(ctx: CGContext, point: CGPoint, color: UIColor, radius: CGFloat) {
        // Outer circle (white border)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: point.x - radius - 1, y: point.y - radius - 1, 
                                   width: (radius + 1) * 2, height: (radius + 1) * 2))
        
        // Inner circle (colored)
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, 
                                   width: radius * 2, height: radius * 2))
    }
    
    // MARK: - Touch Handling
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let chain = bezierChain else { return }
        let location = touch.location(in: self)
        updateTargetsFromTouch(location: location, chain: chain)
        setNeedsDisplay()
    }
    
    /// Update control point targets based on touch/mouse position
    /// Creates "wave" effect with falloff from center
    private func updateTargetsFromTouch(location: CGPoint, chain: BezierChain) {
        let width = bounds.width
        let height = bounds.height
        let centerX = width / 2
        let centerY = height / 2
        
        // Calculate offset from center
        let offsetX = (location.x - centerX) * 0.3
        let offsetY = (location.y - centerY) * 0.5
        
        // Apply to control points with falloff
        for (index, curve) in chain.curves.enumerated() {
            let progress = CGFloat(index) / CGFloat(chain.curves.count - 1)
            
            // Parabolic falloff: middle moves more than edges
            let falloff = 1 - abs(progress - 0.5) * 2
            
            // Get original positions
            let segmentWidth = width / CGFloat(chain.curves.count)
            let startX = CGFloat(index) * segmentWidth
            
            // Update control points (not endpoints)
            curve.p1.setTarget(
                startX + segmentWidth * 0.33 + offsetX * falloff,
                centerY - 50 + offsetY * 0.8
            )
            
            curve.p2.setTarget(
                startX + segmentWidth * 0.67 + offsetX * falloff,
                centerY + 50 + offsetY * 1.2
            )
        }
    }
}

// MARK: - Control Panel

protocol ControlPanelDelegate: AnyObject {
    func didUpdateSpringStiffness(_ value: CGFloat)
    func didUpdateDamping(_ value: CGFloat)
    func didToggleTangents(_ show: Bool)
    func didToggleControlPoints(_ show: Bool)
    func didTogglePhysics(_ enabled: Bool)
    func didTapReset()
    func didSelectPreset(_ preset: String)
}

class ControlPanelView: UIView {
    weak var delegate: ControlPanelDelegate?
    
    private var springSlider: UISlider!
    private var dampingSlider: UISlider!
    private var tangentsSwitch: UISwitch!
    private var controlPointsSwitch: UISwitch!
    private var physicsSwitch: UISwitch!
    
    private var springLabel: UILabel!
    private var dampingLabel: UILabel!
    
    private var scrollView: UIScrollView!
    private var hasSetupControls = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Setup controls on first layout when we have correct bounds
        if !hasSetupControls && bounds.width > 0 {
            hasSetupControls = true
            setupControls()
        }
        
        // Update blur view frame when bounds change
        subviews.first(where: { $0 is UIVisualEffectView })?.frame = bounds
    }
    
    private func setupUI() {
        // Glassmorphism background
        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        // Add blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        insertSubview(blurView, at: 0)
        
        // Controls will be setup in layoutSubviews when we have correct bounds
    }
    
    private func setupControls() {
        let scrollView = UIScrollView()
        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        addSubview(scrollView)
        
        let contentWidth = bounds.width
        let contentView = UIView()
        contentView.backgroundColor = .clear
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: 450)
        scrollView.addSubview(contentView)
        scrollView.contentSize = CGSize(width: contentWidth, height: 450)
        
        print("DEBUG: ControlPanel bounds.width = \(bounds.width)")
        print("DEBUG: contentWidth = \(contentWidth)")
        
        var yOffset: CGFloat = 15
        
        // Title
        let titleLabel = createLabel(text: "⚙️ Physics Controls", fontSize: 18, bold: true)
        titleLabel.frame = CGRect(x: 15, y: yOffset, width: contentWidth - 30, height: 25)
        contentView.addSubview(titleLabel)
        yOffset += 35
        
        // Spring Stiffness
        springLabel = createLabel(text: "Spring: 0.15", fontSize: 14, bold: false)
        springLabel.frame = CGRect(x: 15, y: yOffset, width: contentWidth - 30, height: 20)
        contentView.addSubview(springLabel)
        yOffset += 25
        
        springSlider = createSlider(min: 0.01, max: 0.5, value: 0.15)
        springSlider.frame = CGRect(x: 15, y: yOffset, width: contentWidth - 30, height: 30)
        springSlider.addTarget(self, action: #selector(springChanged), for: .valueChanged)
        contentView.addSubview(springSlider)
        yOffset += 40
        
        // Damping
        dampingLabel = createLabel(text: "Damping: 0.85", fontSize: 14, bold: false)
        dampingLabel.frame = CGRect(x: 15, y: yOffset, width: contentWidth - 30, height: 20)
        contentView.addSubview(dampingLabel)
        yOffset += 25
        
        dampingSlider = createSlider(min: 0.5, max: 0.99, value: 0.85)
        dampingSlider.frame = CGRect(x: 15, y: yOffset, width: contentWidth - 30, height: 30)
        dampingSlider.addTarget(self, action: #selector(dampingChanged), for: .valueChanged)
        contentView.addSubview(dampingSlider)
        yOffset += 45
        
        // Toggles
        yOffset = addToggle(to: contentView, yOffset: yOffset, text: "Show Tangents", 
                           width: contentWidth, action: #selector(tangentsToggled), initialValue: true, switch: &tangentsSwitch)
        yOffset = addToggle(to: contentView, yOffset: yOffset, text: "Show Control Points", 
                           width: contentWidth, action: #selector(controlPointsToggled), initialValue: true, switch: &controlPointsSwitch)
        yOffset = addToggle(to: contentView, yOffset: yOffset, text: "Enable Physics", 
                           width: contentWidth, action: #selector(physicsToggled), initialValue: true, switch: &physicsSwitch)
        
        // Preset Buttons
        let presetLabel = createLabel(text: "Presets:", fontSize: 14, bold: true)
        presetLabel.frame = CGRect(x: 15, y: yOffset, width: contentWidth - 30, height: 20)
        contentView.addSubview(presetLabel)
        yOffset += 25
        
        let presets = ["Bouncy", "Smooth", "Stiff", "Fluid"]
        let buttonWidth = (contentWidth - 60) / 4
        for (index, preset) in presets.enumerated() {
            let button = createPresetButton(title: preset)
            button.frame = CGRect(x: 15 + CGFloat(index) * (buttonWidth + 5), y: yOffset, 
                                 width: buttonWidth, height: 32)
            button.tag = index
            contentView.addSubview(button)
        }
        yOffset += 40
        
        // Reset Button
        let resetButton = createButton(title: "🔄 Reset")
        resetButton.frame = CGRect(x: 15, y: yOffset, width: contentWidth - 30, height: 40)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        contentView.addSubview(resetButton)
    }
    
    private func createLabel(text: String, fontSize: CGFloat, bold: Bool) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        label.textColor = .white
        return label
    }
    
    private func createSlider(min: Float, max: Float, value: Float) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        slider.tintColor = UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1.0) // #22D3EE Cyan
        return slider
    }
    
    private func addToggle(to view: UIView, yOffset: CGFloat, text: String, 
                          width: CGFloat, action: Selector, initialValue: Bool, switch switchView: inout UISwitch!) -> CGFloat {
        let label = createLabel(text: text, fontSize: 14, bold: false)
        label.frame = CGRect(x: 15, y: yOffset, width: width - 80, height: 30)
        view.addSubview(label)
        
        let toggle = UISwitch()
        toggle.isOn = initialValue
        toggle.onTintColor = UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1.0) // #22D3EE Cyan
        toggle.frame.origin = CGPoint(x: width - 65, y: yOffset)
        toggle.addTarget(self, action: action, for: .valueChanged)
        view.addSubview(toggle)
        
        switchView = toggle
        return yOffset + 35
    }
    
    private func createPresetButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(presetTapped), for: .touchUpInside)
        return button
    }
    
    private func createButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 0.8)
        button.layer.cornerRadius = 12
        return button
    }
    
    // MARK: - Actions
    
    @objc private func springChanged() {
        let value = CGFloat(springSlider.value)
        springLabel.text = String(format: "Spring: %.2f", value)
        delegate?.didUpdateSpringStiffness(value)
    }
    
    @objc private func dampingChanged() {
        let value = CGFloat(dampingSlider.value)
        dampingLabel.text = String(format: "Damping: %.2f", value)
        delegate?.didUpdateDamping(value)
    }
    
    @objc private func tangentsToggled() {
        delegate?.didToggleTangents(tangentsSwitch.isOn)
    }
    
    @objc private func controlPointsToggled() {
        delegate?.didToggleControlPoints(controlPointsSwitch.isOn)
    }
    
    @objc private func physicsToggled() {
        delegate?.didTogglePhysics(physicsSwitch.isOn)
    }
    
    @objc private func resetTapped() {
        delegate?.didTapReset()
    }
    
    @objc private func presetTapped(_ sender: UIButton) {
        let presets = ["Bouncy", "Smooth", "Stiff", "Fluid"]
        let preset = presets[sender.tag]
        delegate?.didSelectPreset(preset)
        
        // Update UI
        switch preset {
        case "Bouncy":
            springSlider.value = 0.08
            dampingSlider.value = 0.75
        case "Smooth":
            springSlider.value = 0.15
            dampingSlider.value = 0.90
        case "Stiff":
            springSlider.value = 0.35
            dampingSlider.value = 0.95
        case "Fluid":
            springSlider.value = 0.05
            dampingSlider.value = 0.80
        default:
            break
        }
        
        springChanged()
        dampingChanged()
    }
}

// MARK: - Main View Controller

class ViewController: UIViewController, ControlPanelDelegate {
    
    // Core components
    private var bezierCanvas: BezierCanvasView!
    private var controlPanel: ControlPanelView!
    private var fpsLabel: UILabel!
    private var infoLabel: UILabel!
    
    // Animation system
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastFrameTime: CFTimeInterval = 0
    
    // Configuration
    private var config = PhysicsConfig.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGradientBackground()
        setupTitleLabel()
        setupInfoLabel()
        setupBezierCanvas()
        setupControlPanel()
        setupFPSLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bezierCanvas.initializeChain()
        startAnimation()
    }
    
    // MARK: - Setup Methods
    
    private func setupGradientBackground() {
        // Dark Slate professional gradient (#1E293B)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1.0).cgColor,  // #1E293B
            UIColor(red: 0.09, green: 0.13, blue: 0.19, alpha: 1.0).cgColor,  // Darker variant
            UIColor(red: 0.15, green: 0.19, blue: 0.27, alpha: 1.0).cgColor   // Lighter variant
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupTitleLabel() {
        let label = UILabel()
        label.text = " Interactive Bézier Physics"
        label.font = UIFont.boldSystemFont(ofSize: 26)
        label.textColor = UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1.0) // #F8FAFC
        label.textAlignment = .center
        label.frame = CGRect(x: 20, y: 60, width: view.bounds.width - 40, height: 35)
        label.layer.shadowColor = UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1.0).cgColor // Cyan glow
        label.layer.shadowOpacity = 0.6
        label.layer.shadowRadius = 10
        label.layer.shadowOffset = .zero
        view.addSubview(label)
    }
    
    private func setupInfoLabel() {
        infoLabel = UILabel()
        infoLabel.text = "Drag on canvas to interact"
        infoLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        infoLabel.textColor = UIColor(red: 0.75, green: 0.8, blue: 0.85, alpha: 0.9)
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.frame = CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 30)
        view.addSubview(infoLabel)
    }
    
    private func setupBezierCanvas() {
        bezierCanvas = BezierCanvasView(config: config)
        let safeArea = view.safeAreaInsets
        let canvasHeight = view.bounds.height * 0.45  // 45% of screen
        
        bezierCanvas.frame = CGRect(
            x: 20,
            y: 140,
            width: view.bounds.width - 40,
            height: canvasHeight
        )
        bezierCanvas.backgroundColor = UIColor(red: 0.1, green: 0.13, blue: 0.18, alpha: 0.5)
        bezierCanvas.layer.cornerRadius = 20
        bezierCanvas.layer.borderWidth = 2
        bezierCanvas.layer.borderColor = UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 0.4).cgColor // #22D3EE
        bezierCanvas.layer.shadowColor = UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1.0).cgColor
        bezierCanvas.layer.shadowOpacity = 0.3
        bezierCanvas.layer.shadowRadius = 15
        bezierCanvas.layer.shadowOffset = .zero
        view.addSubview(bezierCanvas)
    }
    
    private func setupControlPanel() {
        controlPanel = ControlPanelView()
        let canvasBottom = 140 + view.bounds.height * 0.45
        let panelHeight = view.bounds.height - canvasBottom - 50  // Leave 50px bottom margin
        
        controlPanel.frame = CGRect(
            x: 20,
            y: canvasBottom + 20,
            width: view.bounds.width - 40,
            height: panelHeight
        )
        controlPanel.delegate = self
        view.addSubview(controlPanel)
    }
    
    private func setupFPSLabel() {
        fpsLabel = UILabel()
        fpsLabel.text = "60 FPS"
        fpsLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        fpsLabel.textColor = UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1.0) // #22D3EE Cyan
        fpsLabel.backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 0.9) // Dark slate
        fpsLabel.textAlignment = .center
        fpsLabel.layer.cornerRadius = 12
        fpsLabel.layer.borderWidth = 1
        fpsLabel.layer.borderColor = UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 0.5).cgColor // #22D3EE Cyan border
        fpsLabel.clipsToBounds = true
        fpsLabel.frame = CGRect(x: view.bounds.width - 80, y: 105, width: 60, height: 22) // Below title, right side
        view.addSubview(fpsLabel)
    }
    
    // MARK: - Animation Loop
    
    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = 60 // Target 60 FPS
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateFrame(displayLink: CADisplayLink) {
        // Calculate FPS
        frameCount += 1
        let currentTime = displayLink.timestamp
        let deltaTime = currentTime - lastFrameTime
        
        if deltaTime >= 1.0 {
            let fps = Double(frameCount) / deltaTime
            fpsLabel.text = String(format: "%.0f FPS", fps)
            frameCount = 0
            lastFrameTime = currentTime
        }
        
        // Update physics
        bezierCanvas.bezierChain?.update(config: config)
        
        // Trigger redraw
        bezierCanvas.setNeedsDisplay()
    }
    
    // MARK: - ControlPanelDelegate
    
    func didUpdateSpringStiffness(_ value: CGFloat) {
        config.springStiffness = value
        bezierCanvas.config.springStiffness = value
    }
    
    func didUpdateDamping(_ value: CGFloat) {
        config.damping = value
        bezierCanvas.config.damping = value
    }
    
    func didToggleTangents(_ show: Bool) {
        config.showTangents = show
        bezierCanvas.config.showTangents = show
        bezierCanvas.setNeedsDisplay()
    }
    
    func didToggleControlPoints(_ show: Bool) {
        config.showControlPoints = show
        bezierCanvas.config.showControlPoints = show
        bezierCanvas.setNeedsDisplay()
    }
    
    func didTogglePhysics(_ enabled: Bool) {
        config.enablePhysics = enabled
        bezierCanvas.config.enablePhysics = enabled
    }
    
    func didTapReset() {
        // Reset configuration to defaults
        config = PhysicsConfig.default
        bezierCanvas.config = config
        
        // Reinitialize chain
        bezierCanvas.initializeChain()
        bezierCanvas.setNeedsDisplay()
    }
    
    func didSelectPreset(_ preset: String) {
        switch preset {
        case "Bouncy":
            config.springStiffness = 0.08
            config.damping = 0.75
        case "Smooth":
            config.springStiffness = 0.15
            config.damping = 0.90
        case "Stiff":
            config.springStiffness = 0.35
            config.damping = 0.95
        case "Fluid":
            config.springStiffness = 0.05
            config.damping = 0.80
        default:
            break
        }
        
        bezierCanvas.config = config
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
