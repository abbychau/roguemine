# RogueMine - Mobile Vertical Game

A mobile-first vertical orientation game built with Godot 4.3.

## Mobile Configuration Features

### Display Settings
- **Resolution**: 1080x1920 (9:16 aspect ratio)
- **Orientation**: Portrait (vertical) locked
- **Stretch Mode**: Canvas items with keep aspect ratio
- **Rendering**: Mobile renderer optimized

### Touch Controls
- Touch input emulation enabled for desktop testing
- Mobile back button handling
- Touch-optimized UI elements

### Project Structure
```
roguemine/
├── scenes/
│   ├── MainMenu.tscn      # Main menu with vertical layout
│   └── GameScene.tscn     # Demo game scene
├── scripts/
│   ├── MainMenu.gd        # Menu navigation logic
│   └── GameScene.gd       # Game logic with touch handling
├── builds/                # Export builds directory
└── export_presets.cfg     # Android export configuration
```

## Controls
- **Touch/Tap**: Interact with game elements
- **Back Button**: Navigate back (Android)
- **UI Buttons**: Menu navigation

## Development Setup

1. Open the project in Godot 4.3
2. The main scene is set to `MainMenu.tscn`
3. Run the project to test in desktop mode
4. For mobile testing, export to Android using the configured preset

## Export for Android

1. Install Android SDK and configure Godot export templates
2. Go to Project → Export
3. Select "Android" preset
4. Configure signing keys if needed
5. Export to `builds/RogueMine.apk`

## Key Features Implemented

### Main Menu (`MainMenu.tscn`)
- Vertical layout optimized for mobile
- Large touch-friendly buttons
- Clean, simple design
- Version display

### Game Scene (`GameScene.tscn`)
- Touch interaction demo
- Score system
- Back navigation
- Visual feedback on touch

### Mobile Optimizations
- Portrait orientation lock
- Touch input handling
- Mobile renderer
- Proper aspect ratio scaling
- Android back button support

## Next Steps

1. Implement actual game mechanics
2. Add sound effects and music
3. Create options/settings menu
4. Add more visual effects
5. Implement save system
6. Add more scenes and levels

## Testing

- Desktop: Run directly in Godot editor
- Mobile: Export and install APK on Android device
- Touch simulation works in editor for basic testing
