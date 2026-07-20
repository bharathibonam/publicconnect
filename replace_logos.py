import os
from PIL import Image

def process_file(file_path, src_img):
    try:
        # Get the size of the target image
        target = Image.open(file_path)
        size = target.size
        target.close()
        
        # Resize the source image to the target size
        resized = src_img.resize(size, Image.Resampling.LANCZOS)
        resized.save(file_path, "PNG")
        print(f"Replaced {file_path} with size {size}")
    except Exception as e:
        print(f"Failed to process {file_path}: {e}")

def main():
    base_dir = "."
    src_logo_path = "assets/images/logo_padded.png"
    
    if not os.path.exists(src_logo_path):
        print(f"Source logo {src_logo_path} not found.")
        return
        
    src_img = Image.open(src_logo_path)

    # 1. Android launcher icons
    android_res_dir = os.path.join(base_dir, "android", "app", "src", "main", "res")
    if os.path.exists(android_res_dir):
        for root, dirs, files in os.walk(android_res_dir):
            for file in files:
                if file.startswith("ic_launcher") and file.endswith(".png"):
                    process_file(os.path.join(root, file), src_img)

    # 2. iOS launcher and splash icons
    ios_assets_dir = os.path.join(base_dir, "ios", "Runner", "Assets.xcassets")
    if os.path.exists(ios_assets_dir):
        for root, dirs, files in os.walk(ios_assets_dir):
            for file in files:
                if file.endswith(".png"):
                    process_file(os.path.join(root, file), src_img)

    # 3. Web icons
    web_dir = os.path.join(base_dir, "web")
    if os.path.exists(web_dir):
        for root, dirs, files in os.walk(web_dir):
            for file in files:
                if file.endswith(".png"):
                    process_file(os.path.join(root, file), src_img)
                elif file.endswith(".ico"):
                    process_file(os.path.join(root, file), src_img)

    print("All logos replaced successfully!")

if __name__ == "__main__":
    main()
