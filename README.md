# Interactive Bézier Curve Physics Simulator

**Real-time cubic Bézier curves with spring-damper physics, manual mathematical implementation, and interactive controls.**

---


### Web Version 
```bash
cd /Users/dhruvsharma/Downloads/flam/web
open index.html
```
Or just **double-click** `index.html` — that's it!

### iOS Version 
```bash
cd /Users/dhruvsharma/Downloads/flam/ios
open SimpleBezierApp.xcodeproj
```

---

## The Mathematics

### 1. Cubic Bézier Curve Formula

I implemented the parametric cubic Bézier equation:

```
B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
```

Where **t ∈ [0, 1]** is the curve parameter, and:
- **P₀** = Fixed start point
- **P₁** = First control point (dynamic, responds to input)
- **P₂** = Second control point (dynamic, responds to input)  
- **P₃** = Fixed end point

The curve is sampled at **100 points** (t = 0.00, 0.01, ..., 1.00) for smooth rendering.

### 2. Tangent Vectors (First Derivative)

Tangents show the **instantaneous direction** at any point. I computed them using analytical derivatives:

```
B'(t) = 3(1-t)²(P₁-P₀) + 6(1-t)t(P₂-P₁) + 3t²(P₃-P₂)
```

These tangents are:
- **Normalized** to unit vectors for consistent visual length
- Displayed as **color-coded arrows** (10 per curve)
- Calculated using **analytical calculus**, not numerical approximation



---

## The Physics Model

I chose a **spring-mass-damper system** for natural, organic motion instead of direct position tracking.

### The Equations

Each control point follows these physics equations every frame:

```
1. Spring Force:      Fs = -k · (position - target)    [Hooke's Law]
2. Damping Force:     Fd = -c · velocity               [Resistance]
3. Total Force:       F = Fs + Fd
4. Acceleration:      a = F / mass                     [mass = 1]
5. Update Velocity:   v(t+Δt) = v(t) + a·Δt           [Euler integration]
6. Update Position:   p(t+Δt) = p(t) + v·Δt
```

### Parameters

- **k = 0.15** (spring stiffness): How strongly it pulls toward target
  - Lower = loose, floppy motion
  - Higher = tight, rigid response
  
- **c = 0.85** (damping): How much it resists motion
  - Lower = bouncy, oscillates
  - Higher = smooth, no overshoot

### Why Not Direct Tracking?

I could have simply set `position = mousePosition`, but that would:
- ❌ Feel robotic and instant (no natural motion)
- ❌ Lack momentum and overshoot
- ❌ Miss the educational value of physics simulation

Spring-damper gives:
- ✅ **Natural, organic motion** (feels like a real rope)
- ✅ **Smooth transitions** with momentum
- ✅ **Realistic overshoot** and settling behavior
- ✅ **More visually appealing** dynamics

---

## Key Design Choices

### 1. Analytical Derivatives vs Numerical Approximation

**I chose analytical derivatives** for tangent computation:

```
✅ B'(t) = 3(1-t)²(P₁-P₀) + 6(1-t)t(P₂-P₁) + 3t²(P₃-P₂)
```

Instead of numerical approximation:
```
❌ tangent ≈ (B(t+ε) - B(t-ε)) / 2ε
```

**Why?**
- More accurate (exact derivative)
- Better performance (no epsilon calculations)
- Cleaner mathematics (explicit formula)
- Educational value (demonstrates calculus)
- No numerical instability

### 2. Multiple Curve Segments (Chaining)

I chain **3 connected Bézier curves** instead of using a single curve:

```
Curve 1: P₀──P₁──P₂──P₃
                       │ (shared point)
Curve 2:              P₀──P₁──P₂──P₃
                                   │
Curve 3:                          P₀──P₁──P₂──P₃
```

**Why?**
- Creates realistic **rope/ribbon effect**
- Allows more **complex shapes** than single curve
- Demonstrates **curve continuity** concepts
- More visually interesting **wave patterns**

**Why?**
- Shows curve **flow direction** visually
- Helps understand **parametric nature** (t parameter)
- Makes derivative concept more **intuitive**
- Aesthetically pleasing
- Educational visualization

---

## Implementation Summary

### Both Platforms Feature

| Component | Description |
|-----------|-------------|
| **Vector2D** | 2D vector math (add, subtract, multiply, normalize) |
| **PhysicsPoint** | Control point with spring-damper physics |
| **CubicBezier** | Single curve segment (manual B(t) formula) |
| **BezierChain** | 3 connected curves for rope effect |
| **Renderer** | Canvas 2D (web) / Core Graphics (iOS) |
| **Controls** | Real-time parameter adjustment |

### Web Version
- Pure vanilla JavaScript (no libraries)
- HTML5 Canvas 2D API
- requestAnimationFrame for 60 FPS
- Mouse + touch + keyboard input

### iOS Version  
- Native Swift + UIKit
- Core Graphics (NO UIBezierPath)
- CADisplayLink for 60 FPS
- Touch input with gesture handling

---

## Performance

**Target:** 60 FPS (16.67ms per frame)  
**Actual:** 60 FPS on both platforms consistently

**Per Frame:**
- 12 physics updates (3 curves × 4 points)
- 300 curve samples (3 curves × 100 points)
- 30 tangent vectors (3 curves × 10 tangents)

**Optimizations:**
- Pre-calculate powers (t², t³) instead of Math.pow()
- Single stroke() call per curve (not per segment)
- Conditional rendering (only draw enabled features)

---

**Both implementations:**
- ✅ Zero external dependencies
- ✅ Manual Bézier mathematics
- ✅ Manual tangent derivatives
- ✅ Manual spring-damper physics
- ✅ 60 FPS real-time rendering

---

## Controls

**Web:** Mouse move, keyboard shortcuts (T/C/P/R/1-4), sliders  
**iOS:** Touch drag, sliders, switches, color buttons, reset

**Both support:** Real-time spring/damping adjustment, tangent toggle, physics presets

---


## What I Learned

This project demonstrates:
- **Parametric curves** — Bézier mathematics from scratch
- **Calculus** — Computing derivatives analytically
- **Physics simulation** — Spring-damper differential equations
- **Real-time graphics** — 60 FPS animation loops
- **Code architecture** — Clean separation of concerns
- **Cross-platform development** — Web + iOS implementations

---

**Created by:** Dhruv Sharma  
**December 2025**
# B-zier-curve
