# FrancoSphere Development Guidelines

## Build & Test Commands
- Build: `xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere -configuration Debug build`
- Test All: `xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere -destination 'platform=iOS Simulator,name=iPhone 15' test`
- Run Single Test: `xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:FrancoSphereTests/FrancoSphereTests/testName`
- UI Test: `xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:FrancoSphereUITests/FrancoSphereUITests/testName`

## Code Style Guidelines
- **Imports**: Group imports by framework (SwiftUI, Foundation, etc.)
- **Naming**: Use descriptive camelCase for variables/functions, PascalCase for types
- **Documentation**: Use /// for public API documentation
- **MARK comments**: Use MARK: - SectionName to organize code sections
- **Error Handling**: Use meaningful do/catch blocks with descriptive error messages
- **Types**: Prefer strong typing with enums for predefined options
- **Organization**: Place extensions in the same file as the type being extended
- **SwiftUI**: Keep view components small and composable
- **Models**: Define models in the Models directory with clear property names