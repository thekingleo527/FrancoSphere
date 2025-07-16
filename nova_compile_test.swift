// Quick compilation test for Nova types
import Foundation

// This should compile without errors if fixes worked
func testNovaTypes() {
    let context = NovaContext(data: "test")
    let prompt = NovaPrompt(text: "test prompt")
    let action = NovaAction(title: "test", description: "test", actionType: .complete)
    
    print("✅ Nova types compile correctly")
    print("Context ID: \(context.id)")
    print("Prompt ID: \(prompt.id)")
    print("Action ID: \(action.id)")
}
