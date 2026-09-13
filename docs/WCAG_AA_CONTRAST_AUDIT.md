# WCAG AA Contrast Ratio Audit Report

**Date**: 2026-03-28
**Standard**: WCAG 2.1 Level AA
**Requirement**:
- Normal text: 4.5:1 minimum
- Large text (18pt+ or 14pt+ bold): 3:1 minimum

---

## Color Reference

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| Primary Dark Green | #1B5E20 | (27, 94, 32) | Buttons, AppBar, links |
| Primary Light Green | #81C784 | (129, 199, 132) | Dark mode accents |
| Secondary Green | #8BC34A | (139, 195, 74) | Accent color |
| On Secondary (Black) | #000000 | (0, 0, 0) | Text on secondary |
| Surface (White) | #FFFFFF | (255, 255, 255) | Card backgrounds |
| On Surface (Near-black) | #0A0A0A | (10, 10, 10) | Primary text |
| On Surface Variant | #37434F | (55, 67, 79) | Secondary text/hints |
| Error Red | #D32F2F | (211, 47, 47) | Error states |
| On Error (White) | #FFFFFF | (255, 255, 255) | Error text |

---

## Contrast Ratio Analysis

### 1. PRIMARY COLOR COMBINATIONS ✓

#### #1B5E20 (Dark Green) + White Text
- **Location**: AppBar title, FilledButton text, primary CTA
- **Relative Luminance**: #1B5E20 = 0.076, White = 1.0
- **Contrast Ratio**: (1.0 + 0.05) / (0.076 + 0.05) = **8.3:1**
- **Status**: ✓ PASS (exceeds 4.5:1)

#### #81C784 (Light Green) + Dark Text (Dark Mode)
- **Location**: Dark mode primary buttons, accents
- **Relative Luminance**: #81C784 = 0.458, Black = 0.0
- **Contrast Ratio**: (0.458 + 0.05) / (0.0 + 0.05) = **10.2:1**
- **Status**: ✓ PASS (exceeds 4.5:1)

---

### 2. TEXT COLOR COMBINATIONS ✓

#### #0A0A0A (Near-black) on White
- **Location**: Primary text on white cards, body text
- **Relative Luminance**: #0A0A0A = 0.0004, White = 1.0
- **Contrast Ratio**: (1.0 + 0.05) / (0.0004 + 0.05) = **21:1**
- **Status**: ✓ PASS (exceeds 4.5:1)

#### #37434F (Slate Gray) on White
- **Location**: Secondary text, hints, labels
- **Relative Luminance**: #37434F = 0.088
- **Contrast Ratio**: (1.0 + 0.05) / (0.088 + 0.05) = **6.5:1**
- **Status**: ✓ PASS (exceeds 4.5:1)

#### #ECEFF1 (Light Gray) on #121212 (Dark Surface - Dark Mode)
- **Location**: Primary text in dark mode
- **Relative Luminance**: #ECEFF1 = 0.917, #121212 = 0.006
- **Contrast Ratio**: (0.917 + 0.05) / (0.006 + 0.05) = **17.7:1**
- **Status**: ✓ PASS (exceeds 4.5:1)

#### #B0BEC5 (Light Gray) on #121212 (Dark Surface - Dark Mode)
- **Location**: Secondary text in dark mode
- **Relative Luminance**: #B0BEC5 = 0.606, #121212 = 0.006
- **Contrast Ratio**: (0.606 + 0.05) / (0.006 + 0.05) = **11.3:1**
- **Status**: ✓ PASS (exceeds 4.5:1)

---

### 3. SECONDARY & ACCENT COLOR COMBINATIONS ✓

#### #8BC34A (Light Green) + Black Text
- **Location**: Secondary buttons, chips
- **Relative Luminance**: #8BC34A = 0.431, Black = 0.0
- **Contrast Ratio**: (0.431 + 0.05) / (0.0 + 0.05) = **9.6:1**
- **Status**: ✓ PASS (exceeds 4.5:1 for normal text, 3:1 for large)

#### #8BC34A (Light Green) + White Text
- **Relative Luminance**: #8BC34A = 0.431, White = 1.0
- **Contrast Ratio**: (1.0 + 0.05) / (0.431 + 0.05) = **2.2:1**
- **Status**: ✗ FAIL (below 3:1) - **AVOID THIS COMBINATION**

---

### 4. ERROR STATE COMBINATIONS ✓

#### #D32F2F (Error Red) + White Text
- **Location**: Error messages, error buttons
- **Relative Luminance**: #D32F2F = 0.178, White = 1.0
- **Contrast Ratio**: (1.0 + 0.05) / (0.178 + 0.05) = **4.7:1**
- **Status**: ✓ PASS (meets 4.5:1 minimum)

#### #D32F2F (Error Red) + Black Text
- **Location**: Error status indicators
- **Relative Luminance**: #D32F2F = 0.178, Black = 0.0
- **Contrast Ratio**: (0.178 + 0.05) / (0.0 + 0.05) = **4.6:1**
- **Status**: ✓ PASS (meets 4.5:1 minimum)

---

### 5. DISABLED STATE COLORS

#### Recommended Disabled Color: #BDBDBD (Gray)
- **Relative Luminance**: #BDBDBD = 0.522
- **On White**: (1.0 + 0.05) / (0.522 + 0.05) = **1.96:1** (below 4.5:1)
- **Status**: ⚠ ACCEPTABLE for disabled states (visual distinction acceptable)

---

## Summary

| Combination | Ratio | Target | Status |
|---|---|---|---|
| #1B5E20 + White | 8.3:1 | 4.5:1 | ✓ PASS |
| #81C784 + Black | 10.2:1 | 4.5:1 | ✓ PASS |
| #0A0A0A + White | 21:1 | 4.5:1 | ✓ PASS |
| #37434F + White | 6.5:1 | 4.5:1 | ✓ PASS |
| #ECEFF1 + #121212 (Dark) | 17.7:1 | 4.5:1 | ✓ PASS |
| #B0BEC5 + #121212 (Dark) | 11.3:1 | 4.5:1 | ✓ PASS |
| #8BC34A + Black | 9.6:1 | 4.5:1 | ✓ PASS |
| #8BC34A + White | 2.2:1 | 3:1 | ✗ FAIL |
| #D32F2F + White | 4.7:1 | 4.5:1 | ✓ PASS |
| #D32F2F + Black | 4.6:1 | 4.5:1 | ✓ PASS |

---

## Recommendations

### ✓ All-Clear Combinations
Use freely without concerns:
1. Dark text (#0A0A0A, #37434F) on white backgrounds
2. White text on dark green (#1B5E20)
3. Dark text on light green (#8BC34A)
4. Light text (#ECEFF1, #B0BEC5) on dark surfaces

### ⚠ Avoid
**#8BC34A (light green) with white text** - falls below 3:1 threshold. Do not use this combination in buttons or text elements.

### ℹ Dark Mode Validation Required
Test actual rendering on device for:
- Dark surface (#121212) with light text (#ECEFF1)
- Dark surface (#121212) with secondary text (#B0BEC5)
- Ensure no color shifts from display settings

---

## Testing Checklist

- [ ] Light theme: verify dark text on white appears crisp
- [ ] Dark theme: verify light text on dark surface is readable
- [ ] Error messages: confirm #D32F2F + white text passes visual inspection
- [ ] Disabled buttons: confirm visual distinction from enabled buttons
- [ ] Printed: verify contrast still meets WCAG AA when printed in grayscale

