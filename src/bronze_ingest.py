"""
Bronze Layer Ingestion
======================
Reads raw NYC Yellow Taxi Parquet data and loads it into the `bronze`
table in MySQL, with ingestion metadata attached.

Medallion layer: BRONZE (raw, untransformed).
"""

import hashlib
import logging
from datetime import datetime

import pandas as pd
from sqlalchemy import create_engine, text

from config import (
    DB_URL, PARQUET_FILE, BRONZE_TABLE,
    TARGET_ROWS, CHUNK_SIZE,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
)
log = logging.getLogger(__name__)


def _add_metadata(df: pd.DataFrame, source_file: str) -> pd.DataFrame:
    """Attach ingestion timestamp, source, and row hash."""
    df["_ingest_timestamp"] = datetime.now()
    df["_source_file"] = str(source_file)
    df["_row_hash"] = df.apply(
        lambda row: hashlib.sha256(
            "|".join(str(v) for v in row.values).encode()
        ).hexdigest(),
        axis=1,
    )
    return df


def run() -> None:
    engine = create_engine(DB_URL)

    with engine.connect() as conn:
        log.info("Truncating %s ...", BRONZE_TABLE)
        conn.execute(text(f"TRUNCATE TABLE {BRONZE_TABLE}"))
        conn.commit()

    log.info("Reading parquet: %s", PARQUET_FILE)
    df = pd.read_parquet(PARQUET_FILE, engine="pyarrow")
    log.info("Loaded %s rows.", f"{len(df):,}")

    if len(df) > TARGET_ROWS:
        log.info("Slicing to %s rows.", f"{TARGET_ROWS:,}")
        df = df.iloc[:TARGET_ROWS]

    df = _add_metadata(df, PARQUET_FILE)
    total = len(df)

    log.info("Inserting %s rows in chunks of %s ...", f"{total:,}", f"{CHUNK_SIZE:,}")
    imported = 0
    for start in range(0, total, CHUNK_SIZE):
        end = min(start + CHUNK_SIZE, total)
        chunk = df.iloc[start:end]
        chunk.to_sql(BRONZE_TABLE, engine, if_exists="append", index=False)
        imported += len(chunk)
        log.info("Inserted %s / %s", f"{imported:,}", f"{total:,}")
        del chunk

    log.info("Bronze ingestion complete: %s rows.", f"{imported:,}")


if __name__ == "__main__":
    run()