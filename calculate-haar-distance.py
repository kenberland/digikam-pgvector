
import sys
import argparse
import mysql.connector
from urllib.parse import urlparse
import struct

# --- Ported Digikam Logic ---

# From haar.h
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
    """Port of WeightBin::WeightBin() from haar.cpp"""
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
    """Port of HaarIface::calculateScore from haariface.cpp"""
    score = 0.0
    # Step 1: Average intensity values
    for channel in range(3):
        score += weights[0][channel] * abs(query_sig.avg[channel] - target_sig.avg[channel])

    # Step 2: Common coefficients
    for channel in range(3):
        common_coeffs = query_sig.sig[channel].intersection(target_sig.sig[channel])
        for coef in common_coeffs:
            # Get absolute index for weight_bin
            abs_coef = abs(coef)
            if 0 < abs_coef < len(weight_bin):
                weight_index = weight_bin[abs_coef]
                score -= weights[weight_index][channel]
    return score

# --- Main Script Logic ---

def main():
    parser = argparse.ArgumentParser(description='Calculate Haar distance between images.')
    parser.add_argument('--imageid', type=int, required=True, help='The ID of the image to compare against.')
    parser.add_argument('--mysql-conn-str', required=True, help='MySQL connection string')
    parser.add_argument('--limit', type=int, default=30, help='Number of results to show.')
    args = parser.parse_args()

    mysql_url = urlparse(args.mysql_conn_str)

    try:
        mysql_conn = mysql.connector.connect(
            host=mysql_url.hostname,
            user=mysql_url.username,
            password=mysql_url.password,
            database=mysql_url.path[1:]
        )

        print(f"Fetching signature for query image ID: {args.imageid}")
        cursor = mysql_conn.cursor()
        cursor.execute("SELECT matrix FROM ImageHaarMatrix WHERE imageid = %s", (args.imageid,))
        query_blob = cursor.fetchone()[0]
        query_sig = Signature(query_blob)

        print("Fetching all other image signatures...")
        cursor.execute("SELECT imageid, matrix FROM ImageHaarMatrix WHERE imageid != %s", (args.imageid,))
        
        # Pre-calculate weights and bins
        weights = S_HAAR_WEIGHTS[0] # Assuming ScannedSketch
        weight_bin = create_weight_bin()

        print("Calculating scores...")
        scores = []
        for (imageid, matrix_blob) in cursor:
            target_sig = Signature(matrix_blob)
            score = calculate_score(query_sig, target_sig, weights, weight_bin)
            scores.append((imageid, score))
        
        cursor.close()

        # Sort by score (lower is better)
        scores.sort(key=lambda x: x[1])

        print(f"\n--- Top {args.limit} most similar images to {args.imageid} (using Digikam's algorithm) ---")
        print("{:<10} {:<20}".format('ImageID', 'Haar Score'))
        print("-" * 30)
        for i in range(min(args.limit, len(scores))):
            print("{:<10} {:<20.4f}".format(scores[i][0], scores[i][1]))

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        if 'mysql_conn' in locals() and mysql_conn.is_connected():
            mysql_conn.close()

if __name__ == "__main__":
    main()
