import json
from graphify.detect import detect
from pathlib import Path
from graphify.extract import collect_files, extract

detect = json.loads(Path('graphify-out/.graphify_detect.json').read_text())
# Filter files to lib/
files = {k:[f for f in v if f.startswith('lib/')] for k,v in detect.get('files',{}).items()}
code_files = files.get('code', [])
code_paths = []
for f in code_files:
    p = Path(f)
    code_paths.extend(collect_files(p) if p.is_dir() else [p])
if code_paths:
    result = extract(code_paths)
    Path('graphify-out/.graphify_ast.json').write_text(json.dumps(result, indent=2))
    print('AST: {} nodes, {} edges'.format(len(result.get('nodes',[])), len(result.get('edges',[]))))
else:
    Path('graphify-out/.graphify_ast.json').write_text(json.dumps({'nodes':[],'edges':[],'input_tokens':0,'output_tokens':0}))
    print('No code files - skipping AST extraction')
