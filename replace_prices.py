import os

directories = [
    r'c:\Users\Faiz\Downloads\eventease_new\lib\features\customer',
    r'c:\Users\Faiz\Downloads\eventease_new\lib\features\booking',
    r'c:\Users\Faiz\Downloads\eventease_new\lib\shared\widgets'
]

for directory in directories:
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = content.replace('toStringAsFixed(0)', 'toStringAsFixed(2)')
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f'Updated {filepath}')
