import sys
import argparse
import mysql.connector
from urllib.parse import urlparse

# --- Database Queries ---

ADD_DEDUP_REASON_COLUMN = "ALTER TABLE Images ADD COLUMN dedupReason TEXT DEFAULT NULL"

COUNT_ALL_IMAGES = "SELECT COUNT(*) FROM Images"

GET_IMAGE_IDS_BATCH = "SELECT id FROM Images LIMIT %s OFFSET %s"

GET_CAMERA_INFO = "SELECT make, model FROM ImageMetadata WHERE imageid = %s"

GET_DIMENSIONS = "SELECT width, height FROM ImageInformation WHERE imageid = %s"

GET_APPLEMARK_COMMENT = "SELECT COUNT(*) FROM ImageComments WHERE imageid = %s AND comment LIKE '%%AppleMark%%'"

UPDATE_DEDUP_REASON = "UPDATE Images SET dedupReason = %s WHERE id = %s"

# --- Main Logic ---


def main():
    parser = argparse.ArgumentParser(
        description="Find and mark non-camera images in the Digikam database."
    )
    parser.add_argument(
        "--mysql-conn-str", required=True, help="MySQL connection string"
    )
    args = parser.parse_args()

    # --- Database Connection ---
    mysql_url = urlparse(args.mysql_conn_str)

    try:
        mysql_conn = mysql.connector.connect(
            host=mysql_url.hostname,
            user=mysql_url.username,
            password=mysql_url.password,
            database=mysql_url.path[1:],
        )

        # --- Add dedupReason column if it doesn't exist ---
        try:
            print("Ensuring 'dedupReason' column exists in Images table...")
            cursor = mysql_conn.cursor()
            cursor.execute(ADD_DEDUP_REASON_COLUMN)
            mysql_conn.commit()
            print("Column added or already exists.")
            cursor.close()
        except mysql.connector.Error as err:
            if err.errno == 1060:  # Duplicate column name
                print("Column 'dedupReason' already exists.")
            else:
                raise

        # --- Main Processing ---
        count_cursor = mysql_conn.cursor()
        count_cursor.execute(COUNT_ALL_IMAGES)
        total_images = count_cursor.fetchone()[0]
        count_cursor.close()

        batch_size = 1000
        offset = 0
        processed_count = 0

        print(f"Processing {total_images} images...")

        while offset < total_images:
            batch_cursor = mysql_conn.cursor()
            batch_cursor.execute(GET_IMAGE_IDS_BATCH, (batch_size, offset))
            image_ids = [row[0] for row in batch_cursor.fetchall()]
            batch_cursor.close()

            if not image_ids:
                break

            for image_id in image_ids:
                reasons = []
                check_cursor = mysql_conn.cursor()

                # Check 1: Non-camera
                check_cursor.execute(GET_CAMERA_INFO, (image_id,))
                camera_info = check_cursor.fetchone()
                if not camera_info or (not camera_info[0] and not camera_info[1]):
                    reasons.append("non-camera")

                # Check 2: Face detection
                check_cursor.execute(GET_DIMENSIONS, (image_id,))
                dimensions = check_cursor.fetchone()
                if (
                    dimensions
                    and len(dimensions) == 2
                    and type(dimensions[0]) is int
                    and type(dimensions[1]) is int
                    and dimensions[0] == dimensions[1]
                    and dimensions[0] <= 512
                ):
                    reasons.append("face-detection")

                # Check 3: AppleMark
                check_cursor.execute(GET_APPLEMARK_COMMENT, (image_id,))
                comment_count = check_cursor.fetchone()[0]
                if comment_count > 0:
                    reasons.append("applemark")

                check_cursor.close()

                # Update database if any reasons were found
                if reasons:
                    reason_str = ",".join(reasons)
                    update_cursor = mysql_conn.cursor()
                    update_cursor.execute(UPDATE_DEDUP_REASON, (reason_str, image_id))
                    update_cursor.close()

            mysql_conn.commit()  # Commit after each batch
            offset += batch_size
            processed_count += len(image_ids)
            print(f"  {processed_count}/{total_images}...")

        print("\nDone. Database has been updated.")

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        if "mysql_conn" in locals() and mysql_conn.is_connected():
            mysql_conn.close()


if __name__ == "__main__":
    main()
