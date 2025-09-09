# Flutter

## 🧭 1. **Global Flutter Config**

- **Path**: `$HOME/.flutter`
- **Purpose**: Stores global settings like analytics preferences, enabled features, and cached metadata.
- **Contents**:
  - `settings`: JSON file with flags like `enable-linux-desktop`
  - `analytics.json`: opt-in/out status

### 🧰 2. **Project-Specific Config**

- **Path**: Inside your Flutter project directory
- **Files**:
  - `pubspec.yaml`: Declares dependencies, assets, and metadata
  - `.metadata`: Tracks Flutter version and project type
  - `.packages`: Maps Dart packages (deprecated in favor of `.dart_tool/package_config.json`)
  - `.dart_tool/`: Contains build artifacts and config for tools like `dart`, `flutter`, and `build_runner`

### 🧪 3. **Snap Install Path (if used)**

 If you installed Flutter via Snap:
 - **SDK Path**:  
  `/home/<username>/snap/flutter/common/flutter`
 - **Config Path**:  
  Still uses `$HOME/.flutter` for global settings

### 🧠 Bonus: Check Current Config
This command shows you the current configuration, including:
- SDK path
- Analytics opt-in status
- Enabled features
- Cached metadata

use `flutter config` to see a list of current settings.
use `flutter config --list` to see a list of all available settings.
