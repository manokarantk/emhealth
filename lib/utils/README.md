# SnackBar Helper

This utility provides a consistent way to show SnackBars above the floating action button throughout the app.

## Usage

### Basic Usage

Instead of using `ScaffoldMessenger.of(context).showSnackBar()` directly, use the helper methods:

```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Success message'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 3),
  ),
);

// After
SnackBarHelper.showSuccess(
  context,
  'Success message',
  duration: Duration(seconds: 3),
);
```

### Available Methods

1. **`SnackBarHelper.showSuccess()`** - Green background for success messages
2. **`SnackBarHelper.showError()`** - Red background for error messages  
3. **`SnackBarHelper.showWarning()`** - Orange background for warning messages
4. **`SnackBarHelper.showInfo()`** - Blue background for info messages
5. **`SnackBarHelper.showSnackBarAboveFAB()`** - Custom SnackBar with any color

### Features

- **Positioned above FAB**: All SnackBars appear above the floating action button
- **Consistent styling**: Predefined colors and durations for different message types
- **Floating behavior**: Uses `SnackBarBehavior.floating` for better positioning
- **Customizable**: Supports custom durations and SnackBarAction

### Example

```dart
import '../utils/snackbar_helper.dart';

// Success message
SnackBarHelper.showSuccess(context, 'Item added to cart!');

// Error message with longer duration
SnackBarHelper.showError(
  context, 
  'Failed to add item', 
  duration: Duration(seconds: 5)
);

// Warning message
SnackBarHelper.showWarning(context, 'Please check your input');

// Info message
SnackBarHelper.showInfo(context, 'Loading data...');

// Custom SnackBar
SnackBarHelper.showSnackBarAboveFAB(
  context,
  message: 'Custom message',
  backgroundColor: Colors.purple,
  duration: Duration(seconds: 2),
  action: SnackBarAction(
    label: 'Undo',
    onPressed: () => undoAction(),
  ),
);
```

## Migration

To migrate existing SnackBar calls:

1. Import the helper: `import '../utils/snackbar_helper.dart';`
2. Replace `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` with the appropriate helper method
3. Extract the message text and use it as the first parameter
4. Use the helper's predefined colors or specify custom ones
