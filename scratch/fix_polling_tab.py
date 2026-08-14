import os

file_path = r"c:\Users\Administrator\Desktop\rajahmundry_2\rajahmundry\rajahmundry\Smart-Gov-App\flutter_demo_app\lib\screens\super_admin\super_polling_tab.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the start of the master dataset comment
target = "// Master Self-Contained Dataset - 1,557 Verified Polling Station Records"
idx = content.find(target)
if idx != -1:
    # Truncate content up to that comment
    new_content = content[:idx].strip() + "\n"
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Successfully truncated the file!")
else:
    print("Target comment not found!")
