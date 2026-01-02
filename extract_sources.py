#!/usr/bin/env python3
"""
Extract source code from .rbxlx file
"""
import xml.etree.ElementTree as ET
import sys
import os

def extract_sources(filepath, output_dir="extracted_sources"):
    """Extract all source code to separate files"""
    os.makedirs(output_dir, exist_ok=True)

    tree = ET.parse(filepath)
    root = tree.getroot()

    extracted = []

    def extract_name(item):
        """Extract name from Item properties"""
        props = item.find('Properties')
        if props is not None:
            name_elem = props.find(".//string[@name='Name']")
            if name_elem is not None:
                return name_elem.text
        return "Unknown"

    def extract_source(item):
        """Extract source code"""
        props = item.find('Properties')
        if props is not None:
            source_elem = props.find(".//ProtectedString[@name='Source']")
            if source_elem is not None:
                return source_elem.text
        return None

    def traverse(item, path=""):
        """Recursively traverse XML tree"""
        class_name = item.get('class', '')
        name = extract_name(item)
        current_path = f"{path}/{name}" if path else name

        # Extract script sources
        if class_name in ['LocalScript', 'Script', 'ModuleScript']:
            source = extract_source(item)
            if source and source.strip():
                # Create safe filename
                safe_path = current_path.replace('/', '_').replace(' ', '_')
                ext = '.lua'
                if class_name == 'LocalScript':
                    ext = '.client.lua'
                elif class_name == 'Script':
                    ext = '.server.lua'

                filename = f"{safe_path}{ext}"
                filepath = os.path.join(output_dir, filename)

                with open(filepath, 'w') as f:
                    f.write(source)

                extracted.append({
                    'type': class_name,
                    'name': name,
                    'path': current_path,
                    'file': filename
                })

        # Recurse
        for child in item:
            if child.tag == 'Item':
                traverse(child, current_path)

    # Start traversal
    for item in root.findall('Item'):
        traverse(item)

    return extracted

def main():
    filepath = sys.argv[1] if len(sys.argv) > 1 else 'bg game.rbxlx'

    print(f"Extracting sources from: {filepath}\n")
    extracted = extract_sources(filepath)

    print(f"Extracted {len(extracted)} scripts to ./extracted_sources/\n")

    # Print inventory
    for item in extracted:
        print(f"  [{item['type']}] {item['path']}")
        print(f"     → {item['file']}")

if __name__ == "__main__":
    main()
