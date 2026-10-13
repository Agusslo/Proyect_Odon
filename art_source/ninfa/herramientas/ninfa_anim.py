"""Anima a Ninfa (partes recortadas del concepto) y convierte cada cuadro a pixel art.

Uso: python3 ninfa_anim.py <carpeta_partes> <carpeta_salida> [preview]
Salida: <anim>.png (tira horizontal de cuadros), frames.json (tamaño de cuadro, fps, loop, ancla)."""
import json, math, sys
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.cluster.vq import kmeans2

PARTS, OUT = sys.argv[1], sys.argv[2]
rig = json.load(open(f"{PARTS}/rig.json"))
SRC_W, SRC_H = rig["size"]
HIP = np.array(rig["root"], float)

TARGET_H = 56                 # alto del personaje en píxeles del juego (cuernos a botas)
CHAR_H = 575.0                # alto en la hoja original
S = TARGET_H / CHAR_H
CANVAS = (1440, 1000)         # lienzo de render (coordenadas de la hoja)
ANCHOR = np.array([720.0, 640.0])  # dónde cae la cadera en el lienzo
FW, FH = round(CANVAS[0] * S), round(CANVAS[1] * S)

parts = {}
for name, parent, pivot in rig["parts"]:
    im = Image.open(f"{PARTS}/{name}.png").convert("RGBA")
    a = np.array(im)
    # limpieza de hilachas de 1-2 px
    m = ndimage.binary_opening(a[..., 3] > 0, structure=np.ones((3, 3)))
    a[..., 3] = np.where(m, a[..., 3], 0)
    parts[name] = {"img": Image.fromarray(a), "parent": parent, "pivot": np.array(pivot, float)}

# Alas iridiscentes (como en el concepto): violeta -> turquesa -> dorado según la posición,
# conservando las venas oscuras del dibujo original.
def _iridescent(img):
    a = np.array(img).astype(np.float32)
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    t = ((xx / w) * 0.7 + (yy / h) * 0.5) * 2.2 % 1.0
    stops = np.array([[150, 130, 220], [110, 200, 215], [215, 200, 140], [190, 130, 210], [150, 130, 220]], np.float32)
    k = t * (len(stops) - 1)
    i0 = np.floor(k).astype(int)
    f = (k - i0)[..., None]
    col = stops[i0] * (1 - f) + stops[np.minimum(i0 + 1, len(stops) - 1)] * f
    lum = a[..., :3].mean(-1, keepdims=True) / 255.0
    vein = np.clip(lum * 1.6, 0.35, 1.15)
    a[..., :3] = np.clip(col * vein * 0.72 + a[..., :3] * 0.38, 0, 255)
    return Image.fromarray(a.astype(np.uint8))


parts["wings"]["img"] = _iridescent(parts["wings"]["img"])

# capas emisivas: el ojo (blanco) y las grietas de fuego del brazo
head_a = np.array(parts["head"]["img"]).astype(int)
eye = (head_a[..., :3].sum(2) > 640) & (head_a[..., 3] > 0)
arm_a = np.array(parts["arm"]["img"]).astype(int)
ember = (arm_a[..., 0] > 140) & (arm_a[..., 0] > arm_a[..., 1] * 2.2) & (arm_a[..., 3] > 0)
EMISSIVE = {"arm": Image.fromarray((ember * 255).astype(np.uint8))}


def T(x, y):
    return np.array([[1, 0, x], [0, 1, y], [0, 0, 1.0]])


def R(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1.0]])


def Sc(sx, sy):
    return np.array([[sx, 0, 0], [0, sy, 0], [0, 0, 1.0]])


# --- Silueta: proporciones de cada parte (fijas en todas las animaciones).
# El recorte del concepto, achicado a 56 px, quedaba "gordo": capa ancha, brazo grueso
# y piernas cortas. Acá se estiliza sin cambiar el diseño: torso y capa más angostos,
# capa más corta, piernas (botas) más largas y alas de libélula más largas y finas.
PART_SCALE = {
    "body": (0.80, 1.0),
    "hem": (0.78, 0.80),
    "arm": (0.82, 0.98),
    "leg_back": (0.92, 1.45),
    "leg_front": (0.92, 1.45),
    "wings": (1.18, 0.78),
    "head": (0.96, 0.98),
    "katana": (1.0, 1.0),
}
LEG_LEN = 71.0
LIFT = LEG_LEN * (PART_SCALE["leg_front"][1] - 1.0)   # se sube el cuerpo para que las botas sigan pisando el piso


def world(pose):
    """Matrices de dibujo de cada parte: jerarquía (world_raw) + la escala propia de la silueta."""
    Wm = world_raw(pose)
    out = {}
    for name in Wm:
        sx, sy = PART_SCALE.get(name, (1.0, 1.0))
        pv = HIP if name == "body" else parts[name]["pivot"]
        out[name] = Wm[name] @ T(pv[0], pv[1]) @ Sc(sx, sy) @ T(-pv[0], -pv[1])
    return out


def world_raw(pose):
    """pose: {parte: ángulo, 'off': (dx,dy) del cuerpo, 'rot': giro del cuerpo, 'sx','sy': estirar, '<parte>_off'}."""
    Wm = {}
    off = pose.get("off", (0, 0))
    sq = Sc(pose.get("sx", 1.0), pose.get("sy", 1.0))
    base = T(*(ANCHOR + np.array(off) + np.array([0.0, -LIFT]))) @ R(pose.get("rot", 0)) @ sq @ T(*(-HIP))
    Wm["body"] = base
    for name in ["head", "arm", "katana", "wings", "leg_back", "leg_front", "hem"]:
        p = parts[name]
        pv = p["pivot"]
        o = pose.get(name + "_off", (0, 0))
        k = math.tan(math.radians(pose.get(name + "_skew", 0)))
        shear = np.array([[1, k, 0], [0, 1, 0], [0, 0, 1.0]])  # la parte de abajo se corre (capa que flamea)
        local = T(pv[0] + o[0], pv[1] + o[1]) @ R(pose.get(name, 0)) @ shear @ T(-pv[0], -pv[1])
        Wm[name] = Wm[p["parent"]] @ local
    return Wm


def render(pose, hide=(), layer="color"):
    Wm = world(pose)
    canvas = Image.new("RGBA" if layer == "color" else "L", CANVAS, 0)
    for name, parent, _ in rig["parts"]:
        if name in hide:
            continue
        if layer == "color":
            src = parts[name]["img"]
        else:
            if name not in EMISSIVE:
                # tapar lo emisivo que quede detrás de partes opacas
                m = parts[name]["img"].getchannel("A")
                inv = np.linalg.inv(Wm[name])
                t = m.transform(CANVAS, Image.AFFINE, tuple(inv[:2].flatten()), resample=Image.BILINEAR)
                cn = np.array(canvas).astype(int)
                cn[np.array(t) > 128] = 0
                canvas = Image.fromarray(cn.astype(np.uint8))
                continue
            src = EMISSIVE[name]
        inv = np.linalg.inv(Wm[name])
        t = src.transform(CANVAS, Image.AFFINE, tuple(inv[:2].flatten()), resample=Image.BICUBIC)
        if layer == "color":
            canvas.alpha_composite(t)
        else:
            canvas = Image.fromarray(np.maximum(np.array(canvas), np.array(t)))
    return canvas


# ------------------------------------------------------------------ pixel art
PALETTE = None
EYE = np.array([250, 252, 255]); EMB = np.array([236, 52, 34]); EMB_HOT = np.array([255, 140, 70])
OUTLINE = np.array([9, 7, 12])


def downscale(pose, hide=()):
    col = render(pose, hide)
    a = np.array(col).astype(np.float32)
    rgb = a[..., :3] * (a[..., 3:] / 255.0)
    small_rgb = np.array(Image.fromarray(rgb.clip(0, 255).astype(np.uint8)).resize((FW, FH), Image.BOX)).astype(np.float32)
    small_a = np.array(Image.fromarray(a[..., 3].astype(np.uint8)).resize((FW, FH), Image.BOX)).astype(np.float32)
    with np.errstate(invalid="ignore", divide="ignore"):
        small_rgb = np.where(small_a[..., None] > 0, small_rgb * 255.0 / np.maximum(small_a[..., None], 1), 0)
    em = np.array(render(pose, hide, layer="em").resize((FW, FH), Image.BOX)).astype(np.float32) / 255.0
    return small_rgb, small_a, em


def grade(rgb):
    """Aclara y sube contraste: el original es muy oscuro para un sprite chico."""
    x = rgb / 255.0
    x = np.clip(x, 0, 1) ** 0.8                       # levanta las sombras sin quemar las luces
    x = np.clip((x - 0.45) * 1.08 + 0.45, 0, 1)
    g = x.mean(-1, keepdims=True)
    blue = np.clip((x[..., 2:3] - x[..., 0:1]) * 4, 0, 1)  # el azul (casco, alas) se satura más
    red = np.clip((x[..., 0:1] - x[..., 2:3]) * 4, 0, 1)   # la faja roja y las botas también
    x = np.clip(g + (x - g) * (1.05 + 0.5 * blue + 0.6 * red), 0, 1)
    return x * 255.0


def build_palette(rest_pose, n=30):
    rgb, a, _ = downscale(rest_pose)
    pts = grade(rgb[a > 110])
    cent, _ = kmeans2(pts.astype(np.float64), n, minit="++", seed=3)
    return np.vstack([cent, EYE, EMB, EMB_HOT])


def to_pixels(pose, hide=(), tint=None):
    rgb, a, em = downscale(pose, hide)
    mask = a > 110
    g = grade(rgb)
    if tint is not None:
        g = g * np.array(tint[:3]) + np.array(tint[3:]) * 255.0
    flat = g.reshape(-1, 3)
    pal = PALETTE[:-3]
    d = ((flat[:, None, :] - pal[None, :, :]) ** 2 * np.array([0.3, 0.59, 0.11])).sum(-1)
    q = pal[d.argmin(1)].reshape(FH, FW, 3)
    q[(em > 0.10) & mask & (em <= 0.35)] = EMB
    q[(em > 0.35) & mask] = EMB_HOT
    out = np.zeros((FH, FW, 4), np.uint8)
    out[mask, :3] = q[mask].clip(0, 255).astype(np.uint8)
    out[mask, 3] = 255
    return out, mask


def finish(out, mask, eye_px=None):
    if eye_px is not None:
        y, x = eye_px
        if 0 <= y < FH and 0 <= x < FW:
            out[y, x] = list(EYE) + [255]
    o = ndimage.binary_dilation(mask, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]]) & ~mask
    out[o] = list(OUTLINE) + [255]
    return Image.fromarray(out, "RGBA")


EYE_SRC = np.argwhere(eye).mean(0)[::-1]  # (x, y) del ojo en la hoja


def eye_pixel(pose):
    Wm = world(pose)
    p = Wm["head"] @ np.array([EYE_SRC[0], EYE_SRC[1], 1.0])
    return int(p[1] * S), int(p[0] * S)


def frame(pose, hide=(), tint=None):
    out, mask = to_pixels(pose, hide, tint)
    return finish(out, mask, None if "head" in hide else eye_pixel(pose))


# ------------------------------------------------------------------ animaciones
# Convención: ángulo positivo = giro horario en pantalla. Ninfa mira a la derecha.
def lerp(a, b, t):
    return a + (b - a) * t


def blend(p0, p1, t):
    keys = set(p0) | set(p1)
    out = {}
    for k in keys:
        default = (0, 0) if k.endswith("off") else (1.0 if k in ("sx", "sy") else 0)
        v0, v1 = p0.get(k, default), p1.get(k, default)
        if isinstance(v0, tuple):
            out[k] = (lerp(v0[0], v1[0], t), lerp(v0[1], v1[1], t))
        else:
            out[k] = lerp(v0, v1, t)
    return out


def ease(t):
    return t * t * (3 - 2 * t)


ANIMS = {}


def anim(name, fps, loop, poses):
    ANIMS[name] = {"fps": fps, "loop": loop, "poses": poses}


def keyed(n, keys, loop=True):
    """Interpola poses clave con suavizado. keys = [(t, pose)], t de 0 a 1.
    En los bucles el último cuadro empalma con el primero."""
    ks = sorted(keys, key=lambda k: k[0])
    if loop:
        ks = ks + [(1.0, ks[0][1])]
    out = []
    for i in range(n):
        t = i / n if loop else i / max(n - 1, 1)
        for a, b in zip(ks, ks[1:]):
            if a[0] <= t <= b[0]:
                u = (t - a[0]) / max(b[0] - a[0], 1e-6)
                out.append(blend(a[1], b[1], ease(u)))
                break
        else:
            out.append(dict(ks[-1][1]))
    return out


def buzz(poses, amp, part="wings"):
    """Alas de libélula: tiemblan un poco en cuadros alternados."""
    for i, p in enumerate(poses):
        p[part] = p.get(part, 0) + (amp if i % 2 == 0 else -amp)
    return poses


def over(poses, **extra):
    """Suma valores constantes a todas las poses."""
    for p in poses:
        for k, v in extra.items():
            if isinstance(v, tuple):
                o = p.get(k, (0, 0))
                p[k] = (o[0] + v[0], o[1] + v[1])
            else:
                p[k] = p.get(k, 0) + v
    return poses


# --- reposo: respira, la capa se mece, el ojo baja y sube un poco tarde
anim("idle", 10, True, buzz(keyed(12, [
    (0.0, {"off": (0, 0), "sy": 1.0, "head": -1, "hem": 0, "hem_skew": 0, "arm": 0, "wings": 0}),
    (0.5, {"off": (0, 5), "sy": 0.982, "sx": 1.01, "head": 2, "hem": -2, "hem_skew": 3, "arm": 3, "katana": 2, "wings": 5}),
]), 1.5))

# --- correr: contacto / paso / contacto / paso, con la capa flameando atrás
RUN_BASE = {"rot": 9, "head": -5, "wings": 22, "hem": 10, "hem_skew": -9, "katana": 6}
anim("run", 14, True, buzz(over(keyed(10, [
    (0.0, {"off": (0, 3), "sy": 0.96, "sx": 1.03, "leg_front": -42, "leg_back": 36, "arm": -24, "hem": 2, "head": 1}),
    (0.25, {"off": (0, -14), "sy": 1.03, "leg_front": 0, "leg_back": 0, "leg_front_off": (0, -12), "arm": -12, "hem": 6, "head": -2}),
    (0.5, {"off": (0, 3), "sy": 0.96, "sx": 1.03, "leg_front": 36, "leg_back": -42, "arm": 0, "hem": 2, "head": 1}),
    (0.75, {"off": (0, -14), "sy": 1.03, "leg_front": 0, "leg_back": 0, "leg_back_off": (0, -12), "arm": -12, "hem": 6, "head": -2}),
]), **RUN_BASE), 4))

anim("jump", 14, False, keyed(5, [
    (0.0, {"off": (0, 10), "sy": 0.88, "sx": 1.08, "wings": 4, "hem": -4, "arm": 6, "head": 4}),
    (0.3, {"off": (0, -8), "sy": 1.1, "sx": 0.93, "wings": 30, "leg_back": 26, "leg_front": -22, "hem": 10, "hem_skew": 6, "arm": -16, "head": -4}),
    (1.0, {"off": (0, -10), "sy": 1.03, "wings": 40, "leg_back": 20, "leg_front": -26, "hem": 6, "hem_skew": 4, "arm": -24, "head": -5}),
], loop=False))
anim("fall", 14, True, buzz(keyed(6, [
    (0.0, {"off": (0, -4), "wings": 34, "leg_back": 10, "leg_front": -4, "arm": -30, "head": 4, "hem": -8, "hem_skew": 8}),
    (0.5, {"off": (0, -6), "wings": 40, "leg_back": 14, "leg_front": -8, "arm": -34, "head": 3, "hem": -12, "hem_skew": 12}),
]), 10))

# --- tajo: anticipación (sube por detrás) -> corte -> seguimiento -> vuelta
anim("attack", 20, False, keyed(8, [
    # tajo descendente: la katana sube por arriba de la cabeza y cae hacia adelante
    (0.0, {"arm": -60, "katana": -20, "rot": -4, "off": (-2, 0), "head": -2}),
    (0.22, {"arm": -195, "katana": -25, "rot": -9, "off": (-6, 2), "head": -5, "wings": -6, "hem": -4, "sy": 0.97}),
    (0.45, {"arm": -100, "katana": 18, "rot": 10, "off": (16, 0), "head": 4, "wings": 10, "hem": 10, "hem_skew": -8, "sx": 1.04}),
    (0.62, {"arm": -40, "katana": 14, "rot": 12, "off": (20, 0), "head": 5, "wings": 12, "hem": 12, "hem_skew": -10}),
    (1.0, {"arm": -10, "katana": 0, "rot": 2, "off": (4, 0), "hem": 3}),
], loop=False))
anim("attack2", 20, False, keyed(8, [
    # tajo ascendente: la katana baja por detrás y sube cortando hacia adelante
    (0.0, {"arm": 15, "katana": 15, "rot": 4, "off": (4, 4), "sy": 0.96}),
    (0.2, {"arm": 40, "katana": 35, "rot": 6, "off": (6, 8), "sy": 0.92, "head": 4, "hem": -4}),
    (0.45, {"arm": -80, "katana": 12, "rot": -6, "off": (18, -6), "head": -6, "wings": -8, "hem": 12, "hem_skew": -8, "sy": 1.05}),
    (0.62, {"arm": -125, "katana": 5, "rot": -9, "off": (20, -8), "head": -8, "wings": -12, "hem": 14, "hem_skew": -10}),
    (1.0, {"arm": -20, "katana": 0, "rot": 0, "off": (4, 0)}),
], loop=False))
# --- zarpazo: gran anticipación hacia atrás y estocada con las garras
anim("zarpazo", 20, False, keyed(9, [
    (0.0, {"arm": 30, "rot": -6, "off": (-4, 2), "sy": 0.97}),
    (0.25, {"arm": 75, "katana": 0, "rot": -15, "off": (-16, 4), "head": -9, "wings": -18, "sy": 0.9, "sx": 1.04, "hem": -10, "hem_skew": 8}),
    (0.45, {"arm": -110, "katana": 30, "rot": 19, "off": (34, 2), "head": 7, "wings": 24, "sx": 1.1, "sy": 0.95, "hem": 18, "hem_skew": -14}),
    (0.65, {"arm": -114, "katana": 32, "rot": 20, "off": (38, 2), "head": 7, "wings": 26, "hem": 20, "hem_skew": -16}),
    (1.0, {"arm": -20, "katana": 8, "rot": 3, "off": (8, 0), "hem": 4}),
], loop=False))
anim("attack_up", 20, False, keyed(7, [
    (0.0, {"arm": 40, "katana": -30, "head": 4, "sy": 0.95, "off": (0, 4)}),
    (0.4, {"arm": -205, "katana": -40, "head": -12, "rot": -5, "off": (0, -8), "sy": 1.06, "wings": 14, "hem": -6}),
    (0.6, {"arm": -218, "katana": -30, "head": -13, "rot": -6, "off": (0, -10), "wings": 18}),
    (1.0, {"arm": -40, "katana": -10, "head": -2}),
], loop=False))
anim("attack_down", 20, False, keyed(6, [
    (0.0, {"arm": -200, "katana": -20, "head": -6, "wings": 22, "leg_back": 22, "leg_front": -22, "hem": -6}),
    (0.4, {"arm": -10, "katana": 15, "head": 10, "rot": 8, "wings": 34, "leg_back": 26, "leg_front": -26, "hem": -10, "hem_skew": 10}),
    (1.0, {"arm": 0, "katana": 10, "head": 6, "wings": 26, "leg_back": 16, "leg_front": -16, "hem": -6}),
], loop=False))
# --- Galope del Diablo: tendida, capa y alas hacia atrás
anim("dash", 18, False, buzz(keyed(4, [
    (0.0, {"rot": 18, "off": (0, 8), "wings": 20, "arm": -36, "katana": 26, "leg_back": 38, "leg_front": 26, "head": -12, "sx": 1.06, "sy": 0.95, "hem": 18, "hem_skew": -14}),
    (1.0, {"rot": 26, "off": (0, 12), "wings": 26, "arm": -46, "katana": 34, "leg_back": 48, "leg_front": 36, "head": -16, "sx": 1.13, "sy": 0.91, "hem": 26, "hem_skew": -20}),
], loop=False), 3))
anim("glide", 14, True, buzz(keyed(6, [
    (0.0, {"off": (0, -2), "wings": 52, "leg_back": 18, "leg_front": -8, "arm": -24, "head": -2, "rot": 5, "hem": 16, "hem_skew": -10}),
    (0.5, {"off": (0, 2), "wings": 60, "leg_back": 22, "leg_front": -12, "arm": -28, "head": 0, "rot": 6, "hem": 20, "hem_skew": -13}),
]), 9))
anim("hurt", 14, False, keyed(4, [
    (0.0, {"rot": -20, "off": (-16, 0), "head": -18, "arm": 34, "wings": 18, "sy": 0.94, "hem": -14, "hem_skew": 12}),
    (1.0, {"rot": -8, "off": (-6, 0), "head": -6, "arm": 14, "wings": 8, "hem": -6, "hem_skew": 5}),
], loop=False))
# --- Devorar: estira el brazo, agarra, tira hacia sí, muerde y sacude la cabeza
anim("devour", 14, False, keyed(9, [
    (0.0, {"arm": -40, "katana": 40, "rot": 4, "off": (6, 0)}),
    (0.18, {"arm": -112, "katana": 52, "rot": 18, "off": (28, 4), "head": 6, "wings": 12, "hem": 10, "hem_skew": -8, "sx": 1.06}),
    (0.36, {"arm": -105, "katana": 50, "rot": 16, "off": (24, 6), "head": 8, "wings": 10}),
    (0.55, {"arm": 15, "katana": 30, "rot": -4, "off": (-2, 10), "head": 16, "sy": 0.9, "sx": 1.05, "wings": -8, "hem": -6, "hem_skew": 6}),
    (0.7, {"arm": 10, "katana": 30, "rot": 2, "off": (0, 8), "head": 4, "sy": 0.94, "wings": 6}),
    (0.82, {"arm": 12, "katana": 30, "rot": -2, "off": (0, 8), "head": 14, "sy": 0.93}),
    (1.0, {"arm": 2, "katana": 10, "off": (0, 2), "head": 2}),
], loop=False))
anim("cast", 16, False, keyed(6, [
    (0.0, {"arm": 70, "katana": 0, "rot": -10, "off": (-10, 2), "head": -6, "wings": -12, "sy": 0.95, "hem": -6}),
    (0.35, {"arm": -102, "katana": 42, "rot": 13, "off": (18, 0), "head": 5, "wings": 14, "hem": 12, "hem_skew": -10, "sx": 1.05}),
    (0.65, {"arm": -100, "katana": 40, "rot": 12, "off": (16, 0), "head": 4, "wings": 12, "hem": 10}),
    (1.0, {"arm": -30, "katana": 20, "rot": 3, "off": (4, 0)}),
], loop=False))
anim("death", 12, False, keyed(9, [
    (0.0, {"rot": -10, "off": (-8, 0), "head": -14, "arm": 30, "wings": 10, "hem": -6}),
    (0.25, {"rot": -14, "off": (-12, 26), "head": 12, "arm": 46, "wings": 20, "sy": 0.88, "leg_back": -30, "leg_front": 30}),
    (0.6, {"rot": -55, "off": (-40, 80), "head": -20, "arm": 52, "wings": 30, "leg_back": -30, "leg_front": -10, "hem": -10}),
    (1.0, {"rot": -88, "off": (-62, 158), "head": -32, "arm": 62, "wings": 44, "leg_back": -30, "leg_front": -30, "hem": -14}),
], loop=False))
anim("rest", 10, False, keyed(6, [
    (0.0, {"off": (0, 6), "sy": 0.96, "head": 6, "arm": 8, "wings": 8}),
    (1.0, {"off": (0, 46), "sy": 0.88, "head": 20, "arm": 24, "wings": 44, "leg_back": -40, "leg_front": 50, "hem": -8, "hem_skew": 10}),
], loop=False))


# --- ataques mientras corre: el torso ataca y las piernas siguen el ciclo de correr
def calm_root(name, factor=0.45):
    """Achica el adelantamiento del cuerpo en los ataques (que no parezca que se desliza)."""
    for pose in ANIMS[name]["poses"]:
        o = pose.get("off", (0, 0))
        pose["off"] = (o[0] * factor, o[1])


def with_run(name):
    base = ANIMS[name]["poses"]
    run = ANIMS["run"]["poses"]
    out = []
    for i, p in enumerate(base):
        q = dict(p)
        r = run[i % len(run)]
        for k in ("leg_back", "leg_front", "leg_back_off", "leg_front_off"):
            if k in r:
                q[k] = r[k]
        q["off"] = (p.get("off", (0, 0))[0] * 0.6, r.get("off", (0, 0))[1])
        q["hem"] = p.get("hem", 0) * 0.4 + r.get("hem", 0) * 0.8
        q["hem_skew"] = p.get("hem_skew", 0) * 0.4 + r.get("hem_skew", 0) * 0.8
        q["rot"] = p.get("rot", 0) * 0.6 + 5
        out.append(q)
    anim(name + "_run", ANIMS[name]["fps"], False, out)


for _n in ("attack", "attack2", "zarpazo"):
    calm_root(_n)
    with_run(_n)


def build_all():
    global PALETTE
    PALETTE = build_palette({})
    meta = {"frame_w": FW, "frame_h": FH, "anchor": [ANCHOR[0] * S, ANCHOR[1] * S], "hip_to_feet": (CHAR_H - HIP[1]) * S,
            "anims": {}}
    for name, a in ANIMS.items():
        frames = [frame(p) for p in a["poses"]]
        strip = Image.new("RGBA", (FW * len(frames), FH), (0, 0, 0, 0))
        for i, f in enumerate(frames):
            strip.alpha_composite(f, (i * FW, 0))
        strip.save(f"{OUT}/{name}.png")
        meta["anims"][name] = {"frames": len(frames), "fps": a["fps"], "loop": a["loop"]}
        print(name, len(frames))
    json.dump(meta, open(f"{OUT}/frames.json", "w"), indent=1)


def preview(names):
    global PALETTE
    PALETTE = build_palette({})
    rows = []
    for name in names:
        fr = [frame(p) for p in ANIMS[name]["poses"]]
        cw = 90
        row = Image.new("RGBA", (cw * len(fr), FH), (34, 38, 50, 255))
        for i, f in enumerate(fr):
            row.alpha_composite(f.crop((FW // 2 - 45, 0, FW // 2 + 45, FH)), (i * cw, 0))
        rows.append(row)
    w = max(r.width for r in rows)
    sheet = Image.new("RGBA", (w, FH * len(rows)), (34, 38, 50, 255))
    for i, r in enumerate(rows):
        sheet.alpha_composite(r, (0, i * FH))
    bb = sheet.getbbox()
    sheet = sheet.resize((sheet.width * 5, sheet.height * 5), Image.NEAREST)
    sheet.save(f"{OUT}/preview.png")


if __name__ == "__main__":
    if len(sys.argv) > 3:
        preview(sys.argv[3].split(","))
    else:
        build_all()
