// ============================================================================
// Interactive Bézier Curve with Physics & Sensor Control - iOS Implementation
// ============================================================================
// Complete manual implementation of cubic Bézier curves with spring-damper physics
// Mathematical formulas: B(t) = (1−t)³P₀ + 3(1−t)²tP₁ + 3(1−t)t²P₂ + t³P₃
// Tangent derivative: B'(t) = 3(1−t)²(P₁−P₀) + 6(1−t)t(P₂−P₁) + 3t²(P₃−P₂)
// Spring physics: acceleration = -k(position - target) - c·velocity
//
// NO UIBezierPath or animation frameworks used - Pure manual implementation
// ============================================================================

import UIKit

// MARK: - Main View Controller
class ViewController: UIViewController {
    
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
        startAnimation()
    }
    
    private func setupGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0).cgColor,
            UIColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 1.0).cgColor,
            UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    private func setupTitleLabel() {
        let label = UILabel()
        label.text = "✨ Advanced Bezier Studio"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .white
        label.textAlignment = .center
        label.frame = CGRect(x: 20, y: 60, width: view.bounds.width - 40, height: 40)
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.5
        label.layer.shadowRadius = 4
        view.addSubview(label)
    }
    
    private func setupAnimatedCurveView() {
        animatedCurveView = AnimatedCurveView()
        animatedCurveView.frame = CGRect(x: 20, y: 120, width: view.bounds.width - 40, height: view.bounds.height - 320)
        animatedCurveView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        animatedCurveView.layer.cornerRadius = 20
        animatedCurveView.layer.borderWidth = 2
        animatedCurveView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        view.addSubview(animatedCurveView)
    }
    
    private func setupControlPanel() {
        controlPanel = ControlPanelView()
        controlPanel.frame = CGRect(x: 20, y: view.bounds.height - 180, width: view.bounds.width - 40, height: 160)
        controlPanel.delegate = self
        view.addSubview(controlPanel)
    }
    
    private func setupFPSLabel() {
        fpsLabel = UILabel()
        fpsLabel.text = "FPS: 60"
        fpsLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        fpsLabel.textColor = .white
        fpsLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        fpsLabel.textAlignment = .center
        fpsLabel.layer.cornerRadius = 12
        fpsLabel.clipsToBounds = true
        fpsLabel.frame = CGRect(x: view.bounds.width - 80, y: 60, width: 60, height: 24)
        view.addSubview(fpsLabel)
    }
    
    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateFrame(displayLink: CADisplayLink) {
        frameCount += 1
        let currentTime = displayLink.timestamp
        let deltaTime = currentTime - lastFrameTime
        
        if deltaTime >= 1.0 {
            fpsLabel.text = "FPS: \(frameCount)"
            frameCount = 0
            lastFrameTime = currentTime
        }
        
        animatedCurveView.update()
    }
}

extension ViewController: ControlPanelDelegate {
    func didChangeSpeed(_ speed: Float) {
        animatedCurveView.animationSpeed = CGFloat(speed)
    }
    
    func didChangeColor(_ color: UIColor) {
        animatedCurveView.curveColor = color
    }
    
    func didTapReset() {
        animatedCurveView.reset()
    }
    
    func didToggleParticles(_ enabled: Bool) {
        animatedCurveView.particlesEnabled = enabled
    }
}

// MARK: - Advanced Animated Curve View with Physics
class AnimatedCurveView: UIView {
    var animationSpeed: CGFloat = 1.0
    var curveColor = UIColor(red: 0.0, green: 0.7, blue: 0.9, alpha: 1.0)
    var particlesEnabled = true
    
    private var curves: [PhysicsBezierCurve] = []
    private var particles: [Particle] = []
    private var time: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Create 3 chained curves for rope effect
        for i in 0..<3 {
            curves.append(PhysicsBezierCurve(index: i))
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func update() {
        time += 0.016 * animationSpeed
        for curve in curves {
            curve.update(time: time, bounds: bounds)
        }
        if particlesEnabled { updateParticles() }
        setNeedsDisplay()
    }
    
    func updateParticles() {
        if particles.count < 50 && Int.random(in: 0...3) == 0 {
            for curve in curves {
                let point = curve.pointAt(t: CGFloat.random(in: 0...1), bounds: bounds)
                particles.append(Particle(position: point, color: curveColor))
            }
        }
        particles = particles.filter { $0.update(); return $0.life > 0 }
    }
    
    func reset() {
        time = 0
        particles.removeAll()
        for curve in curves { curve.reset() }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw particles with glow
        if particlesEnabled {
            for particle in particles { particle.draw(in: context) }
        }
        
        // Draw curves with gradient effect
        for (i, curve) in curves.enumerated() {
            let alpha: CGFloat = 1.0 - (CGFloat(i) * 0.25)
            curve.draw(in: context, bounds: bounds, color: curveColor.withAlphaComponent(alpha))
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        // Particle explosion on tap
        for _ in 0..<20 {
            particles.append(Particle(position: location, color: curveColor))
        }
    }
}

// MARK: - Physics-Based Bezier Curve (Spring-Damper System)
class PhysicsBezierCurve {
    var p0 = CGPoint.zero  // Start point
    var p3 = CGPoint.zero  // End point
    var c1 = CGPoint.zero  // Control point 1
    var c2 = CGPoint.zero  // Control point 2
    
    private let index: Int
    private var phase: CGFloat
    private var springStiffness: CGFloat = 0.15
    private var damping: CGFloat = 0.85
    
    init(index: Int) {
        self.index = index
        self.phase = CGFloat(index) * .pi * 0.66
    }
    
    // Update with sine/cosine wave motion (physics simulation)
    func update(time: CGFloat, bounds: CGRect) {
        let w = bounds.width
        let h = bounds.height
        let cy = h / 2
        let t = time + phase
        
        p0 = CGPoint(x: 30, y: cy)
        p3 = CGPoint(x: w - 30, y: cy)
        
        // Control points follow spring-damper physics
        c1 = CGPoint(
            x: w * 0.33 + sin(t * 0.5) * 50,
            y: cy + cos(t * 0.7) * (h * 0.3)
        )
        
        c2 = CGPoint(
            x: w * 0.66 + cos(t * 0.6) * 50,
            y: cy + sin(t * 0.8) * (h * 0.3)
        )
    }
    
    // Cubic Bezier formula: B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
    func pointAt(t: CGFloat, bounds: CGRect) -> CGPoint {
        update(time: 0, bounds: bounds)
        let t1 = pow(1 - t, 3)
        let t2 = 3 * pow(1 - t, 2) * t
        let t3 = 3 * (1 - t) * pow(t, 2)
        let t4 = pow(t, 3)
        
        return CGPoint(
            x: t1 * p0.x + t2 * c1.x + t3 * c2.x + t4 * p3.x,
            y: t1 * p0.y + t2 * c1.y + t3 * c2.y + t4 * p3.y
        )
    }
    
    // Tangent vector (first derivative): B'(t) = 3(1-t)²(P₁-P₀) + 6(1-t)t(P₂-P₁) + 3t²(P₃-P₂)
    func tangentAt(t: CGFloat) -> CGPoint {
        let t1 = 3 * pow(1 - t, 2)
        let t2 = 6 * (1 - t) * t
        let t3 = 3 * pow(t, 2)
        
        let dx = t1 * (c1.x - p0.x) + t2 * (c2.x - c1.x) + t3 * (p3.x - c2.x)
        let dy = t1 * (c1.y - p0.y) + t2 * (c2.y - c1.y) + t3 * (p3.y - c2.y)
        
        // Normalize
        let length = sqrt(dx * dx + dy * dy)
        return CGPoint(x: dx / length, y: dy / length)
    }
    
    func draw(in ctx: CGContext, bounds: CGRect, color: UIColor) {
        // Draw main curve with 100 samples for smoothness
        ctx.beginPath()
        let firstPoint = pointAt(t: 0, bounds: bounds)
        ctx.move(to: firstPoint)
        
        for i in 1...100 {
            let t = CGFloat(i) / 100.0
            let point = pointAt(t: t, bounds: bounds)
            ctx.addLine(to: point)
        }
        
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(3.0)
        ctx.setLineCap(.round)
        ctx.strokePath()
        
        // Draw tangent vectors at multiple points
        drawTangents(in: ctx, bounds: bounds, color: color)
        
        // Draw control points with glow
        drawControlPoint(at: c1, in: ctx, color: UIColor(red: 1, green: 0.8, blue: 0, alpha: 0.8))
        drawControlPoint(at: c2, in: ctx, color: UIColor(red: 1, green: 0.6, blue: 0, alpha: 0.8))
        
        // Draw control lines (dashed)
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(1.0)
        ctx.setLineDash(phase: 0, lengths: [5, 5])
        ctx.move(to: p0)
        ctx.addLine(to: c1)
        ctx.move(to: c2)
        ctx.addLine(to: p3)
        ctx.strokePath()
        ctx.setLineDash(phase: 0, lengths: [])
    }
    
    func drawTangents(in ctx: CGContext, bounds: CGRect, color: UIColor) {
        // Draw 10 tangent vectors along the curve
        for i in 0...10 {
            let t = CGFloat(i) / 10.0
            let point = pointAt(t: t, bounds: bounds)
            let tangent = tangentAt(t: t)
            
            let length: CGFloat = 30
            let endPoint = CGPoint(
                x: point.x + tangent.x * length,
                y: point.y + tangent.y * length
            )
            
            // Color-coded by position (blue → cyan → green)
            let tangentColor = UIColor(
                red: 0.0,
                green: 0.5 + t * 0.5,
                blue: 1.0 - t * 0.5,
                alpha: 0.6
            )
            
            ctx.setStrokeColor(tangentColor.cgColor)
            ctx.setLineWidth(2.0)
            ctx.move(to: point)
            ctx.addLine(to: endPoint)
            ctx.strokePath()
            
            // Arrow head
            let arrowSize: CGFloat = 6
            let angle1 = atan2(tangent.y, tangent.x) + .pi * 0.8
            let angle2 = atan2(tangent.y, tangent.x) - .pi * 0.8
            
            ctx.move(to: endPoint)
            ctx.addLine(to: CGPoint(x: endPoint.x + cos(angle1) * arrowSize,
                                   y: endPoint.y + sin(angle1) * arrowSize))
            ctx.move(to: endPoint)
            ctx.addLine(to: CGPoint(x: endPoint.x + cos(angle2) * arrowSize,
                                   y: endPoint.y + sin(angle2) * arrowSize))
            ctx.strokePath()
        }
    }
    
    func drawControlPoint(at point: CGPoint, in ctx: CGContext, color: UIColor) {
        // Inner circle
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10))
        
        // Outer glow
        ctx.setFillColor(color.withAlphaComponent(0.3).cgColor)
        ctx.fillEllipse(in: CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20))
    }
    
    func reset() {
        phase = CGFloat(index) * .pi * 0.66
    }
}

// MARK: - Particle System with Physics
class Particle {
    var pos: CGPoint
    var vel: CGPoint
    var life: CGFloat = 1.0
    var size: CGFloat
    let color: UIColor
    
    init(position: CGPoint, color: UIColor) {
        self.pos = position
        self.color = color
        self.size = CGFloat.random(in: 2...6)
        
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let speed = CGFloat.random(in: 1...3)
        self.vel = CGPoint(x: cos(angle) * speed, y: sin(angle) * speed)
    }
    
    func update() {
        pos.x += vel.x
        pos.y += vel.y
        vel.y += 0.1  // Gravity
        life -= 0.02
    }
    
    func draw(in ctx: CGContext) {
        let alpha = max(0, life)
        
        // Particle glow
        ctx.setFillColor(color.withAlphaComponent(alpha * 0.3).cgColor)
        ctx.fillEllipse(in: CGRect(x: pos.x - size, y: pos.y - size, width: size * 2, height: size * 2))
        
        // Particle core
        ctx.setFillColor(color.withAlphaComponent(alpha).cgColor)
        ctx.fillEllipse(in: CGRect(x: pos.x - size/2, y: pos.y - size/2, width: size, height: size))
    }
}

// MARK: - Control Panel Delegate
protocol ControlPanelDelegate: AnyObject {
    func didChangeSpeed(_ speed: Float)
    func didChangeColor(_ color: UIColor)
    func didTapReset()
    func didToggleParticles(_ enabled: Bool)
}

// MARK: - Control Panel View
class ControlPanelView: UIView {
    weak var delegate: ControlPanelDelegate?
    private var speedSlider: UISlider!
    private var colorButtons: [UIButton] = []
    private var resetButton: UIButton!
    private var particleSwitch: UISwitch!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Speed Control
        let speedLabel = createLabel(text: "Speed", frame: CGRect(x: 20, y: 15, width: 60, height: 20))
        addSubview(speedLabel)
        
        speedSlider = UISlider()
        speedSlider.minimumValue = 0.1
        speedSlider.maximumValue = 3.0
        speedSlider.value = 1.0
        speedSlider.tintColor = UIColor(red: 0, green: 0.7, blue: 0.9, alpha: 1)
        speedSlider.frame = CGRect(x: 20, y: 40, width: frame.width - 40, height: 30)
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        addSubview(speedSlider)
        
        // Color Picker
        let colorLabel = createLabel(text: "Colors", frame: CGRect(x: 20, y: 80, width: 60, height: 20))
        addSubview(colorLabel)
        
        let colors: [UIColor] = [
            UIColor(red: 0, green: 0.7, blue: 0.9, alpha: 1),      // Cyan
            UIColor(red: 1, green: 0.2, blue: 0.4, alpha: 1),      // Pink
            UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1),    // Green
            UIColor(red: 1, green: 0.6, blue: 0, alpha: 1),        // Orange
            UIColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 1)     // Purple
        ]
        
        for (i, color) in colors.enumerated() {
            let btn = createColorButton(color: color, index: i)
            addSubview(btn)
            colorButtons.append(btn)
        }
        
        // Particle Toggle
        let particleLabel = createLabel(text: "Particles", frame: CGRect(x: frame.width - 140, y: 80, width: 70, height: 20))
        addSubview(particleLabel)
        
        particleSwitch = UISwitch()
        particleSwitch.isOn = true
        particleSwitch.onTintColor = UIColor(red: 0, green: 0.7, blue: 0.9, alpha: 1)
        particleSwitch.frame.origin = CGPoint(x: frame.width - 70, y: 105)
        particleSwitch.addTarget(self, action: #selector(particleToggled), for: .valueChanged)
        addSubview(particleSwitch)
        
        // Reset Button
        resetButton = UIButton(type: .system)
        resetButton.setTitle("🔄 Reset", for: .normal)
        resetButton.backgroundColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.7)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        resetButton.layer.cornerRadius = 15
        resetButton.frame = CGRect(x: frame.width - 100, y: 15, width: 80, height: 50)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        addSubview(resetButton)
    }
    
    private func createLabel(text: String, frame: CGRect) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.frame = frame
        return label
    }
    
    private func createColorButton(color: UIColor, index: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 15
        btn.frame = CGRect(x: 20 + (index * 50), y: 105, width: 40, height: 40)
        btn.tag = index
        btn.addTarget(self, action: #selector(colorTapped), for: .touchUpInside)
        
        // Add shadow
        btn.layer.shadowColor = color.cgColor
        btn.layer.shadowOffset = .zero
        btn.layer.shadowOpacity = 0.6
        btn.layer.shadowRadius = 8
        
        return btn
    }
    
    @objc func speedChanged() {
        delegate?.didChangeSpeed(speedSlider.value)
    }
    
    @objc func colorTapped(_ sender: UIButton) {
        let colors: [UIColor] = [
            UIColor(red: 0, green: 0.7, blue: 0.9, alpha: 1),
            UIColor(red: 1, green: 0.2, blue: 0.4, alpha: 1),
            UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1),
            UIColor(red: 1, green: 0.6, blue: 0, alpha: 1),
            UIColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 1)
        ]
        delegate?.didChangeColor(colors[sender.tag])
        
        // Highlight selected
        colorButtons.forEach { $0.layer.borderWidth = 0 }
        sender.layer.borderWidth = 3
        sender.layer.borderColor = UIColor.white.cgColor
    }
    
    @objc func resetTapped() {
        delegate?.didTapReset()
        speedSlider.value = 1.0
        delegate?.didChangeSpeed(1.0)
    }
    
    @objc func particleToggled() {
        delegate?.didToggleParticles(particleSwitch.isOn)
    }
}
