import time
import mysql.connector
import psycopg2
from pgvector.psycopg2 import register_vector
import numpy as np
from urllib.parse import urlparse
from mysql_to_pgvector import convert_blob_to_vector
import argparse
import random


def l2_distance(v1, v2):
    return np.linalg.norm(v1 - v2)


class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    ENDC = "\033[0m"


def main():
    parser = argparse.ArgumentParser(description="Benchmark MySQL vs. pgvector.")
    parser.add_argument("mysql_conn_str", help="MySQL connection string")
    parser.add_argument("postgres_conn_str", help="PostgreSQL connection string")
    parser.add_argument(
        "--seed", type=int, default=42, help="Random seed for repeatable results"
    )
    args = parser.parse_args()

    # Seed for reproducibility
    random.seed(args.seed)
    np.random.seed(args.seed)

    # Parse connection strings
    mysql_url = urlparse(args.mysql_conn_str)
    postgres_url = urlparse(args.postgres_conn_str)

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

    # --- Get all image IDs for random selection ---
    mysql_cursor.execute("SELECT imageid FROM ImageHaarMatrix")
    all_image_ids = [row[0] for row in mysql_cursor.fetchall()]

    mysql_times = []
    postgres_times = []
    num_runs = 5

    print(f"--- Starting Benchmark ({num_runs} runs, seed={args.seed}) ---")

    for i in range(num_runs):
        print(f"\n--- Run {i+1}/{num_runs} ---")

        # --- Pick a random image to search for ---
        random_image_id = random.choice(all_image_ids)
        mysql_cursor.execute(
            "SELECT matrix FROM ImageHaarMatrix WHERE imageid = %s", (random_image_id,)
        )
        query_blob = mysql_cursor.fetchone()[0]
        query_vector = convert_blob_to_vector(query_blob)
        print(f"Querying for image id: {random_image_id}")

        # --- MySQL Benchmark ---
        print("Running MySQL benchmark... ", end="", flush=True)
        start_time = time.time()
        mysql_cursor.execute("SELECT imageid, matrix FROM ImageHaarMatrix")
        mysql_results = []
        all_rows = mysql_cursor.fetchall()
        for j, (imageid, matrix_blob) in enumerate(all_rows):
            if j > 0 and j % 10000 == 0:
                print(".", end="", flush=True)
            vector = convert_blob_to_vector(matrix_blob)
            distance = l2_distance(query_vector, vector)
            mysql_results.append((imageid, distance))
        print()  # for newline

        mysql_results.sort(key=lambda x: x[1])
        mysql_time = time.time() - start_time
        mysql_times.append(mysql_time)
        print(f"MySQL (simulated search): {mysql_time:.4f} seconds")

        # --- PostgreSQL Benchmark ---
        start_time = time.time()
        postgres_cursor.execute(
            "SELECT imageid, matrix <-> %s AS distance FROM ImageHaarMatrix ORDER BY distance LIMIT 10",
            (query_vector,),
        )
        postgres_results = postgres_cursor.fetchall()
        postgres_time = time.time() - start_time
        postgres_times.append(postgres_time)
        print(f"PostgreSQL (pgvector search): {postgres_time:.4f} seconds")

        # --- Verification ---
        mysql_top_10_ids = {res[0] for res in mysql_results[:10]}
        postgres_top_10_ids = {res[0] for res in postgres_results}

        if mysql_top_10_ids == postgres_top_10_ids:
            print(f"{Colors.GREEN}Result sets match.{Colors.ENDC}")
        else:
            print(f"{Colors.RED}Result sets DO NOT match.{Colors.ENDC}")
            print(f"  MySQL results: {mysql_top_10_ids}")
            print(f"  PostgreSQL results: {postgres_top_10_ids}")

    # --- Summarize Results ---
    avg_mysql_time = sum(mysql_times) / num_runs
    avg_postgres_time = sum(postgres_times) / num_runs
    improvement_factor = avg_mysql_time / avg_postgres_time

    print("\n--- Benchmark Summary ---")
    print(f"Runs: {num_runs}")
    print("\n--- Individual Run Times ---")
    for i in range(num_runs):
        print(
            f"Run {i+1}: MySQL: {Colors.RED}{mysql_times[i]:.4f}s{Colors.ENDC}, PostgreSQL: {Colors.GREEN}{postgres_times[i]:.4f}s{Colors.ENDC}"
        )

    print("\n--- Average Times ---")
    print(
        f"MySQL (simulated search): {Colors.RED}{avg_mysql_time:.4f} seconds{Colors.ENDC}"
    )
    print(
        f"PostgreSQL (pgvector search): {Colors.GREEN}{avg_postgres_time:.4f} seconds{Colors.ENDC}"
    )
    print(f"\nImprovement Factor: {Colors.GREEN}{improvement_factor:.2f}x{Colors.ENDC}")

    if "mysql_conn" in locals() and mysql_conn.is_connected():
        mysql_cursor.close()
        mysql_conn.close()
    if "postgres_conn" in locals():
        postgres_cursor.close()
        postgres_conn.close()


if __name__ == "__main__":
    main()
