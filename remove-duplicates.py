import argparse
import mysql.connector
import psycopg2
from urllib.parse import urlparse
from pgvector.psycopg2 import register_vector
import os
from datetime import datetime
import math
import dominate
from dominate.tags import link, div, h1, p, img, a, span, b, br

GET_ALL_IMAGE_IDS = "SELECT id FROM Images"
GET_IMAGE_VECTOR = "SELECT matrix FROM ImageHaarMatrix WHERE imageid = %s"
FIND_SIMILAR_IMAGES = (
    "SELECT imageid FROM ImageHaarMatrix WHERE imageid != %s AND matrix <-> %s < %s"
)
GET_IMAGE_DETAILS = """
SELECT
    I.id,
    CONCAT(AR.specificPath, A.relativePath, I.name) AS fullPath,
    I.fileSize,
    II.creationDate
FROM Images AS I
JOIN Albums AS A ON I.album = A.id
JOIN AlbumRoots AS AR ON A.albumRoot = AR.id
JOIN ImageInformation AS II ON I.id = II.imageid
WHERE I.id = %s
"""

CSS_STYLES = """
body { font-family: sans-serif; margin: 2em; }
.page-nav { margin-bottom: 1em; }
.duplicate-set { border: 1px solid #ccc; margin-bottom: 2em; padding: 1em; }
.image-grid { display: flex; flex-wrap: wrap; }
.image-container { margin: 1em; text-align: center; }
.image-container img {
  max-width: 200px; max-height: 200px; border: 2px solid transparent;
}
.reference-image { border-color: green !important; }
.duplicate-image { border-color: red !important; }
.caption { font-size: 0.8em; }
"""


def get_image_details(mysql_cursor, image_id):
    mysql_cursor.execute(GET_IMAGE_DETAILS, (image_id,))
    result = mysql_cursor.fetchone()
    if result:
        image_id, path, size, date = result
        return {"id": image_id, "path": path, "size": size or 0, "date": date}
    return None


def select_reference_image(image_details):
    with_date = [d for d in image_details if d["date"] is not None]
    without_date = [d for d in image_details if d["date"] is None]
    if with_date:
        with_date.sort(key=lambda x: (x["date"], -x["size"]))
        return with_date[0]
    else:
        without_date.sort(key=lambda x: -x["size"])
        return without_date[0]


def generate_html_page(duplicate_sets, page_num, total_pages, output_dir):
    doc = dominate.document(title="Duplicate Images Report")

    with doc.head:
        link(rel="stylesheet", href="style.css")

    with doc:
        h1("Duplicate Images Report")

        nav_div = div(_class="page-nav")
        if page_num > 1:
            nav_div.add(a("Previous", href=f"page-{page_num-1}.html"))
        if page_num < total_pages:
            if page_num > 1:
                nav_div.add(span(" | ", style="margin: 0 1em;"))
            nav_div.add(a("Next", href=f"page-{page_num+1}.html"))

        for duplicate_set in duplicate_sets:
            with div(_class="duplicate-set"):
                with div(_class="image-grid"):
                    ref_image = duplicate_set["reference"]
                    with div(_class="image-container"):
                        p(b("Reference (Keep)"))
                        img(src=ref_image["path"], _class="reference-image")
                        with p(_class="caption"):
                            div(ref_image["path"])
                            br()
                            div(f"Date: {ref_image['date']}")
                            br()
                            div(f"Size: {ref_image['size']} bytes")

                    for dup_image in duplicate_set["duplicates"]:
                        with div(_class="image-container"):
                            p("Duplicate (Remove)")
                            img(src=dup_image["path"], _class="duplicate-image")
                            with p(_class="caption"):
                                div(dup_image["path"])
                                br()
                                div(f"Date: {dup_image['date']}")
                                br()
                                div(f"Size: {dup_image['size']} bytes")

        nav_div_bottom = div(_class="page-nav")
        if page_num > 1:
            nav_div_bottom.add(a("Previous", href=f"page-{page_num-1}.html"))
        if page_num < total_pages:
            if page_num > 1:
                nav_div_bottom.add(span(" | ", style="margin: 0 1em;"))
            nav_div_bottom.add(a("Next", href=f"page-{page_num+1}.html"))

    with open(os.path.join(output_dir, f"page-{page_num}.html"), "w") as f:
        f.write(doc.render())


def main():
    parser = argparse.ArgumentParser(
        description="Find and generate an HTML report for duplicate images."
    )
    parser.add_argument(
        "--threshold",
        type=float,
        required=True,
        help="Similarity threshold (max L2 distance)",
    )
    parser.add_argument(
        "--mysql-conn-str", required=True, help="MySQL connection string"
    )
    parser.add_argument(
        "--postgres-conn-str", required=True, help="PostgreSQL connection string"
    )
    args = parser.parse_args()

    # --- Create Output Directory ---
    timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M")
    output_dir = f"output-{timestamp}"
    os.makedirs(output_dir, exist_ok=True)

    # --- Write CSS file ---
    with open(os.path.join(output_dir, "style.css"), "w") as f:
        f.write(CSS_STYLES)

    # --- Database Connections ---
    mysql_url = urlparse(args.mysql_conn_str)
    postgres_url = urlparse(args.postgres_conn_str)

    try:
        mysql_conn = mysql.connector.connect(
            host=mysql_url.hostname,
            user=mysql_url.username,
            password=mysql_url.password,
            database=mysql_url.path[1:],
        )
        mysql_cursor = mysql_conn.cursor()

        postgres_conn = psycopg2.connect(
            host=postgres_url.hostname,
            user=postgres_url.username,
            password=postgres_url.password,
            dbname=postgres_url.path[1:],
        )
        postgres_cursor = postgres_conn.cursor()
        register_vector(postgres_conn)

        # --- Main Processing ---
        mysql_cursor.execute(GET_ALL_IMAGE_IDS)
        all_image_ids = [row[0] for row in mysql_cursor.fetchall()]
        processed_images = set()
        all_duplicate_sets = []

        print(f"Processing {len(all_image_ids)} images...")

        for i, image_id in enumerate(all_image_ids):
            if i > 0 and i % 100 == 0:
                print(f"  {i}/{len(all_image_ids)}...")

            if image_id in processed_images:
                continue

            postgres_cursor.execute(GET_IMAGE_VECTOR, (image_id,))
            result = postgres_cursor.fetchone()
            if not result:
                continue
            query_vector = result[0]

            postgres_cursor.execute(
                FIND_SIMILAR_IMAGES, (image_id, query_vector, args.threshold)
            )
            similar_images = postgres_cursor.fetchall()

            if similar_images:
                duplicate_set_ids = {image_id} | {row[0] for row in similar_images}
                processed_images.update(duplicate_set_ids)

                duplicate_details = [
                    get_image_details(mysql_cursor, dup_id)
                    for dup_id in duplicate_set_ids
                    if get_image_details(mysql_cursor, dup_id) is not None
                ]

                if len(duplicate_details) > 1:
                    reference_image = select_reference_image(duplicate_details)
                    duplicates = [
                        d for d in duplicate_details if d["id"] != reference_image["id"]
                    ]
                    all_duplicate_sets.append(
                        {"reference": reference_image, "duplicates": duplicates}
                    )

        # --- Generate HTML Report ---
        if all_duplicate_sets:
            sets_per_page = 50
            total_pages = math.ceil(len(all_duplicate_sets) / sets_per_page)
            print(
                f"\nFound {len(all_duplicate_sets)} duplicate sets. Generating {total_pages} HTML pages..."
            )

            for i in range(total_pages):
                start_index = i * sets_per_page
                end_index = start_index + sets_per_page
                page_sets = all_duplicate_sets[start_index:end_index]
                generate_html_page(page_sets, i + 1, total_pages, output_dir)

            print(f"Done. HTML report generated in '{output_dir}'")
        else:
            print("No duplicates found.")

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        if "mysql_conn" in locals() and mysql_conn.is_connected():
            mysql_cursor.close()
            mysql_conn.close()
        if "postgres_conn" in locals():
            postgres_cursor.close()
            postgres_conn.close()


if __name__ == "__main__":
    main()
