# Responsive Design Guidelines for StubStreet

## Overview
This document outlines the responsive design principles and best practices implemented in the StubStreet Flutter application.

## Breakpoints
- **Mobile**: 0 - 767px
- **Tablet**: 768 - 1023px  
- **Desktop**: 1024px+

## Responsive Widgets

### 1. ResponsiveWrapper
Use `ResponsiveWrapper` to create different layouts for different screen sizes:

```dart
ResponsiveWrapper(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
```

### 2. ResponsiveTextFormField
Replaces `AuthTextField` with responsive sizing and accessibility features:

```dart
ResponsiveTextFormField(
  controller: controller,
  labelText: 'Email',
  semanticLabel: 'Email address input field',
  keyboardType: TextInputType.emailAddress,
)
```

### 3. ResponsiveButton
Adaptive button with responsive sizing:

```dart
ResponsiveButton(
  text: 'Login',
  onPressed: onPressed,
  type: ButtonType.elevated,
  semanticLabel: 'Login button',
)
```

### 4. ResponsiveAppBar
App bar that adapts to screen size:

```dart
ResponsiveAppBar(
  title: 'StubStreet',
  actions: [
    ResponsiveIconButton(
      icon: Icons.settings,
      semanticLabel: 'Settings',
      onPressed: onSettings,
    ),
  ],
)
```

### 5. ResponsiveBottomNavigationBar
Navigation that shows as bottom bar on mobile/tablet and side rail on desktop:

```dart
ResponsiveBottomNavigationBar(
  currentIndex: selectedIndex,
  onTap: onTap,
  items: [
    ResponsiveBottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
      semanticLabel: 'Home tab',
    ),
  ],
)
```

## Layout Patterns

### Mobile Layout (Single Column)
- Stack elements vertically
- Use full width for form fields and buttons
- Minimal padding (8-16px)
- List view for content

### Tablet Layout (Responsive Grid)
- Use 2-column grid for content when appropriate
- Increased padding (12-20px)
- Larger touch targets
- Grid view for ticket cards

### Desktop Layout (Multi-Column)
- Use sidebar navigation
- 3-column grid for content
- Maximum padding (24-32px)
- Navigation rail instead of bottom navigation

## Accessibility Features

### Semantic Labels
All interactive widgets include semantic labels:

```dart
Semantics(
  label: 'Ticket: Concert Name, Venue, Date, Price',
  button: true,
  child: TicketCard(...),
)
```

### Focus Management
- Proper tab order
- Focus indicators
- Keyboard navigation support

### Screen Reader Support
- Descriptive labels for all UI elements
- Proper role assignments (button, textfield, etc.)
- Content announcements for state changes

## Theme Consistency

### Material 3 Design
- Uses `useMaterial3: true`
- Consistent color scheme across light/dark themes
- Proper elevation and shadows
- Modern border radius (12-16px)

### Color Scheme
- Primary: Deep Purple
- Generated Material 3 color schemes
- Proper contrast ratios for accessibility

### Typography
- Responsive font sizes
- Consistent text styles
- Proper line heights and spacing

## Asset Management

### Resolution-Aware Images
Assets are organized in resolution-specific folders:
```
assets/
  images/
    logo.png (1x)
    2.0x/
      logo.png (2x)
    3.0x/
      logo.png (3x)
    4.0x/
      logo.png (4x)
```

## Best Practices

### 1. Use Context Extensions
```dart
// Get device type
if (context.isMobile) { ... }
if (context.isTablet) { ... }
if (context.isDesktop) { ... }

// Get screen dimensions
final width = context.screenWidth;
final height = context.screenHeight;
```

### 2. Responsive Spacing
```dart
// Use responsive spacing utility
final spacing = ResponsiveSpacing.getSpacing(
  context,
  mobile: 8.0,
  tablet: 12.0,
  desktop: 16.0,
);
```

### 3. Responsive Padding
```dart
// Use responsive padding
padding: ResponsivePadding.responsive(
  context,
  mobile: 16.0,
  tablet: 20.0,
  desktop: 24.0,
),
```

### 4. LayoutBuilder for Complex Layouts
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 1024) {
      return DesktopLayout();
    } else if (constraints.maxWidth > 768) {
      return TabletLayout();
    }
    return MobileLayout();
  },
)
```

## Testing Guidelines

### Device Testing
- Test on various screen sizes and orientations
- Use Flutter's device preview for testing
- Test with screen readers enabled
- Verify keyboard navigation

### Performance
- Use `const` constructors where possible
- Avoid rebuilding expensive widgets
- Use `ListView.builder` for large lists
- Optimize image loading with `cached_network_image`

### Accessibility Testing
- Enable TalkBack/VoiceOver and test navigation
- Check contrast ratios
- Verify semantic labels
- Test with different font sizes

## Migration from Old Code

### Before (Non-Responsive)
```dart
AuthTextField(
  controller: controller,
  labelText: 'Email',
)
```

### After (Responsive + Accessible)
```dart
ResponsiveTextFormField(
  controller: controller,
  labelText: 'Email',
  semanticLabel: 'Email address input field',
)
```

## Common Patterns

### 1. Responsive Card Layout
```dart
Card(
  margin: EdgeInsets.symmetric(
    vertical: ResponsiveSpacing.getSpacing(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
    horizontal: ResponsiveSpacing.getSpacing(context, mobile: 16.0, tablet: 12.0, desktop: 8.0),
  ),
  child: Padding(
    padding: EdgeInsets.all(context.isDesktop ? 20.0 : (context.isTablet ? 18.0 : 16.0)),
    child: content,
  ),
)
```

### 2. Responsive Icon Sizing
```dart
Icon(
  Icons.star,
  size: context.isDesktop ? 28.0 : (context.isTablet ? 26.0 : 24.0),
)
```

### 3. Responsive Text Sizing
```dart
Text(
  'Title',
  style: TextStyle(
    fontSize: context.isDesktop ? 18.0 : (context.isTablet ? 16.0 : 14.0),
  ),
)
```

This implementation provides a solid foundation for responsive design that adapts to different screen sizes while maintaining accessibility and modern design principles.
