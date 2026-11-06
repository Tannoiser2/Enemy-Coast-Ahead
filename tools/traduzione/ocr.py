import json, sys, cv2
from rapidocr_onnxruntime import RapidOCR
ocr = RapidOCR()
img = cv2.imread('/home/claude/src_mod/x/Mods/Images/httpsiimgurcomTiIUW8xjpg.jpg')
H, W = img.shape[:2]
out = []
T = 1100; O = 150
for y in range(0, H, T):
    for x in range(0, W, T):
        x0, y0 = max(0, x - O), max(0, y - O)
        tile = img[y0:min(H, y + T + O), x0:min(W, x + T + O)]
        res, _ = ocr(tile)
        for box, txt, conf in (res or []):
            xs = [p[0] + x0 for p in box]; ys = [p[1] + y0 for p in box]
            cx, cy = sum(xs)/4, sum(ys)/4
            if not (x <= cx < x + T and y <= cy < y + T):
                continue
            out.append({"box": [[round(a), round(b)] for a, b in zip(xs, ys)], "t": txt, "c": round(float(conf), 2)})
json.dump(out, open('ocr.json', 'w'), ensure_ascii=False, indent=0)
print(len(out))
