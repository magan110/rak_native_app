import json
from pathlib import Path
from graphify.extract import collect_files, extract

detect = json.loads(Path('graphify-out/.graphify_detect.json').read_text())
# Normalize paths and filter for lib/
all_files = [f.replace('\\','/') for files in detect.get('files', {}).values() for f in files]
code_files = [f for f in all_files if f.startswith('lib/')]
code_paths = []
for f in code_files:
    p = Path(f)
    if p.exists():
        code_paths.extend(collect_files(p) if p.is_dir() else [p])
    else:
        # try with workspace root
        p2 = Path('.') / f
        if p2.exists():
            code_paths.extend(collect_files(p2) if p2.is_dir() else [p2])

if code_paths:
    result = extract(code_paths)
    Path('graphify-out/.graphify_ast.json').write_text(json.dumps(result, indent=2))
    print('AST: {} nodes, {} edges'.format(len(result.get('nodes',[])), len(result.get('edges',[]))))
else:
    Path('graphify-out/.graphify_ast.json').write_text(json.dumps({'nodes':[],'edges':[],'input_tokens':0,'output_tokens':0}))
    print('No code files found under lib/')
