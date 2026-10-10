# Changelog

## 2.0.0

- Added a terminal-aware startup sequence with static, fast, and disabled modes.
- Reorganized navigation into the 13 requested tool areas and added shared UI/status helpers.
- Improved ADB/Fastboot enumeration and device-state reporting; missing properties remain unknown.
- Made dry-run the default for recovery flashing and temporary Fastboot boot.
- Blocked recovery flashing unless Fastboot reports a product, the target matches exactly, the image is non-empty, a trusted SHA-256 matches, and the user confirms the dedicated `recovery` partition.
- Added local checksum catalog, backup integrity checks, destination validation, service report export, structured rescue guides, firmware ZIP inspection, and safe Git fast-forward updates.
- Added mock ADB/Fastboot tests and updated Termux installation and safety documentation.
- Real-device USB/OTG behavior and model-specific recovery compatibility remain unverified without the target hardware.
