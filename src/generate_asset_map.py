import os
import json

assets_dir = 'assets/'  
output_file = 'lib/asset_map.dart'  


asset_map = {}
for filename in os.listdir(assets_dir):
    if filename.endswith('.png'):
        lowercase_key = filename.lower().replace('.png', '')
        asset_map[lowercase_key] = filename.replace('.png', '')


dart_code = f'''
// AUTO-GENERATED FILE. DO NOT EDIT.
final Map<String, String> assetMap = {{
  {', '.join([f'"{k}": "{v}"' for k, v in asset_map.items()])}
}};
'''

with open(output_file, 'w') as f:
    f.write(dart_code)