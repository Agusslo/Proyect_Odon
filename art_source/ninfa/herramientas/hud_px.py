"""HUD en pixel art: retrato de Ninfa, celdas de vida y segmentos de Brasas."""
import sys
import numpy as np
from PIL import Image, ImageEnhance
from scipy import ndimage
from scipy.cluster.vq import kmeans2

CONCEPT, OUT = sys.argv[1], sys.argv[2]


def save(a, name):
    Image.fromarray(a.astype(np.uint8), "RGBA").save(f"{OUT}/{name}.png")


def outline(a, col=(8, 6, 10, 255)):
    m = a[..., 3] > 0
    o = ndimage.binary_dilation(m, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]]) & ~m
    a[o] = col
    return a


# ---------------------------------------------------------------- retrato (34x34)
im = Image.open(CONCEPT).convert("RGB")
crop = np.array(im.crop((60, 600, 470, 990))).astype(int)  # primer plano del casco
near = np.abs(crop - np.array([16, 15, 15])).sum(2) < 14
lab, _ = ndimage.label(near)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
alpha = ~np.isin(lab, list(border))
l2, n = ndimage.label(alpha)
sz = ndimage.sum(alpha, l2, range(1, n + 1))
alpha = l2 == (np.argmax(sz) + 1)
head = Image.fromarray(crop.astype(np.uint8))
head = ImageEnhance.Brightness(head).enhance(1.35)
head = ImageEnhance.Color(head).enhance(1.25)
head_a = Image.fromarray((alpha * 255).astype(np.uint8))
bb = head_a.getbbox()
head, head_a = head.crop(bb), head_a.crop(bb)
S = 23
w, h = head.size
k = S / max(w, h)
nw, nh = max(1, round(w * k)), max(1, round(h * k))
small = np.array(head.resize((nw, nh), Image.BOX)).astype(np.float64)
sa = np.array(head_a.resize((nw, nh), Image.BOX)) > 110
cent, labs = kmeans2(small[sa], 12, minit="++", seed=2)
q = np.zeros((nh, nw, 4))
q[sa, :3] = cent[labs]
q[sa, 3] = 255
lum = small.sum(2)
ey, ex = np.unravel_index(np.argmax(np.where(sa, lum, 0)), lum.shape)
q[ey, ex] = (250, 252, 255, 255)
if ex + 1 < nw and sa[ey, ex + 1]:
    q[ey, ex + 1] = (200, 230, 255, 255)
portrait = q

P = 34
frame = np.zeros((P, P, 4))
yy, xx = np.mgrid[0:P, 0:P]
r = np.hypot(xx - P / 2 + 0.5, yy - P / 2 + 0.5)
frame[r <= 15.5] = (14, 12, 20, 255)                  # fondo
glow = np.clip(1 - r / 15.0, 0, 1)
frame[r <= 14.5, 0] += glow[r <= 14.5] * 70           # brasa roja atrás del casco
frame[(r > 13.5) & (r <= 16.5)] = (58, 46, 52, 255)   # aro de hierro
frame[(r > 13.5) & (r <= 14.5)] = (30, 22, 28, 255)
frame[(r > 15.5) & (r <= 16.5) & (yy < P / 2)] = (104, 84, 88, 255)  # brillo arriba
for (cx, cy) in ((17, 1), (17, 32), (1, 17), (32, 17)):          # remaches
    frame[cy, cx] = (180, 120, 70, 255)
# casco centrado, abajo
oy, ox = P - 4 - nh, (P - nw) // 2 + 1
for y in range(nh):
    for x in range(nw):
        if portrait[y, x, 3] > 0:
            ty, tx = oy + y, ox + x
            if 0 <= ty < P and 0 <= tx < P and r[ty, tx] <= 14.0:
                frame[ty, tx] = portrait[y, x]
save(outline(frame.clip(0, 255)), "hud_portrait")

# ---------------------------------------------------------------- celdas de vida (11x12, panal)
HEX = ["...XXXXX...",
       "..XXXXXXX..",
       ".XXXXXXXXX.",
       "XXXXXXXXXXX",
       "XXXXXXXXXXX",
       "XXXXXXXXXXX",
       "XXXXXXXXXXX",
       "XXXXXXXXXXX",
       ".XXXXXXXXX.",
       "..XXXXXXX..",
       "...XXXXX..."]
hm = np.array([[c == "X" for c in row] for row in HEX])
H, W = hm.shape
inner = ndimage.binary_erosion(hm)


def cell(fill, edge, hi=None, core=None):
    a = np.zeros((H, W, 4))
    a[hm] = edge + (255,)
    a[inner] = fill + (255,)
    if hi:
        for (y, x) in ((2, 3), (2, 4), (3, 2), (3, 3)):
            a[y, x] = hi + (255,)
    if core:
        a[5:7, 5] = core + (255,)
    return outline(a)


save(cell((196, 226, 240), (90, 130, 170), hi=(250, 254, 255), core=(130, 190, 230)), "hp_full")
save(cell((24, 22, 32), (60, 58, 74)), "hp_empty")
save(cell((255, 255, 255), (255, 220, 200)), "hp_flash")
save(cell((230, 70, 60), (140, 30, 30), hi=(255, 170, 150)), "hp_danger")

# ---------------------------------------------------------------- segmentos de Brasas (24x7)
SW, SH = 24, 7
under = np.zeros((SH, SW, 4))
under[:, :] = (40, 30, 34, 255)
under[1:-1, 1:-1] = (14, 10, 14, 255)
under[0, 1:-1] = (90, 70, 70, 255)
save(outline(under), "brasa_under")
fill = np.zeros((SH, SW, 4))
rng = np.random.default_rng(5)
for x in range(SW):
    for y in range(SH):
        t = y / (SH - 1)
        c = np.array([255, 210, 110]) * (1 - t) + np.array([200, 40, 30]) * t
        if rng.random() < 0.12:
            c = np.array([255, 240, 170])
        fill[y, x] = tuple(c) + (255,)
fill[0, :] = (255, 248, 200, 255)
save(fill, "brasa_fill")
print("ok", nw, nh)
