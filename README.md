# Digikam MySQL to pgvector Migration

This script moves image similarity data from a Digikam MySQL database to a PostgreSQL database with the `pgvector` extension. It also can run a benchmark, comparing searching using each.

## Usage

### Setup

```bash
uv venv
source .venv/bin/activate
uv sync
```

### Migrate

The following commands demonstrate how to drop and recreate the database, and then run the migration script.

```bash
dropdb -U postgres -h localhost digikam
createdb -U postgres -h localhost digikam
python mysql_to_pgvector.py mysql://root:secret@localhost/digikam "postgresql://postgres@localhost/digikam"
```

## Benchmarking

After you have converted the data, you can run the benchmark script to compare the performance of MySQL and PostgreSQL with `pgvector`.

```bash
python benchmark.py mysql://root:secret@localhost/digikam "postgresql://postgres@localhost/digikam"
```

This will run the benchmark 5 times and provide a summary of the results, including the performance improvement factor.

To ensure the benchmark is repeatable, you can use the `--seed` argument:

```bash
python benchmark.py mysql://root:secret@localhost/digikam "postgresql://postgres@localhost/digikam" --seed 123
```

If no seed is provided, it will default to 42.
