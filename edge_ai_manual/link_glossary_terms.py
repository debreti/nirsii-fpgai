#!/usr/bin/env python3
"""
Script to add glossary hyperlinks to the first use of each term in chapter files.
Only the first occurrence of each term in each chapter will have a hyperlink.
All other occurrences (including existing redundant links) will be plain text.
"""

import re
import os
from pathlib import Path
from typing import Dict

def extract_glossary_terms(glossary_path: str) -> Dict[str, str]:
    """
    Extract glossary terms and their anchors from glossary.md.
    Returns a dictionary mapping term to anchor name.
    More robust: matches table rows starting with '|' and captures **term**
    and any <a name="..."></a> that appears in the same table cell.
    """
    terms = {}

    with open(glossary_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match table rows where first cell contains **Term** and optionally an <a name="..."></a>
    # Use multiline so ^ matches line starts, allow spaces before closing pipe.
    row_pattern = r'^\|\s*\*\*(?P<term>.+?)\*\*\s*(?P<cell>.*?)\|\s*$'
    for m in re.finditer(row_pattern, content, re.MULTILINE):
        term = m.group('term').strip()
        cell = m.group('cell')
        # find anchor inside the same cell if present
        anchor_match = re.search(r'<a\s+name="([^"]+)"></a>', cell)
        if anchor_match:
            anchor = anchor_match.group(1).strip()
            if term and anchor:
                terms[term] = anchor

    return terms

def process_chapter(chapter_path: str, terms: Dict[str, str]) -> str:
    """
    Process a chapter file and add glossary links.
    Only the first occurrence of each term gets a link.
    All other occurrences (including existing links) are converted to plain text.
    Returns the modified content.
    """
    
    with open(chapter_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Sort terms by length (longest first) to avoid partial matches
    sorted_terms = sorted(terms.items(), key=lambda x: len(x[0]), reverse=True)
    
    for term, anchor in sorted_terms:
        escaped_term = re.escape(term)
        
        # First, remove all existing links to this term from glossary
        link_pattern = r'\[' + escaped_term + r'\]\(glossary\.md#' + re.escape(anchor) + r'\)'
        content = re.sub(link_pattern, term, content)
        
        # Now find all occurrences of the plain term (not in headers)
        # Split content into lines to check for headers
        lines = content.split('\n')
        modifications = []
        char_pos = 0
        first_occurrence_found = False
        
        for line_idx, line in enumerate(lines):
            # Skip headers (lines starting with #)
            if line.lstrip().startswith('#'):
                char_pos += len(line) + 1
                continue
            
            # Find all occurrences in this line
            pattern = r'\b' + escaped_term + r'\b'
            
            for match in re.finditer(pattern, line):
                if not first_occurrence_found:
                    # This is the first occurrence - mark it for linking
                    start = char_pos + match.start()
                    end = char_pos + match.end()
                    modifications.append((start, end, f'[{term}](glossary.md#{anchor})'))
                    first_occurrence_found = True
                # Other occurrences stay as plain text (no modification needed)
            
            char_pos += len(line) + 1
        
        # Apply modifications from end to start to preserve positions
        for start, end, replacement in reversed(modifications):
            content = content[:start] + replacement + content[end:]
    
    return content

def process_all_chapters(base_dir: str, glossary_file: str = 'glossary.md') -> None:
    """
    Process all ch*.md files in the given directory.
    """
    # Extract terms from glossary
    glossary_path = os.path.join(base_dir, glossary_file)
    
    if not os.path.exists(glossary_path):
        print(f"Error: Glossary file not found at {glossary_path}")
        return
    
    terms = extract_glossary_terms(glossary_path)
    
    if not terms:
        print("Warning: No terms found in glossary")
        return
    
    print(f"Found {len(terms)} terms in glossary:")
    for term, anchor in sorted(terms.items()):
        print(f"  - {term} (#{anchor})")
    print()
    
    # Find all chapter files
    chapter_files = sorted(Path(base_dir).glob('ch*.md'))
    
    if not chapter_files:
        print("Warning: No chapter files (ch*.md) found")
        return
    
    # Process each chapter
    for chapter_path in chapter_files:
        chapter_name = chapter_path.name
        print(f"Processing {chapter_name}...")
        
        original_content = chapter_path.read_text(encoding='utf-8')
        modified_content = process_chapter(str(chapter_path), terms)
        
        if original_content != modified_content:
            chapter_path.write_text(modified_content, encoding='utf-8')
            print(f"  ✓ Updated {chapter_name}")
        else:
            print(f"  - No changes needed for {chapter_name}")
    
    print("\nDone!")

if __name__ == '__main__':
    # Get the chapters directory (one level down from where script is)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    chapters_dir = os.path.join(script_dir, 'chapters')
    
    # If script is already in chapters dir, use current dir
    if os.path.basename(script_dir) == 'chapters':
        chapters_dir = script_dir
    
    process_all_chapters(chapters_dir)
