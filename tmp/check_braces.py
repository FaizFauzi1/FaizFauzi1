
import sys

def check_braces(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        depth = 0
        for i, line in enumerate(lines):
            line_num = i + 1
            for char in line:
                if char == '{':
                    depth += 1
                elif char == '}':
                    depth -= 1
                    if depth < 0:
                        print(f"ERROR: Extra closing brace at line {line_num}: {line.strip()}")
                        return
            
            # Print depth changes for significant lines or if depth is high
            if i % 100 == 0 or depth != 0:
                # Optionally print some context
                pass
        
        if depth > 0:
            print(f"ERROR: Unclosed opening braces. Final depth: {depth}")
        elif depth == 0:
            print("SUCCESS: Braces are balanced.")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        check_braces(sys.argv[1])
    else:
        print("Usage: python check_braces.py <file_path>")
