import os
import json

ROOMS_DIR = 'd:/GAME Project/thi_tran_vui_Ve/assets/rooms'
OUTPUT_DIR = 'd:/GAME Project/thi_tran_vui_Ve/game/world/rooms'
os.makedirs(OUTPUT_DIR, exist_ok=True)

for room_name in os.listdir(ROOMS_DIR):
    room_path = os.path.join(ROOMS_DIR, room_name)
    if not os.path.isdir(room_path):
        continue
        
    layout_file = os.path.join(room_path, 'layout.json')
    if not os.path.exists(layout_file):
        continue
        
    with open(layout_file, 'r', encoding='utf-8') as f:
        layout = json.load(f)
        
    tscn_path = os.path.join(OUTPUT_DIR, f'{room_name.capitalize()}.tscn')
    
    resources = []
    nodes = []
    
    # Background
    bg_path = f'res://assets/rooms/{room_name}/assets/background/room_shell.png'
    resources.append((bg_path, 'Texture'))
    nodes.append(f'[node name=\"{room_name.capitalize()}\" type=\"Node2D\"]\n')
    nodes.append(f'[node name=\"Background\" type=\"Sprite\" parent=\".\"]\ntexture = ExtResource( 1 )\ncentered = false\n')
    nodes.append(f'[node name=\"YSort\" type=\"YSort\" parent=\".\"]\n')
    
    for inst in layout.get('instances', []):
        inst_id = inst['instance_id']
        asset_id = inst['asset_id']
        direction = inst.get('direction', 'down')
        pos = inst['position_px']
        
        # Check files
        tex_path = f'res://assets/rooms/{room_name}/assets/furniture/{asset_id}/frames/{asset_id}_{direction}.png'
        real_path = tex_path.replace('res://', 'd:/GAME Project/thi_tran_vui_Ve/')
        if not os.path.exists(real_path):
            tex_path = f'res://assets/rooms/{room_name}/assets/furniture/{asset_id}/frames/{asset_id}.png'
            real_path = tex_path.replace('res://', 'd:/GAME Project/thi_tran_vui_Ve/')
            if not os.path.exists(real_path):
                frames_dir = os.path.dirname(real_path)
                if os.path.exists(frames_dir) and os.listdir(frames_dir):
                    first_file = [f for f in os.listdir(frames_dir) if f.endswith('.png')][0]
                    tex_path = f'res://assets/rooms/{room_name}/assets/furniture/{asset_id}/frames/{first_file}'
        
        if tex_path not in [r[0] for r in resources]:
            resources.append((tex_path, 'Texture'))
            
        res_id = [r[0] for r in resources].index(tex_path) + 1
        
        nodes.append(f'[node name=\"{inst_id}\" type=\"Sprite\" parent=\"YSort\"]\nposition = Vector2( {pos[0]}, {pos[1]} )\ntexture = ExtResource( {res_id} )\n')
        
    with open(tscn_path, 'w', encoding='utf-8') as f:
        f.write(f'[gd_scene load_steps={len(resources)+1} format=2]\n\n')
        for i, res in enumerate(resources):
            f.write(f'[ext_resource path=\"{res[0]}\" type=\"Texture\" id={i+1}]\n')
        f.write('\n')
        for node in nodes:
            f.write(node + '\n')
            
    print(f'Generated {room_name.capitalize()}.tscn')
