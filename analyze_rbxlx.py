#!/usr/bin/env python3
"""
Parse Roblox .rbxlx file to extract structure and scripts
"""
import xml.etree.ElementTree as ET
import sys

def parse_rbxlx(filepath):
    """Parse .rbxlx and extract key information"""
    tree = ET.parse(filepath)
    root = tree.getroot()

    scripts = {
        'LocalScript': [],
        'Script': [],
        'ModuleScript': []
    }

    services = {}

    def extract_name(item):
        """Extract name from Item properties"""
        props = item.find('Properties')
        if props is not None:
            name_elem = props.find(".//string[@name='Name']")
            if name_elem is not None:
                return name_elem.text
        return "Unknown"

    def extract_source(item):
        """Extract source code snippet"""
        props = item.find('Properties')
        if props is not None:
            source_elem = props.find(".//ProtectedString[@name='Source']")
            if source_elem is not None:
                source = source_elem.text
                if source:
                    # Get first 100 chars
                    lines = source.strip().split('\n')[:3]
                    return ' | '.join(lines)
        return ""

    def traverse(item, path="", depth=0):
        """Recursively traverse XML tree"""
        class_name = item.get('class', '')
        name = extract_name(item)
        current_path = f"{path}/{name}" if path else name

        # Track services
        if class_name in ['ReplicatedStorage', 'ServerScriptService', 'StarterPlayer', 'Workspace']:
            services[class_name] = current_path

        # Track scripts
        if class_name in scripts:
            source_preview = extract_source(item)
            scripts[class_name].append({
                'name': name,
                'path': current_path,
                'source_preview': source_preview[:150]
            })

        # Recurse
        for child in item:
            if child.tag == 'Item':
                traverse(child, current_path, depth + 1)

    # Start traversal
    for item in root.findall('Item'):
        traverse(item)

    return scripts, services

def main():
    filepath = sys.argv[1] if len(sys.argv) > 1 else 'bg game.rbxlx'

    print(f"Analyzing: {filepath}\n")
    scripts, services = parse_rbxlx(filepath)

    print("=" * 80)
    print("SERVICES FOUND")
    print("=" * 80)
    for service, path in services.items():
        print(f"  {service}: {path}")

    print("\n" + "=" * 80)
    print("SCRIPTS INVENTORY")
    print("=" * 80)

    for script_type, script_list in scripts.items():
        print(f"\n{script_type} ({len(script_list)}):")
        print("-" * 80)
        for script in script_list:
            print(f"\n  Name: {script['name']}")
            print(f"  Path: {script['path']}")
            if script['source_preview']:
                print(f"  Preview: {script['source_preview']}")

    print("\n" + "=" * 80)
    print(f"TOTAL: {sum(len(v) for v in scripts.values())} scripts")
    print("=" * 80)

if __name__ == "__main__":
    main()
