# Changelog

## [2.0.0] - 2025-12-02

### ✨ New Features
-   **App Mode Selection**: Choose between "Online & Offline" or "Only Offline" mode at startup.
-   **Offline Mode**: Dedicated offline experience with restricted online features and no login requirement.
-   **Strict Login Enforcement**: Online playback and downloads now strictly require user authentication.
-   **Forced Update Mechanism**: App checks for critical updates and prompts the user to update.
-   **Offline Home Banner**: Visual indicator when running in offline mode.
-   **Smart State Management**: Auto-switch to Online mode on login, and Offline mode on logout.

### 🐛 Fixes & Improvements
-   Refactored `UpdateService` for better maintainability.
-   Improved startup routing logic.
-   Fixed login/logout state synchronization.
