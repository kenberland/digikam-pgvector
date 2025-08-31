import sys
import struct
import mysql.connector
import psycopg2
from psycopg2.extras import execute_values
from pgvector.psycopg2 import register_vector
import numpy as np
from urllib.parse import urlparse

# --- Ported Digikam Logic ---

S_HAAR_WEIGHTS = [
    # ScannedSketch
    [
        [5.00, 19.21, 34.37],
        [0.83, 1.26, 0.36],
        [1.01, 0.44, 0.45],
        [0.52, 0.53, 0.14],
        [0.47, 0.28, 0.18],
        [0.30, 0.14, 0.27]
    ],
    # PaintedSketch
    [
        [4.04, 15.14, 22.62],
        [0.78, 0.92, 0.40],
        [0.46, 0.53, 0.63],
        [0.42, 0.26, 0.25],
        [0.41, 0.14, 0.15],
        [0.32, 0.07, 0.38]
    ]
]

NUMBER_OF_PIXELS = 128
NUMBER_OF_PIXELS_SQUARED = NUMBER_OF_PIXELS * NUMBER_OF_PIXELS

def create_weight_bin():
    """Port of WeightBin::WeightBin() from haar.cpp"""
    m_bin = [5] * NUMBER_OF_PIXELS_SQUARED
    for i in range(5):
        for j in range(5):
            m_bin[i * NUMBER_OF_PIXELS + j] = max(i, j)
    return m_bin

# --- Vector Conversion ---

VECTOR_DIMENSION = 123
BLOB_SIZE = 508  # 4 (version) + 3*8 (avg) + 3*40*4 (sig)

def convert_blob_to_vector(blob, weights, weight_bin):
    """
    Converts the digiKam Haar matrix blob to a weighted feature vector.
    """
    if len(blob) != BLOB_SIZE:
        raise ValueError(f"Invalid blob size: expected {BLOB_SIZE}, got {len(blob)}")

    version, avg1, avg2, avg3, *coeffs = struct.unpack(">i3d120i", blob)

    if version != 1:
        print(f"Warning: Unexpected blob version: {version}")

    vector = [avg1, avg2, avg3]

    for channel in range(3):
        channel_coeffs = coeffs[channel * 40 : (channel + 1) * 40]
        channel_weights = []
        for coef in channel_coeffs:
            abs_coef = abs(coef)
            if 0 < abs_coef < len(weight_bin):
                weight_index = weight_bin[abs_coef]
                channel_weights.append(weights[weight_index][channel])
            else:
                channel_weights.append(0) # Should not happen in practice
        
        channel_weights.sort(reverse=True)
        vector.extend(channel_weights)

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

        # Pre-calculate weights and bins
        weights = S_HAAR_WEIGHTS[0] # Assuming ScannedSketch
        weight_bin = create_weight_bin()

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
                    vector = convert_blob_to_vector(matrix_blob, weights, weight_bin)
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

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        if 'mysql_conn' in locals() and mysql_conn.is_connected():
            mysql_conn.close()
        if 'postgres_conn' in locals():
            postgres_conn.close()

if __name__ == "__main__":
    main()