# split_upload.py
import shutil
from pathlib import Path
from typing import Dict
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from pydantic import BaseModel
import threading


BASE_UPLOAD_DIR = Path("./uploads")
TEMP_DIR = BASE_UPLOAD_DIR / "temp"
BASE_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
TEMP_DIR.mkdir(parents=True, exist_ok=True)

# Simple in-memory lock map to avoid race when merging same fileId concurrently.
_lock_map: Dict[str, threading.Lock] = {}
_lock_map_lock = threading.Lock()


class Metadata(BaseModel):
    order: int         # chunk index (0-based or 1-based; client and server must agree)
    fileId: str        # identifier for this overall file (client generated)
    offset: int = 0    # byte offset of this chunk (optional)
    limit: int = 0     # optional: total expected size OR client-defined limit (keeps compatibility)
    fileSize: int = 0  # optional: another field client might use for expected size (keeps compatibility)
    fileName: str      # original filename


def get_lock_for_file(file_id: str) -> threading.Lock:
    with _lock_map_lock:
        if file_id not in _lock_map:
            _lock_map[file_id] = threading.Lock()
        return _lock_map[file_id]


def temp_chunk_name(order: int, file_id: str) -> str:
    # deterministic chunk filename: order_fileId.chunk
    return f"{order}_{file_id}.chunk"


async def split_upload(
    order: int = Form(...),
    fileId: str = Form(...),
    offset: int = Form(0),
    limit: int = Form(0),
    fileSize: int = Form(0),
    fileName: str = Form(...),
    chunk: UploadFile = File(...),
):
    """
    Endpoint to receive a chunk upload.
    Expects multipart/form-data with fields:
      - order (int)
      - fileId (str)
      - offset (int) optional
      - limit (int) optional (interpreted as expected total size)
      - fileSize (int) optional (alternative expected total size)
      - fileName (str)
      - chunk (file contents of this chunk)
    """
    metadata = Metadata(
        order=order,
        fileId=fileId,
        offset=offset,
        limit=limit,
        fileSize=fileSize,
        fileName=fileName,
    )

    # Save chunk
    chunk_path = TEMP_DIR / temp_chunk_name(metadata.order, metadata.fileId)
    try:
        # write chunk to temp file
        with open(chunk_path, "wb") as f:
            while True:
                data = await chunk.read(1024 * 1024)
                if not data:
                    break
                f.write(data)
    except Exception as e:
        # remove partial file if any
        if chunk_path.exists():
            chunk_path.unlink(missing_ok=True)
        raise HTTPException(status_code=400, detail=f"error saving chunk: {e}")

    # Acquire per-file lock for merge-check and potential merge operation
    file_lock = get_lock_for_file(metadata.fileId)

    # The merge check and merge itself are protected by the lock to avoid races
    with file_lock:
        # Find all chunks for this fileId
        pattern = f"*_{metadata.fileId}.chunk"
        chunks = list(TEMP_DIR.glob(pattern))

        # Compute total size of chunks we have for this fileId
        total_bytes = sum(p.stat().st_size for p in chunks)

        # Decide whether to merge:
        # We accept either metadata.fileSize or metadata.limit as the authoritative total expected bytes.
        expected_total = None
        if metadata.fileSize and metadata.limit:
            # both provided: pick the one that is >0 and equal or larger
            expected_total = max(metadata.fileSize, metadata.limit)
        elif metadata.fileSize:
            expected_total = metadata.fileSize
        elif metadata.limit:
            expected_total = metadata.limit

        should_merge = False
        if expected_total:
            # If total bytes we've received equals expected, merge.
            if total_bytes >= expected_total:
                should_merge = True
        else:
            # No expected size provided. Best-effort: if there are at least 1 chunk and
            # the client reported 'order' and that order looks like last chunk,
            # you'd need client to indicate last chunk. Without that, we cannot reliably know.
            # Here we do NOT merge automatically; client should supply expected total or last-flag.
            should_merge = False

        if should_merge:
            # Sort chunk paths by integer order extracted from filename prefix "order_fileId.chunk"
            def order_from_name(p: Path) -> int:
                # filename: "<order>_<fileId>.chunk"
                name = p.name
                try:
                    order_str = name.split("_", 1)[0]
                    return int(order_str)
                except Exception:
                    # if parse error, send large number so malformed ones go to end
                    return 10**9

            chunks_sorted = sorted(chunks, key=order_from_name)

            final_path = BASE_UPLOAD_DIR / f"merged_{metadata.fileName}"
            try:
                with open(final_path, "wb") as final_f:
                    for p in chunks_sorted:
                        with open(p, "rb") as pf:
                            shutil.copyfileobj(pf, final_f)
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"error merging file: {e}")

            # Cleanup temp chunks
            for p in chunks:
                try:
                    p.unlink(missing_ok=True)
                except Exception:
                    # ignore failures to delete; but log/stash if needed
                    pass

            # Optionally: delete lock object from map
            with _lock_map_lock:
                _lock_map.pop(metadata.fileId, None)

            return {"status": "merged", "path": str(final_path)}

    # If we reach here: saved chunk, but not enough chunks/bytes yet
    return {"status": "stored", "chunk_path": str(chunk_path), "total_bytes_received": total_bytes}
