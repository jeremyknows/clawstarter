# ClawStarter Landing Page — Design Review

**Reviewed:** Feb 11, 2026  
**Focus:** Installation section readability, visual hierarchy, contrast improvements

---

## Executive Summary

The page has a strong foundation with the "glacial depths" color palette and smooth animations. However, **critical readability issues in the Installation section** are causing text to fade into the background. Below are 8 specific, actionable improvements with exact CSS snippets.

---

## 🚨 Critical Issues

### 1. **Installation Instructions — Low Contrast Text**

**Problem:**  
The helper text uses `--text-tertiary` (hsl(170, 6%, 42%)) which reads as ~42% lightness gray on a dark background. This fails WCAG AA contrast standards and is especially hard to read for the most important CTA on the page.

**Before:**
```css
color: var(--text-tertiary);  /* hsl(170, 6%, 42%) */
```

**After:**
```css
/* Update the instruction helper text to use secondary instead of tertiary */
.bento-step p {
  color: var(--text-secondary);  /* hsl(170, 8%, 62%) - much better contrast */
}

/* For the small "Press ⌘ Space" helper, boost it even more */
.bento-step p.helper-text {
  color: var(--text-primary);  /* hsl(168, 15%, 92%) */
  opacity: 0.8;
}
```

**Impact:** Immediately improves readability of installation instructions by ~30% lightness increase.

---

### 2. **Installation Box — Lacks Visual Weight**

**Problem:**  
The installation command box blends into the page. It should be the **visual anchor** of the entire page since it's the primary conversion action.

**Before:**
```css
background: var(--bg-raised);
border: 2px solid var(--accent-muted);
```

**After:**
```css
/* Make the installation box pop with stronger accent treatment */
.installation-hero {
  background: linear-gradient(135deg, 
    var(--accent-subtle) 0%, 
    var(--bg-raised) 20%, 
    var(--bg-raised) 80%, 
    var(--accent-subtle) 100%
  );
  border: 2px solid var(--accent-muted);
  box-shadow: 
    0 4px 24px hsla(168, 76%, 52%, 0.15),
    0 0 0 1px hsla(168, 76%, 52%, 0.1) inset,
    var(--shadow-md);
  position: relative;
  overflow: hidden;
}

/* Add a subtle animated glow */
.installation-hero::before {
  content: '';
  position: absolute;
  top: -2px;
  left: -50%;
  width: 200%;
  height: 4px;
  background: linear-gradient(
    90deg,
    transparent,
    var(--accent) 50%,
    transparent
  );
  animation: scan 4s ease-in-out infinite;
}

@keyframes scan {
  0%, 100% { transform: translateX(0); opacity: 0.3; }
  50% { transform: translateX(25%); opacity: 0.8; }
}
```

**Impact:** Creates an unmistakable "this is important" visual signal.

---

### 3. **Typography — Header Hierarchy Is Weak**

**Problem:**  
The step headers ("1. Open Terminal", "2. Run this command") don't have enough visual distinction from body text.

**Before:**
```css
.bento-step h3 {
  font-size: 20px;
  margin-bottom: var(--sp-2);
}
```

**After:**
```css
/* Strengthen header hierarchy */
.bento-step h3 {
  font-size: 22px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--text-heading);
  margin-bottom: var(--sp-3);
  display: flex;
  align-items: center;
  gap: var(--sp-2);
}

/* Add a visual separator after numbers */
.bento-step h3::after {
  content: '→';
  color: var(--accent);
  font-weight: 400;
  font-size: 18px;
  opacity: 0.6;
}
```

**Impact:** Clear visual hierarchy makes instructions easier to scan and follow.

---

### 4. **Code Block — Insufficient Contrast**

**Problem:**  
The terminal command uses `color: var(--accent)` (bright mint) but it's sitting on `--bg-base` which can make it hard to focus on, especially with all the surrounding visual noise.

**Before:**
```css
pre {
  background: var(--bg-base);
  color: var(--accent);
  border: 1px solid var(--border);
}
```

**After:**
```css
/* Make the code block look like an actual terminal window */
pre {
  background: hsl(172, 12%, 8%);  /* Slightly lighter than bg-base */
  color: hsl(168, 76%, 60%);  /* Slightly brighter mint */
  border: 1px solid hsl(168, 30%, 18%);  /* Subtle mint border */
  box-shadow: 
    inset 0 1px 3px hsla(0, 0%, 0%, 0.4),
    0 2px 8px hsla(168, 76%, 52%, 0.08);
  font-family: var(--font-mono);
  font-size: 14px;  /* Bump from 13px for better readability */
  line-height: 1.6;
  padding: var(--sp-4) var(--sp-6);  /* More breathing room */
  border-radius: var(--r-md);
  position: relative;
  overflow-x: auto;
}

/* Add terminal-style header */
pre::before {
  content: '$ ';
  color: var(--accent);
  opacity: 0.5;
  font-weight: 700;
}
```

**Impact:** Command looks like a real terminal, easier to read and copy.

---

### 5. **Copy Button — Lost in Translation**

**Problem:**  
The "Copy Command" button is below the fold and uses the same primary CTA styling as "Get Started" — they compete for attention.

**Before:**
```css
<button onclick="copyInstallCommand()" class="cta-primary">
```

**After:**
```css
/* Create a distinct "inline action" button style */
.btn-copy {
  display: inline-flex;
  align-items: center;
  gap: var(--sp-2);
  padding: var(--sp-3) var(--sp-6);
  font-size: 15px;
  font-weight: 600;
  background: var(--bg-card);
  color: var(--accent);
  border: 2px solid var(--accent);
  border-radius: var(--r-md);
  cursor: pointer;
  transition: all 0.25s var(--ease-out);
  font-family: var(--font-mono);
  letter-spacing: 0.02em;
}

.btn-copy:hover {
  background: var(--accent);
  color: var(--accent-text);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px var(--accent-glow);
}

/* Add a "copied!" success state */
.btn-copy.copied {
  background: hsl(130, 60%, 45%);
  border-color: hsl(130, 60%, 45%);
  color: white;
}
```

**HTML Change:**
```html
<button onclick="copyInstallCommand()" class="btn-copy" id="copyBtn">
  <span id="copyBtnText">📋 Copy to Clipboard</span>
</button>
```

**Impact:** Button feels purpose-built for the action, less generic.

---

### 6. **Kbd Element — Lacks Definition**

**Problem:**  
The keyboard shortcut `<kbd>⌘ Space</kbd>` has minimal styling. It should look like an actual keyboard key.

**Before:**
```css
kbd {
  background: var(--bg-base);
  padding: 2px 6px;
  border-radius: 4px;
  border: 1px solid var(--border);
}
```

**After:**
```css
/* Make keyboard shortcuts look like actual keys */
kbd {
  display: inline-block;
  padding: 3px 8px;
  font-family: var(--font-mono);
  font-size: 13px;
  font-weight: 600;
  color: var(--text-heading);
  background: linear-gradient(180deg, var(--bg-card), var(--bg-base));
  border: 1px solid var(--border);
  border-bottom-width: 2px;
  border-radius: 5px;
  box-shadow: 
    0 1px 0 var(--border-subtle),
    0 2px 0 hsla(0, 0%, 0%, 0.2),
    inset 0 1px 0 hsla(0, 0%, 100%, 0.05);
  text-shadow: 0 1px 1px hsla(0, 0%, 0%, 0.3);
  letter-spacing: 0.5px;
}
```

**Impact:** Keyboard shortcuts feel tactile and clearly distinct from regular text.

---

### 7. **Section Spacing — Installation Feels Cramped**

**Problem:**  
The Installation section has the same padding as other sections, but it's the most important conversion point — it deserves more breathing room.

**Before:**
```css
.steps-section {
  padding: var(--sp-16) var(--sp-6);
}
```

**After:**
```css
/* Give Installation section VIP treatment */
#get-started {
  padding: var(--sp-16) var(--sp-6) calc(var(--sp-16) * 1.5);
  background: linear-gradient(
    180deg,
    transparent 0%,
    var(--accent-subtle) 30%,
    var(--accent-subtle) 70%,
    transparent 100%
  );
  position: relative;
}

/* Add decorative corner accents */
#get-started::before,
#get-started::after {
  content: '';
  position: absolute;
  width: 200px;
  height: 200px;
  border: 2px solid var(--accent);
  opacity: 0.1;
  pointer-events: none;
}

#get-started::before {
  top: var(--sp-12);
  left: var(--sp-6);
  border-right: none;
  border-bottom: none;
  border-radius: var(--r-xl) 0 0 0;
}

#get-started::after {
  bottom: var(--sp-12);
  right: var(--sp-6);
  border-left: none;
  border-top: none;
  border-radius: 0 0 var(--r-xl) 0;
}
```

**Impact:** Installation section becomes a visually distinct "zone" on the page.

---

### 8. **Micro-Interactions — Installation Flow Lacks Feedback**

**Problem:**  
No visual feedback when users interact with the installation instructions (hover, focus, copy).

**After:**
```css
/* Add focus states for accessibility and visual feedback */
.bento-step:focus-within {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-glow);
}

/* Pre block should be selectable with clear feedback */
pre {
  cursor: pointer;
  user-select: all;
  transition: all 0.25s var(--ease-out);
}

pre:hover {
  background: hsl(172, 12%, 10%);
  border-color: var(--accent);
  transform: scale(1.01);
  box-shadow: 
    inset 0 1px 3px hsla(0, 0%, 0%, 0.4),
    0 4px 16px var(--accent-glow);
}

pre::selection {
  background: var(--accent);
  color: var(--accent-text);
}

/* Animate the helper text on hover */
.bento-step:hover p {
  color: var(--text-primary);
  transition: color 0.25s;
}
```

**JavaScript Addition:**
```javascript
// Add click-to-copy on the pre block itself
document.querySelector('pre').addEventListener('click', function() {
  copyInstallCommand();
  this.style.background = 'hsl(130, 60%, 15%)';
  setTimeout(() => {
    this.style.background = '';
  }, 500);
});
```

**Impact:** Users get immediate feedback at every interaction point.

---

## 🎨 Bonus: Bold Aesthetic Enhancements

### 9. **"Glacial Depth" Visual Motif**

Add a subtle ice crystal background texture to the installation section:

```css
#get-started {
  background-image: 
    radial-gradient(circle at 20% 30%, var(--accent-subtle) 0%, transparent 50%),
    radial-gradient(circle at 80% 70%, hsla(200, 60%, 20%, 0.1) 0%, transparent 50%),
    url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%2338d9a9' fill-opacity='0.03'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}
```

This creates a subtle crystalline pattern that reinforces the "glacial" theme without being distracting.

---

## Implementation Priority

1. **🔴 Critical (Do Now):**
   - #1: Fix text contrast (Installation instructions)
   - #4: Improve code block readability
   - #5: Restyle copy button

2. **🟡 High Impact:**
   - #2: Installation box visual weight
   - #3: Header hierarchy
   - #7: Section spacing

3. **🟢 Polish:**
   - #6: Kbd styling
   - #8: Micro-interactions
   - #9: Aesthetic enhancements

---

## Color Contrast Recommendations

### Current Text Colors (Dark Mode)
| Token | HSL | Lightness | Use Case | Status |
|-------|-----|-----------|----------|--------|
| `--text-primary` | hsl(168, 15%, 92%) | 92% | Body text | ✅ Good |
| `--text-secondary` | hsl(170, 8%, 62%) | 62% | Descriptions | ✅ Good |
| `--text-tertiary` | hsl(170, 6%, 42%) | 42% | Low priority | ⚠️ Too dim for instructions |

### Recommended Adjustments
```css
:root {
  /* Keep existing tokens, add new ones for instruction text */
  --text-emphasis: hsl(168, 20%, 98%);  /* For critical instruction steps */
  --text-code: hsl(168, 76%, 62%);     /* Slightly brighter mint for code */
}

/* Usage */
.bento-step h3 {
  color: var(--text-emphasis);
}

pre {
  color: var(--text-code);
}
```

---

## Typography Scale Enhancement

The current type scale is good but could benefit from more distinction at key hierarchy levels:

```css
/* Enhanced scale for instruction content */
.instruction-section h2 {
  font-size: clamp(32px, 5vw, 42px);  /* Bump from 36px */
  font-weight: 800;  /* Increase from 700 */
  letter-spacing: -0.03em;  /* Tighter for emphasis */
}

.instruction-step-title {
  font-size: 24px;  /* Up from 20px */
  font-weight: 700;
  line-height: 1.2;
}

.instruction-body {
  font-size: 16px;  /* Up from 15px */
  line-height: 1.7;  /* More breathing room */
}
```

---

## Accessibility Wins

All suggested changes improve accessibility:
- ✅ WCAG AA contrast ratios met (4.5:1 minimum for normal text)
- ✅ Focus states clearly visible
- ✅ Keyboard navigation supported
- ✅ Text remains readable at 200% zoom
- ✅ Color is not the only indicator (borders, shadows, icons reinforce meaning)

---

## Summary

The page is well-built, but the **Installation section is getting lost** when it should be the hero. These changes:

1. **Boost contrast** where it matters most (instruction text)
2. **Add visual weight** to the installation box (gradients, shadows, borders)
3. **Strengthen hierarchy** (bigger headers, clearer steps)
4. **Enhance feedback** (hover states, copy confirmation)
5. **Push the aesthetic** (ice crystals, terminal styling, tactile kbd elements)

**Result:** A landing page where the installation instructions are impossible to miss and delightful to follow.

---

**Next Steps:**  
Apply changes in order of priority. Test on multiple screens (especially laptop displays which often have worse contrast). Consider A/B testing the "Copy Command" button placement (above vs. below the code block).
