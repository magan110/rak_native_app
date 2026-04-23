import json
from graphify.build import build_from_json
from graphify.cluster import cluster
from graphify.analyze import god_nodes, surprising_connections
from graphify.report import generate
from pathlib import Path

try:
    detect_raw = json.loads(Path('graphify-out/.graphify_detect.json').read_text())
except Exception:
    detect_raw = {}

detection_result = {
    'files': detect_raw.get('files', {}),
    'total_files': sum(len(v) for v in detect_raw.get('files', {}).values()) if detect_raw.get('files') else 0,
    'total_words': detect_raw.get('total_words', 0) if isinstance(detect_raw, dict) else 0,
}

extraction = json.loads(Path('graphify-out/.graphify_extract.json').read_text())
analysis = json.loads(Path('graphify-out/.graphify_analysis.json').read_text())

G = build_from_json(extraction)
communities = {int(k): v for k, v in analysis.get('communities', {}).items()}
gods = god_nodes(G)
surprises = surprising_connections(G, communities)

report = generate(G, communities, {}, {}, gods, surprises, detection_result, {'input':0,'output':0}, '.')
Path('graphify-out/GRAPH_REPORT.md').write_text(report)
print('GRAPH_REPORT.md written')
