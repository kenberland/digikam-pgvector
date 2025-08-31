import sys
import time
import mysql.connector
import psycopg2
from pgvector.psycopg2 import register_vector
import numpy as np
from urllib.parse import urlparse
from mysql_to_pgvector import convert_blob_to_vector
import argparse
import random
import struct

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
NUMBER_OF_COEFFICIENTS = 40

def create_weight_bin():
    m_bin = [5] * NUMBER_OF_PIXELS_SQUARED
    for i in range(5):
        for j in range(5):
            m_bin[i * NUMBER_OF_PIXELS + j] = max(i, j)
    return m_bin

class Signature:
    def __init__(self, blob):
        version, avg1, avg2, avg3, *coeffs = struct.unpack(">i3d120i", blob)
        self.avg = [avg1, avg2, avg3]
        self.sig = [
            set(coeffs[0:40]),
            set(coeffs[40:80]),
            set(coeffs[80:120])
        ]

def calculate_score(query_sig, target_sig, weights, weight_bin):
    score = 0.0
    for channel in range(3):
        score += weights[0][channel] * abs(query_sig.avg[channel] - target_sig.avg[channel])
    for channel in range(3):
        common_coeffs = query_sig.sig[channel].intersection(target_sig.sig[channel])
        for coef in common_coeffs:
            abs_coef = abs(coef)
            if 0 < abs_coef < len(weight_bin):
                weight_index = weight_bin[abs_coef]
                score -= weights[weight_index][channel]
    return score

# --- Benchmark Script Logic ---

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    ENDC = '\033[0m'

def main():
    parser = argparse.ArgumentParser(description='Benchmark MySQL vs. pgvector.')
    parser.add_argument('mysql_conn_str', help='MySQL connection string')
    parser.add_argument('postgres_conn_str', help='PostgreSQL connection string')
    parser.add_argument('--seed', type=int, default=42, help='Random seed for repeatable results')
    args = parser.parse_args()

    random.seed(args.seed)
    np.random.seed(args.seed)

    mysql_url = urlparse(args.mysql_conn_str)
    postgres_url = urlparse(args.postgres_conn_str)

    try:
        mysql_conn = mysql.connector.connect(
            host=mysql_url.hostname,
            user=mysql_url.username,
            password=mysql_url.password,
            database=mysql_url.path[1:]
        )

        postgres_conn = psycopg2.connect(
            host=postgres_url.hostname,
            user=postgres_url.username,
            password=postgres_url.password,
            dbname=postgres_url.path[1:]
        )
        postgres_cursor = postgres_conn.cursor()
        register_vector(postgres_conn)

        mysql_times = []
        postgres_times = []
        num_runs = 5

        count_cursor = mysql_conn.cursor()
        count_cursor.execute("SELECT COUNT(*) FROM ImageHaarMatrix")
        image_count = count_cursor.fetchone()[0]
        count_cursor.close()

        print(f"--- Starting Benchmark ({num_runs} runs, seed={args.seed}) ---")

        for i in range(num_runs):
            print(f"\n--- Run {i+1}/{num_runs} ---")

            random_offset = random.randint(0, image_count - 1)
            rand_cursor = mysql_conn.cursor()
            rand_cursor.execute(f"SELECT imageid, matrix FROM ImageHaarMatrix LIMIT 1 OFFSET {random_offset}")
            query_id, query_blob = rand_cursor.fetchone()
            query_sig = Signature(query_blob)
            query_vector = convert_blob_to_vector(query_blob) # For pgvector
            print(f"Querying for image id: {query_id}")
            rand_cursor.close()

            # --- MySQL Benchmark (Correct Haar Score) ---
            print("Running MySQL benchmark (calculating true Haar score)... ", end="", flush=True)
            start_time = time.time()
            
            unbuffered_mysql_cursor = mysql_conn.cursor(buffered=False)
            unbuffered_mysql_cursor.execute("SELECT imageid, matrix FROM ImageHaarMatrix")
            
            weights = S_HAAR_WEIGHTS[0]
            weight_bin = create_weight_bin()
            mysql_results = []
            for j, (imageid, matrix_blob) in enumerate(unbuffered_mysql_cursor):
                if j > 0 and j % 10000 == 0:
                    print(".", end="", flush=True)
                target_sig = Signature(matrix_blob)
                score = calculate_score(query_sig, target_sig, weights, weight_bin)
                mysql_results.append((imageid, score))
            print() # for newline
            unbuffered_mysql_cursor.close()
            
            mysql_results.sort(key=lambda x: x[1])
            mysql_time = time.time() - start_time
            mysql_times.append(mysql_time)
            print(f"MySQL (true Haar score): {mysql_time:.4f} seconds")

            # --- PostgreSQL Benchmark (Flawed L2 Distance) ---
            start_time = time.time()
            postgres_cursor.execute(
                "SELECT imageid, matrix <-> %s AS distance FROM ImageHaarMatrix ORDER BY distance LIMIT 10",
                (query_vector,)
            )
            postgres_results = postgres_cursor.fetchall()
            postgres_time = time.time() - start_time
            postgres_times.append(postgres_time)
            print(f"PostgreSQL (L2 distance): {postgres_time:.4f} seconds")

        # --- Summarize Results ---
        avg_mysql_time = sum(mysql_times) / num_runs
        avg_postgres_time = sum(postgres_times) / num_runs

        print("\n--- Benchmark Summary ---")
        print(f"Runs: {num_runs}")
        print("\n--- Average Times ---")
        print(f"MySQL (true Haar score): {Colors.RED}{avg_mysql_time:.4f} seconds{Colors.ENDC}")
        print(f"PostgreSQL (L2 distance): {Colors.GREEN}{avg_postgres_time:.4f} seconds{Colors.ENDC}")

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        if 'mysql_conn' in locals() and mysql_conn.is_connected():
            mysql_conn.close()
        if 'postgres_conn' in locals():
            postgres_conn.close()

if __name__ == "__main__":
    main()