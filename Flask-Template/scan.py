import os
import sys
from pathlib import Path
import pathspec


def read_ignore_file(ignore_file_path):
    if ignore_file_path.exists():
        with open(ignore_file_path, 'r', encoding='utf-8') as file:
            return pathspec.PathSpec.from_lines('gitwildmatch', file)
    else:
        return pathspec.PathSpec.from_lines('gitwildmatch', [])


def main(target_dir):
    target_dir = Path(target_dir).resolve()
    output_file = target_dir / "output.md"
    ignore_file = target_dir / ".structureignore.txt"
    markdown_content = ""

    ignorer = read_ignore_file(ignore_file)

    for root, dirs, files in os.walk(target_dir):
        dirs[:] = [d for d in dirs if not ignorer.match_file(
            os.path.join(root, d))]
        for file in files:
            file_path = Path(root) / file
            relative_path = file_path.relative_to(target_dir)
            if ignorer.match_file(str(relative_path)):
                continue

            try:
                with open(file_path, 'r', encoding='utf-8') as file:
                    data = file.read()
                if not data:
                    markdown_content += f"### {relative_path}:\n<EMPTY>\n"
                else:
                    markdown_content += f"### {
                        relative_path}:\n{data}\n"
            except Exception as e:
                print(f"Error reading file: {file_path} - {e}")

    with open(output_file, 'w', encoding='utf-8') as file:
        file.write(markdown_content)
    print(f"Markdown file created: {output_file}")


if __name__ == "__main__":
    target_directory = sys.argv[1] if len(sys.argv) > 1 else "."
    main(target_directory)
