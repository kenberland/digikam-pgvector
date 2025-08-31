import argparse
import mysql.connector
from urllib.parse import urlparse
import os

BASE_DIR = "/mnt/backup-3"
GET_REFERENCE_IMAGES = """
SELECT
    CONCAT(AR.specificPath, A.relativePath, '/', I.name) AS fullPath
FROM Images AS I
JOIN Albums AS A ON I.album = A.id
JOIN AlbumRoots AS AR ON A.albumRoot = AR.id
WHERE I.dedupReason = 'reference-image'
"""

# --- Main Logic ---


def main():
    parser = argparse.ArgumentParser(
        description="Generate a script to move reference images to a new location."
    )
    parser.add_argument(
        "--mirror-location",
        required=True,
        help="The root directory to mirror the images to.",
    )
    parser.add_argument(
        "--mysql-conn-str", required=True, help="MySQL connection string"
    )
    parser.add_argument(
        "--output-script",
        default="move-reference-images.py.sh",
        help="Name of the output script",
    )
    args = parser.parse_args()

    # --- Database Connection ---
    mysql_url = urlparse(args.mysql_conn_str)

    mysql_conn = mysql.connector.connect(
        host=mysql_url.hostname,
        user=mysql_url.username,
        password=mysql_url.password,
        database=mysql_url.path[1:],
    )
    cursor = mysql_conn.cursor()

    # --- Main Processing ---
    cursor.execute(GET_REFERENCE_IMAGES)

    created_dirs = set()
    output_lines = [
        "#!/bin/bash",
        "# Script to move reference images to a new mirrored location.",
        "",
    ]

    for (original_path,) in cursor:
        # Sanitize the path from the database to create a valid relative path
        # This removes any leading slash to prevent os.path.join from treating it as an absolute path.
        if original_path.startswith("/"):
            relative_path = original_path[1:]
        else:
            relative_path = original_path

        new_path = os.path.join(args.mirror_location, relative_path)
        new_dir = os.path.dirname(new_path)

        if new_dir not in created_dirs:
            output_lines.append(f'mkdir -p "{new_dir}"')
            created_dirs.add(new_dir)

        output_lines.append(f'mv "{BASE_DIR + original_path}" "{new_path}"')

    cursor.close()

    # --- Write Output Script ---
    with open(args.output_script, "w") as f:
        for line in output_lines:
            f.write(f"{line}\n")

    os.chmod(args.output_script, 0o755)  # Make the script executable

    print(f"\nDone. Move script written to '{args.output_script}'")
    print(f"Found {len(output_lines) - 3} reference images to move.")


if __name__ == "__main__":
    main()
