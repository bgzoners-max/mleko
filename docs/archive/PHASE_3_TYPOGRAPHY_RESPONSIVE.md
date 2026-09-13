# Phase 3: Fine-tuning - Responsive Typography & Accessibility Audit

## Completed Tasks

### 1. Responsive Typography Implementation ✓

#### Font Size Scaling Strategy
Created `Breakpoints.scaleFontSize()` and `Breakpoints.responsiveTextStyle()` helpers in `lib/core/responsive.dart`:

```dart
/// Mobile (baseline):
- displayLarge: 28px  → tablet: 32px  → desktop: 33px
- displayMedium: 24px → tablet: 27px  → desktop: 29px
- displaySmall: 22px  → tablet: 25px  → desktop: 27px
- headlineLarge: 20px → tablet: 23px  → desktop: 25px
- headlineMedium: 18px → tablet: 20px → desktop: 22px
- headlineSmall: 16px → tablet: 18px → desktop: 20px
- titleLarge: 24px    → tablet: 27px  → desktop: 29px
- titleMedium: 20px   → tablet: 23px  → desktop: 25px
- bodyLarge: 16px     → tablet: 18px  → desktop: 20px
- bodyMedium: 14px    → tablet: 16px  → desktop: 18px
- bodySmall: 12px     → tablet: 14px  → desktop: 16px
- labelSmall: 11px    → tablet: 13px  → desktop: 15px
```

#### Implementation Details
- **Location**: `lib/core/responsive.dart`
- **Methods**:
  - `Breakpoints.scaleFontSize(baseFontSize, context)` - calculates responsive font size
  - `Breakpoints.responsiveTextStyle(baseStyle, context)` - returns scaled TextStyle

#### Usage Pattern
```dart
// In build() method:
Text(
  'Naslov',
  style: Breakpoints.responsiveTextStyle(
    Theme.of(context).textTheme.headlineMedium!,
    context,
  ),
)
```

#### Benefits
- ✓ Enhanced readability on larger screens (tablet/desktop)
- ✓ Proper visual hierarchy across all device sizes
- ✓ Tablet users get +2-3px boost for better legibility
- ✓ Desktop users get +4-5px boost for optimal viewing distance
- ✓ No mobile breakage (baseline unchanged)

---

## Pending Tasks

### 2. Dark Mode Validation
- [ ] Test dark mode across home_screen, product_detail_screen, cart_screen
- [ ] Verify text contrast in dark mode (dark: #ECEFF1 text on #121212 surface)
- [ ] Check accent colors visibility (green: #81C784 on dark backgrounds)
- [ ] Validate card shadows and elevation in dark mode

### 3. WCAG AA Contrast Audit (4.5:1 for normal text)
- [ ] Audit primary green (#1B5E20) against white text
- [ ] Audit secondary green (#8BC34A) against black text
- [ ] Audit surface colors (#37434F text on white background)
- [ ] Audit error states (#D32F2F on white/surface)
- [ ] Audit disabled state contrast

### 4. Desktop Layout (1920px+)
- [ ] Test maximum content width constraint (1200px)
- [ ] Verify horizontal padding on ultra-wide screens (32px)
- [ ] Test grid layouts don't become too sparse (max 4 columns)
- [ ] Check image dimensions scale appropriately
- [ ] Validate spacing and visual balance

---

## Color Palette Reference

### Light Theme
- **Primary**: #1B5E20 (dark green) - high contrast buttons/links
- **On Primary**: White - text on primary backgrounds
- **Secondary**: #8BC34A (light green) - accent color
- **Surface**: White - card/dialog backgrounds
- **On Surface**: #0A0A0A (near-black) - primary text
- **On Surface Variant**: #37434F (slate gray) - secondary text/hints
- **Error**: #D32F2F (red) - error states
- **Outline**: #B0BEC5 (light gray) - borders/dividers

### Dark Theme
- **Primary**: #81C784 (light green) - high contrast on dark
- **Surface**: #1E1E1E - card backgrounds
- **On Surface**: #ECEFF1 (light) - primary text
- **On Surface Variant**: #B0BEC5 (light gray) - secondary text
