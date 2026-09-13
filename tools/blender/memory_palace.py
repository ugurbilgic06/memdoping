#!/usr/bin/env python3
"""
memory_palace.py — MemDoping V2 · PACER R / Method of Loci

Blender'ı açmadan, komut satırından hafıza sarayı odasını üretir ve .usdz
olarak dışa aktarır. Tıklamalı üretimin aksine deterministik: aynı komut
her zaman aynı çıktıyı verir, sürüm kontrolüne girer, tekrar çalıştırılabilir.

Kullanım:
    blender -b -P tools/blender/memory_palace.py -- \
        --out MemDoping/MemDoping/Resources/Models/palace_home.usdz \
        --route home

Notlar:
  * `-b` arayüzsüz (background) çalıştırır — Blender penceresi açılmaz.
  * `--` sonrası argümanlar Blender'a değil bu script'e gider.
  * Durak adları Content.swift içindeki SampleContent.home rotasıyla
    BİREBİR aynıdır. Değiştirirseniz iki tarafı birlikte değiştirin,
    yoksa LociSession durakları eşleştiremez.

Bütçe (docs/v2/V2_FAZ3_Uretim.md §3.2):
    ≤ 50.000 üçgen · ≤ 4 doku (2048²) · 60 FPS hedefi · iPhone 12 alt sınır
Script çıkışta üçgen sayısını yazdırır ve bütçeyi aşarsa hata kodu döner.
"""

import bpy
import bmesh
import sys
import os
import math
import argparse

# ─────────────────────────────────────────────────────────────────────────────
# Rotalar — Content.swift'teki MemoryRoute tanımlarıyla eşleşmeli
# (icon alanı burada yok; o tarafta emoji olarak duruyor)
# ─────────────────────────────────────────────────────────────────────────────

# Dikkat — iki isim alanı var:
#   · USD nesne adı (aşağıdaki ilk sütun): boşluksuz, kod tarafının aradığı kimlik
#   · Görünen ad (Content.swift'teki RouteStop.name): boşluklu, oyuncunun gördüğü
# Tek fark "FrontDoor" ↔ "Front door". Swift tarafında eşleme yaparken
# boşlukları silip karşılaştırın, ya da aşağıdaki tabloyu referans alın:
#
#   FrontDoor → "Front door"        Bed     → "Bed"
#   Couch     → "Couch"             Plant   → "Plant"
#   Window    → "Window"            Shower  → "Shower"
#   Table     → "Table"             TV      → "TV"

ROUTES = {
    "home": [
        # (USD adı, x, y, yükseklik, tip)
        ("FrontDoor", -3.2,  3.6, 1.05, "door"),
        ("Couch",     -2.4,  1.0, 0.42, "block"),
        ("Window",    -3.45, -1.2, 1.35, "panel"),
        ("Table",      0.0, -0.4, 0.72, "table"),
        ("Bed",        2.5, -2.3, 0.50, "block"),
        ("Plant",      3.3,  1.4, 0.85, "plant"),
        ("Shower",     3.4,  3.3, 1.10, "panel"),
        ("TV",        -0.6,  3.5, 1.15, "panel"),
    ],
}

ROOM_W, ROOM_D, ROOM_H = 8.0, 8.0, 2.7
WALL_T = 0.12

# Brand paleti (Views/Components.swift) — sıcak krem / yosun dünyası
PALETTE = {
    "floor":   (0.78, 0.70, 0.55, 1.0),
    "wall":    (0.93, 0.90, 0.83, 1.0),
    "station": (0.46, 0.60, 0.30, 1.0),   # Brand.accent
    "accent":  (0.55, 0.45, 0.28, 1.0),   # Brand.primary
}

TRI_BUDGET = 50_000


# ─────────────────────────────────────────────────────────────────────────────

def default_out():
    """
    Arayüzden çalıştırıldığında (Blender > Scripting > Run) argüman gelmez.
    O durumda çıktıyı proje ağacındaki doğru yere yazarız: bu dosya
    <proje>/tools/blender/ içinde durduğu için iki üst klasör projenin kökü.
    """
    # Blender'da __file__ her zaman tanımlı değildir (text-block olarak
    # çalıştırılırsa yok), bpy.data.filepath da .blend kaydedilmemişse boştur.
    # Üçünü sırayla dener, hiçbiri tutmazsa bilinen proje yoluna düşeriz.
    seed = ""
    try:
        seed = bpy.data.filepath or ""
    except Exception:
        pass
    if not seed:
        seed = globals().get("__file__", "") or ""
    probe = os.path.dirname(os.path.abspath(seed)) if seed \
        else os.path.expanduser("~/Desktop/memdoping")
    for _ in range(5):
        if os.path.isdir(os.path.join(probe, "MemDoping", "MemDoping")):
            break
        probe = os.path.dirname(probe)
    else:
        probe = os.path.expanduser("~/Desktop/memdoping")
    return os.path.join(probe, "MemDoping", "MemDoping",
                        "Resources", "Models", "palace_home.usdz")


def parse_args():
    argv = sys.argv
    has_sep = "--" in argv
    argv = argv[argv.index("--") + 1:] if has_sep else []
    p = argparse.ArgumentParser(description="MemDoping hafıza sarayı üreteci")
    # Arayüzden çalıştırmayı desteklemek için --out zorunlu değil.
    p.add_argument("--out", default=None, help="Çıktı .usdz yolu")
    p.add_argument("--route", default="home", choices=sorted(ROUTES),
                   help="Üretilecek rota")
    p.add_argument("--no-check", action="store_true",
                   help="Üçgen bütçesi kontrolünü atla")
    args = p.parse_args(argv)
    if not args.out:
        args.out = default_out()
        print(f"[MemDoping] Argüman yok — varsayılan çıktı: {args.out}")
    return args


def clear_scene():
    """Varsayılan küp/kamera/ışık dahil her şeyi siler."""
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras,
                  bpy.data.lights):
        for item in list(block):
            if item.users == 0:
                block.remove(item)


def make_material(name, rgba, roughness=0.72):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
    return mat


def add_box(name, size, location, material):
    """Tek bir kutu ekler (12 üçgen). Primitiflerle kalmak bütçeyi korur."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2.0, size[1] / 2.0, size[2] / 2.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(material)
    return ob


def add_cylinder(name, radius, depth, location, material, verts=12):
    """Düşük segmentli silindir — yuvarlaklık pahalıdır, 12 yeter."""
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=depth, location=location, vertices=verts)
    ob = bpy.context.active_object
    ob.name = name
    ob.data.materials.append(material)
    return ob


def build_room(mats):
    """Zemin + dört duvar. Tavan yok: oyuncu yukarıdan bakıyor."""
    add_box("Floor", (ROOM_W, ROOM_D, 0.1), (0, 0, -0.05), mats["floor"])
    half_w, half_d = ROOM_W / 2, ROOM_D / 2
    walls = [
        ("Wall_N", (ROOM_W, WALL_T, ROOM_H), (0,  half_d, ROOM_H / 2)),
        ("Wall_S", (ROOM_W, WALL_T, ROOM_H), (0, -half_d, ROOM_H / 2)),
        ("Wall_E", (WALL_T, ROOM_D, ROOM_H), ( half_w, 0, ROOM_H / 2)),
        ("Wall_W", (WALL_T, ROOM_D, ROOM_H), (-half_w, 0, ROOM_H / 2)),
    ]
    for name, size, loc in walls:
        add_box(name, size, loc, mats["wall"])


def build_station(index, name, x, y, h, kind, mats):
    """
    Her durak bir 'Station_NN_Ad' boşluğu (empty) ve basit bir gövdeden oluşur.
    Boşluk, Swift tarafının öğeyi konumlandıracağı ankraj noktasıdır —
    gövde değişse bile ankraj sabit kalır.
    """
    body_name = f"Body_{index:02d}_{name}"
    if kind == "door":
        add_box(body_name, (0.95, 0.1, 2.05), (x, y, 1.02), mats["accent"])
    elif kind == "panel":
        add_box(body_name, (1.25, 0.1, 1.0), (x, y, h), mats["accent"])
    elif kind == "table":
        add_box(body_name, (1.35, 0.85, 0.07), (x, y, h), mats["accent"])
        for dx in (-0.55, 0.55):
            for dy in (-0.32, 0.32):
                add_box(f"{body_name}_Leg_{dx}_{dy}", (0.08, 0.08, h),
                        (x + dx, y + dy, h / 2), mats["accent"])
    elif kind == "plant":
        add_cylinder(f"{body_name}_Pot", 0.26, 0.42, (x, y, 0.21), mats["accent"])
        add_cylinder(f"{body_name}_Stem", 0.08, h, (x, y, 0.42 + h / 2),
                     mats["station"], verts=8)
    else:  # block
        add_box(body_name, (1.5, 0.75, h), (x, y, h / 2), mats["accent"])

    # Ankraj — Swift bu adı arayacak
    anchor = bpy.data.objects.new(f"Station_{index:02d}_{name}", None)
    anchor.empty_display_type = "PLAIN_AXES"
    anchor.empty_display_size = 0.25
    anchor.location = (x, y, h + 0.35)
    bpy.context.collection.objects.link(anchor)

    # Görünür işaretçi — öğenin bırakıldığı yer
    marker = add_cylinder(f"Marker_{index:02d}_{name}", 0.17, 0.05,
                          (x, y, h + 0.06), mats["station"], verts=10)
    marker.parent = anchor


def triangle_count():
    total = 0
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for ob in bpy.context.scene.objects:
        if ob.type != "MESH":
            continue
        mesh = ob.evaluated_get(depsgraph).to_mesh()
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        total += len(bm.faces)
        bm.free()
        ob.evaluated_get(depsgraph).to_mesh_clear()
    return total


def export_usdz(path):
    """
    USD dışa aktarma operatörünün parametreleri Blender sürümleri arasında
    değişiyor (5.2'de 'export_textures' kaldırıldı). Sabit bir liste göndermek
    yerine operatöre neyi kabul ettiğini soruyoruz ve yalnızca desteklenenleri
    geçiyoruz — böyle her sürümde çalışır.
    """
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)

    wanted = {
        "filepath": path,
        "export_materials": True,
        "export_textures": True,
        "selected_objects_only": False,
        "visible_objects_only": False,
        "export_normals": True,
        "export_uvmaps": True,
        "evaluation_mode": "RENDER",
        "generate_preview_surface": True,
    }

    try:
        supported = set(bpy.ops.wm.usd_export.get_rna_type().properties.keys())
    except Exception:
        supported = {"filepath"}

    kwargs = {k: v for k, v in wanted.items() if k in supported}
    dropped = sorted(set(wanted) - set(kwargs))
    if dropped:
        print(f"[MemDoping] Bu sürümde desteklenmeyen seçenekler atlandı: {dropped}")

    bpy.ops.wm.usd_export(**kwargs)

    # Doğrulama kopyası: .usda düz metindir, sürüm kontrolünde okunabilir ve
    # ankrajların gerçekten dışa aktarıldığını gözle/script'le denetlenebilir
    # kılar. Oyun .usdz'yi kullanır; bu dosya yalnızca denetim içindir.
    ascii_path = os.path.splitext(path)[0] + ".usda"
    ascii_kwargs = dict(kwargs)
    ascii_kwargs["filepath"] = ascii_path
    try:
        bpy.ops.wm.usd_export(**ascii_kwargs)
        print(f"[MemDoping] Doğrulama kopyası: {ascii_path}")
    except Exception as e:
        print(f"[MemDoping] .usda yazılamadı (kritik değil): {e}")


def main():
    args = parse_args()
    route = ROUTES[args.route]

    print(f"\n[MemDoping] Rota: {args.route} · {len(route)} durak")
    clear_scene()

    mats = {k: make_material(f"MD_{k}", v) for k, v in PALETTE.items()}
    build_room(mats)
    for i, (name, x, y, h, kind) in enumerate(route, start=1):
        build_station(i, name, x, y, h, kind, mats)
        print(f"  · Station_{i:02d}_{name}")

    tris = triangle_count()
    print(f"\n[MemDoping] Üçgen: {tris:,} / {TRI_BUDGET:,} bütçe")
    print(f"[MemDoping] Materyal: {len(mats)} (doku dosyası yok — düz renk)")

    if tris > TRI_BUDGET and not args.no_check:
        print(f"[MemDoping] HATA: bütçe aşıldı. --no-check ile zorlayabilirsiniz.")
        sys.exit(1)

    export_usdz(args.out)
    size_kb = os.path.getsize(args.out) / 1024 if os.path.exists(args.out) else 0
    print(f"[MemDoping] Yazıldı: {args.out} ({size_kb:.0f} KB)\n")


if __name__ == "__main__":
    main()
