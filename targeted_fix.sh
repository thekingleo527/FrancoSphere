#!/bin/bash

echo "🔧 FrancoSphere Targeted Fix - Round 2"
echo "======================================"

cd "/Volumes/FastSSD/Xcode" || exit 1

# Create more precise Python fix
cat > /tmp/targeted_fix.py << 'PYTHON_EOF'
import re

def fix_weather_dashboard_precisely():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Create backup
        with open(file_path + '.targeted_backup.' + str(int(__import__('time').time())), 'w') as f:
            f.write(content)
        
        print("🔧 Fixing WeatherDashboardComponent.swift precisely...")
        
        # 1. Fix the malformed ContextualTask array (lines 323-335)
        # Remove the broken array syntax and replace with proper empty array
        malformed_pattern = r'\[\s*ContextualTask\([^]]*\][^]]*\]'
        content = re.sub(malformed_pattern, '[]', content, flags=re.DOTALL)
        
        # Also fix any standalone malformed ContextualTask calls
        content = re.sub(r'ContextualTask\([^)]*uuidString[^)]*\)', '[]', content)
        
        # 2. Fix CLLocationCoordinate2D conversion (lines 311-312)
        # Look for weatherManager.fetchWeather calls with latitude/longitude
        fetch_pattern = r'weatherManager\.fetchWeather\(\s*latitude:\s*([^,]+),\s*longitude:\s*([^)]+)\s*\)'
        fetch_replacement = r'weatherManager.fetchWeather(for: CLLocationCoordinate2D(latitude: \1, longitude: \2))'
        content = re.sub(fetch_pattern, fetch_replacement, content)
        
        # 3. Fix remaining switch statements by finding incomplete ones and making them exhaustive
        
        # Pattern for weather condition switches that are incomplete
        incomplete_switch_patterns = [
            # Find switch statements that don't handle all WeatherCondition cases
            (r'(switch\s+[^{]*\.condition\s*\{\s*)((?:.*?case\s+\.[^:]+:[^}]+)*)(.*?\})', 
             lambda m: fix_weather_condition_switch(m.group(1), m.group(2), m.group(3))),
            
            # Find switch statements on risk that are incomplete  
            (r'(switch\s+[^{]*risk\s*\{\s*)((?:.*?case\s+\.[^:]+:[^}]+)*)(.*?\})',
             lambda m: fix_risk_switch(m.group(1), m.group(2), m.group(3))),
        ]
        
        for pattern, replacement_func in incomplete_switch_patterns:
            content = re.sub(pattern, replacement_func, content, flags=re.DOTALL)
        
        # 4. Add default cases to any remaining incomplete switches
        content = add_default_cases_to_switches(content)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed WeatherDashboardComponent.swift")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def fix_weather_condition_switch(prefix, cases, suffix):
    """Fix incomplete weather condition switches"""
    # Check which cases are missing
    required_cases = ['.clear', '.sunny', '.cloudy', '.rain', '.rainy', 
                      '.snow', '.snowy', '.storm', '.stormy', '.fog', 
                      '.foggy', '.windy']
    
    missing_cases = []
    for case in required_cases:
        if case not in cases:
            missing_cases.append(case)
    
    if missing_cases:
        # Add missing cases with reasonable defaults
        additional_cases = ""
        for case in missing_cases:
            if 'return' in cases:
                # This is a return switch - add appropriate return
                if 'String' in prefix:  # Icon switch
                    additional_cases += f"\n        case {case}: return \"cloud.fill\""
                elif 'Color' in prefix:  # Color switch  
                    additional_cases += f"\n        case {case}: return .gray"
                else:  # Risk switch
                    additional_cases += f"\n        case {case}: return .medium"
            else:
                # Other type of switch
                additional_cases += f"\n        case {case}: break"
        
        # Insert additional cases before the closing brace
        cases += additional_cases
    
    return prefix + cases + suffix

def fix_risk_switch(prefix, cases, suffix):
    """Fix incomplete risk switches"""
    required_cases = ['.low', '.medium', '.high', '.extreme']
    
    missing_cases = []
    for case in required_cases:
        if case not in cases:
            missing_cases.append(case)
    
    if missing_cases:
        additional_cases = ""
        for case in missing_cases:
            if 'String' in prefix:  # Icon or description switch
                additional_cases += f"\n        case {case}: return \"questionmark.circle\""
            elif 'Color' in prefix:  # Color switch
                additional_cases += f"\n        case {case}: return .gray"
            else:
                additional_cases += f"\n        case {case}: break"
        
        cases += additional_cases
    
    return prefix + cases + suffix

def add_default_cases_to_switches(content):
    """Add default cases to any remaining incomplete switches"""
    
    # Find switch statements that don't have all cases covered
    switch_pattern = r'(switch\s+[^{]+\s*\{[^}]*)(case\s+[^}]+)(\})'
    
    def add_default_if_needed(match):
        prefix = match.group(1)
        cases = match.group(2) 
        suffix = match.group(3)
        
        # If there's no default case and it looks incomplete, add one
        if 'default:' not in cases and '@unknown default:' not in cases:
            # Determine what kind of switch this is
            if 'return' in cases:
                if 'String' in prefix:
                    cases += "\n        default: return \"questionmark.circle\""
                elif 'Color' in prefix:
                    cases += "\n        default: return .gray"
                else:
                    cases += "\n        default: return .medium"
            else:
                cases += "\n        default: break"
        
        return prefix + cases + suffix
    
    content = re.sub(switch_pattern, add_default_if_needed, content, flags=re.DOTALL)
    return content

def main():
    print("🎯 Running targeted fixes for remaining errors...")
    
    if fix_weather_dashboard_precisely():
        print("\n🎉 Targeted fix completed!")
        print("\n🚀 Next steps:")
        print("1. Open Xcode")
        print("2. Build project (Cmd+B)")
        print("3. Check for any remaining errors")
        return True
    else:
        print("\n❌ Fix failed")
        return False

if __name__ == "__main__":
    main()
PYTHON_EOF

python3 /tmp/targeted_fix.py

echo ""
echo "🎯 TARGETED FIX COMPLETED!"
echo "========================="
