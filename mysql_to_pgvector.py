import sys
import struct
import mysql.connector
import psycopg2
from psycopg2.extras import execute_values
from pgvector.psycopg2 import register_vector
import numpy as np
from urllib.parse import urlparse

# Based on the analysis of the digiKam source code (haar.h, haariface_p.cpp),
# the vector dimension is fixed at 123 (3 doubles for averages + 3*40 ints for coefficients).

VECTOR_DIMENSION = 123
BLOB_SIZE = 508  # 4 (version) + 3*8 (avg) + 3*40*4 (sig)


def convert_blob_to_vector(blob):
    """
    Converts the digiKam Haar matrix blob to a numpy array.
    The blob format is a QDataStream containing:
    - 1 qint32 (version)
    - 3 doubles (averages)
    - 120 qint32s (coefficients)
    """
    if len(blob) != BLOB_SIZE:
        raise ValueError(f"Invalid blob size: expected {BLOB_SIZE}, got {len(blob)}")

    # Unpack the blob using the format string for big-endian data.
    # >i: version (4-byte signed int)
    # >3d: 3 averages (8-byte double)
    # >120i: 120 coefficients (4-byte signed int)
    version, avg1, avg2, avg3, *coeffs = struct.unpack(">i3d120i", blob)

    if version != 1:
        print(f"Warning: Unexpected blob version: {version}")

    # Combine averages and coefficients into a single vector.
    vector = [avg1, avg2, avg3] + coeffs
    return np.array(vector, dtype=np.float32)


def main():
    if len(sys.argv) != 3:
        print(
            "Usage: python mysql_to_pgvector.py <mysql_connection_string> <postgresql_connection_string>"
        )
        sys.exit(1)

    mysql_conn_str = sys.argv[1]
    postgres_conn_str = sys.argv[2]

    mysql_url = urlparse(mysql_conn_str)
    postgres_url = urlparse(postgres_conn_str)

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

    postgres_cursor.execute("CREATE EXTENSION IF NOT EXISTS vector")
    postgres_conn.commit()
    register_vector(postgres_conn)

    table_name = "ImageHaarMatrix"
    create_table_query = f"""
    CREATE TABLE IF NOT EXISTS {table_name} (
        imageid bigint PRIMARY KEY,
        modificationDate timestamp,
        uniqueHash text,
        matrix vector({VECTOR_DIMENSION})
    );
    """
    postgres_cursor.execute(create_table_query)
    postgres_conn.commit()
    print(f"Table '{table_name}' created in PostgreSQL (if it didn't exist).")

    # Fetch data from MySQL
    mysql_cursor.execute(
        "SELECT imageid, modificationDate, uniqueHash, matrix FROM ImageHaarMatrix"
    )

    batch_size = 10000
    while True:
        rows = mysql_cursor.fetchmany(batch_size)
        if not rows:
            break

        data_to_insert = []
        for row in rows:
            imageid, modificationDate, uniqueHash, matrix_blob = row
            try:
                vector = convert_blob_to_vector(matrix_blob)
                data_to_insert.append((imageid, modificationDate, uniqueHash, vector))
            except ValueError as e:
                print(f"Skipping row for imageid {imageid}: {e}")

        if data_to_insert:
            execute_values(
                postgres_cursor,
                f"INSERT INTO {table_name} (imageid, modificationDate, uniqueHash, matrix) VALUES %s ON CONFLICT (imageid) DO NOTHING",
                data_to_insert,
            )
            postgres_conn.commit()
            print(f"Inserted {len(data_to_insert)} rows into PostgreSQL.")

    print("Data migration completed successfully.")

    if "mysql_conn" in locals() and mysql_conn.is_connected():
        mysql_cursor.close()
        mysql_conn.close()
    if "postgres_conn" in locals():
        postgres_cursor.close()
        postgres_conn.close()


if __name__ == "__main__":
    main()
