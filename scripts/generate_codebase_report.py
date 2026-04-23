#!/usr/bin/env python3
"""
Generate a file-by-file audit and append entries to CODEBASE_REFACTOR_TRACKER.md
Usage: python scripts/generate_codebase_report.py --output CODEBASE_REFACTOR_TRACKER.md
"""
import os
import re
import sys
import argparse
import datetime

def is_binary_file(path):
    try:
        with open(path, 'rb') as f:
            chunk = f.read(1024)
            if b'\0' in chunk:
                return True
            return False
    except Exception:
        return True

def read_text_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception:
        try:
            with open(path, 'r', encoding='latin-1') as f:
                return f.read()
        except Exception:
            return None

def categorize(relpath):
    if relpath.startswith('lib/') or relpath == 'lib':
        return 'Dart source'
    if relpath.startswith('android/'):
        return 'Android platform'
    if relpath.startswith('ios/'):
        return 'iOS platform'
    if relpath.startswith('assets/'):
        return 'Assets'
    if relpath.startswith('test/'):
        return 'Tests'
    if relpath.startswith('scripts/'):
        return 'Scripts'
    if relpath.startswith('build/') or '/build/' in relpath:
        return 'Build/Generated'
    if relpath.endswith(('.yaml', '.yml')):
        return 'Config'
    if relpath.startswith('web/'):
        return 'Web'
    if relpath.startswith('macos/'):
        return 'macOS'
    if relpath.startswith('windows/'):
        return 'Windows'
    if relpath.startswith('linux/'):
        return 'Linux'
    if relpath.startswith('docs/'):
        return 'Docs'
    return 'Other'

def detect_issues(relpath, fullpath, text, size):
    issues = []
    notes = []
    if text is None:
        issues.append('Binary or unreadable file (skipping content checks)')
        return issues, notes
    if re.search(r'\bprint\s*\(', text):
        issues.append('Raw `print()` logging (use shared AppLogger)')
    if 'TODO' in text or 'FIXME' in text:
        issues.append('Contains TODO/FIXME markers')
    if 'ScaffoldMessenger.of(' in text or 'Scaffold.of(' in text:
        issues.append('Direct scaffold usage for messages (centralize via AppSnackBar)')
    if re.search(r'\bhttp\.(get|post|put|delete)\s*\(', text) or 'http.Client' in text:
        issues.append('Direct HTTP calls (prefer `ApiClient`)')
    if 'google-services.json' in relpath or 'google-services.json' in text:
        issues.append('Firebase config file present (ensure no secrets committed)')
    if 'key.properties' in relpath or 'keystore' in relpath or 'storeFile' in text or 'storePassword' in text:
        issues.append('Keystore/key properties present (sensitive) — move to secure storage')
    if re.search(r'password|api_key|apiKey|secret', text, re.I):
        notes.append('Possible secret-like strings found (manual review recommended)')
    if size > 200*1024:
        notes.append('Large file (likely generated or binary)')
    if relpath.endswith(('.gradle', '.gradle.kts')):
        if 'signingConfigs' in text or 'storeFile' in text:
            issues.append('Gradle signing config found (check for committed keystore paths)')
    if os.path.basename(relpath) in ('pubspec.yaml', 'pubspec.yml'):
        deps = []
        for line in text.splitlines():
            m = re.match(r'\s*([a-zA-Z0-9_\-]+):\s*(.*)', line)
            if m:
                key = m.group(1)
                val = m.group(2).strip()
                # crude filter to list top-level dependency keys
                if key and not line.startswith('  '):
                    if key not in ('name','description','version','environment','flutter'):
                        deps.append(key)
        if deps:
            notes.append(f'Dependencies detected: {", ".join(deps)}')
    return issues, notes

def risk_level(issues, notes):
    if any('keystore' in s.lower() or 'firebase' in s.lower() or 'secret' in ' '.join(notes).lower() for s in issues):
        return 'High'
    if issues:
        return 'Medium'
    if notes:
        return 'Low'
    return 'Low'

def purpose_from_extension(relpath):
    ext = os.path.splitext(relpath)[1].lower()
    if ext == '.dart':
        return 'Flutter/Dart source file'
    if ext in ('.kt', '.kts', '.gradle'):
        return 'Android build script / Kotlin'
    if ext in ('.yaml', '.yml'):
        return 'Configuration / manifest'
    if ext == '.json':
        return 'JSON data/config'
    if ext in ('.png', '.jpg', '.jpeg', '.webp', '.ico'):
        return 'Image asset'
    if ext == '.xml':
        return 'Configuration / Android XML'
    return 'File'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='.', help='Repository root')
    parser.add_argument('--output', default='CODEBASE_REFACTOR_TRACKER.md', help='Tracker file to append to')
    args = parser.parse_args()
    root = os.path.abspath(args.root)
    collected = []
    for dirpath, dirnames, filenames in os.walk(root):
        rel_dir = os.path.relpath(dirpath, root)
        # skip common metadata dirs
        if rel_dir.startswith('.git') or rel_dir.startswith('.idea') or rel_dir.startswith('.vscode'):
            continue
        for fn in filenames:
            relpath = os.path.normpath(os.path.join(rel_dir, fn)) if rel_dir != '.' else fn
            relpath = relpath.replace('\\','/')
            fullpath = os.path.join(dirpath, fn)
            # Skip the tracker itself to avoid recursion
            if os.path.normpath(relpath) == os.path.normpath(os.path.basename(args.output)):
                continue
            try:
                size = os.path.getsize(fullpath)
            except Exception:
                size = 0
            text = None
            if not is_binary_file(fullpath):
                text = read_text_file(fullpath)
            collected.append((relpath, fullpath, text, size))
    timestamp = datetime.datetime.utcnow().isoformat() + 'Z'
    report_lines = []
    report_lines.append('\n\n## 3. Full File Inventory Audit (Auto-generated)')
    report_lines.append(f'- Generated: {timestamp}\n')
    report_lines.append('The following entries were produced by an automated scan. Each entry contains: category, purpose, status, issues found, recommended action, risk level, and notes.\n')
    for relpath, fullpath, text, size in sorted(collected, key=lambda x: x[0]):
        category = categorize(relpath)
        purpose = purpose_from_extension(relpath)
        issues, notes = detect_issues(relpath, fullpath, text, size)
        rl = risk_level(issues, notes)
        report_lines.append(f'### {relpath}\n')
        report_lines.append(f'- **Category**: {category}')
        report_lines.append(f'- **Purpose**: {purpose}')
        report_lines.append(f'- **Status**: Scanned')
        if issues:
            report_lines.append(f'- **Issues found**: {"; ".join(issues)}')
        else:
            report_lines.append(f'- **Issues found**: None')
        recs = []
        if any('Raw `print()` logging' in s for s in issues):
            recs.append('Replace `print` calls with `AppLogger`')
        if any('Direct HTTP calls' in s for s in issues):
            recs.append('Route networking through `ApiClient`')
        if any('Scaffold' in s for s in issues):
            recs.append('Use centralized `AppSnackBar`/messaging utilities')
        if any('keystore' in s.lower() or 'Keystore' in s for s in issues):
            recs.append('Remove keystore from repo; load from CI secrets or local excluded path')
        if any('Firebase' in s for s in issues):
            recs.append('Ensure `google-services.json` is not leaking sensitive keys in VCS')
        if not recs:
            recs.append('NO CHANGE')
        report_lines.append(f'- **Recommended action**: {"; ".join(recs)}')
        report_lines.append(f'- **Risk level**: {rl}')
        if notes:
            report_lines.append(f'- **Dependencies/Notes**: {"; ".join(notes)}')
        else:
            report_lines.append(f'- **Dependencies/Notes**: None')
        report_lines.append('')
    outpath = os.path.join(root, args.output)
    try:
        with open(outpath, 'a', encoding='utf-8') as f:
            f.write('\n'.join(report_lines))
        print(f'Appended audit for {len(collected)} files to {args.output}')
    except Exception as e:
        print('Failed to write output file:', e, file=sys.stderr)
        sys.exit(2)

if __name__ == '__main__':
    main()
