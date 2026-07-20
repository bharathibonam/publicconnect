import sys
from PIL import Image, ImageChops

def make_white_transparent(img):
    img = img.convert("RGBA")
    data = img.getdata()
    newData = []
    # threshold for white
    for item in data:
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)
    img.putdata(newData)
    return img

def crop_transparent(img):
    bg = Image.new(img.mode, img.size, (255, 255, 255, 0))
    diff = ImageChops.difference(img, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return img.crop(bbox)
    return img

def create_padded(img, pad_ratio=0.2):
    w, h = img.size
    new_w = int(w * (1 + pad_ratio * 2))
    new_h = int(h * (1 + pad_ratio * 2))
    size = max(new_w, new_h)
    new_img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    x = (size - w) // 2
    y = (size - h) // 2
    new_img.paste(img, (x, y))
    return new_img

if __name__ == "__main__":
    src_path = sys.argv[1]
    img = Image.open(src_path)
    img_transparent = make_white_transparent(img)
    img_cropped = crop_transparent(img_transparent)
    
    # Save the base transparent cropped logo
    img_cropped.save("assets/images/logo.png")
    
    # For launcher icons and splash screens, we usually want it centered in a square
    padded_img = create_padded(img_cropped, 0.15)
    padded_img.save("assets/images/app_logo.png")
    padded_img.save("assets/images/logo_padded.png")

    # Save favicon
    favicon = padded_img.resize((256, 256), Image.Resampling.LANCZOS)
    favicon.save("assets/images/favicon.png")
    
    print("Logo processed successfully!")
