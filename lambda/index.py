"""
Email MIME parser Lambda.

Triggered by S3 events when raw MIME emails land in the raw/ prefix.
Parses the MIME content into structured JSON and writes to parsed/<to>/<date>_<message_id>.json.
"""

import email
import email.policy
import json
import logging
import os
import re
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

BUCKET_NAME = os.environ.get("S3_BUCKET_NAME", "")
PARSED_PREFIX = os.environ.get("S3_PARSED_PREFIX", "parsed/")


def handler(event, context):
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        logger.info(json.dumps({"action": "processing", "bucket": bucket, "key": key}))

        raw_bytes = _download_raw_email(bucket, key)
        parsed = _parse_mime(raw_bytes)
        output_key = _build_output_key(parsed)
        _upload_parsed(output_key, parsed)

        logger.info(json.dumps({"action": "completed", "output_key": output_key}))

    return {"statusCode": 200, "body": json.dumps({"message": "ok"})}


def _download_raw_email(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    return response["Body"].read()


def _parse_mime(raw_bytes):
    msg = email.message_from_bytes(raw_bytes, policy=email.policy.default)

    message_id = msg.get("Message-ID", "")
    from_addr = msg.get("From", "")
    to_addr = msg.get("To", "")
    cc_addr = msg.get("Cc", "")
    subject = msg.get("Subject", "")
    date_raw = msg.get("Date", "")

    date_iso = ""
    if date_raw:
        try:
            dt = email.utils.parsedate_to_datetime(date_raw)
            date_iso = dt.isoformat()
        except Exception:
            date_iso = ""

    headers = {k: v for k, v in msg.items()}

    body_text = ""
    body_html = ""
    attachments = []

    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            disposition = str(part.get("Content-Disposition", ""))

            if "attachment" in disposition:
                attachments.append(_extract_attachment_metadata(part))
            elif content_type == "text/plain" and not body_text:
                body_text = _decode_payload(part)
            elif content_type == "text/html" and not body_html:
                body_html = _decode_payload(part)
    else:
        content_type = msg.get_content_type()
        if content_type == "text/plain":
            body_text = _decode_payload(msg)
        elif content_type == "text/html":
            body_html = _decode_payload(msg)

    return {
        "message_id": message_id,
        "from": from_addr,
        "to": to_addr,
        "cc": cc_addr,
        "subject": subject,
        "date": date_iso,
        "date_raw": date_raw,
        "headers": headers,
        "body_text": body_text,
        "body_html": body_html,
        "attachments": attachments,
    }


def _decode_payload(part):
    payload = part.get_content()
    if isinstance(payload, bytes):
        return payload.decode("utf-8", errors="replace")
    return payload if isinstance(payload, str) else ""


def _extract_attachment_metadata(part):
    filename = part.get_filename() or "unknown"
    content_type = part.get_content_type()
    payload = part.get_payload(decode=True)
    size = len(payload) if payload else 0

    return {
        "filename": filename,
        "content_type": content_type,
        "size": size,
    }


def _sanitize_for_key(value):
    """Remove or replace characters unsafe for S3 keys."""
    value = re.sub(r"[<>:\"/\\|?*]", "", value)
    value = re.sub(r"\s+", "_", value)
    return value[:128]


def _build_output_key(parsed):
    to_addr = parsed.get("to", "unknown").strip()
    # Extract just the email address if it contains a display name
    match = re.search(r"[\w.+-]+@[\w.-]+", to_addr)
    to_clean = _sanitize_for_key(match.group(0) if match else to_addr)

    message_id = parsed.get("message_id", "")
    id_clean = _sanitize_for_key(message_id) or "no-id"

    date_str = ""
    if parsed.get("date"):
        try:
            dt = datetime.fromisoformat(parsed["date"])
            date_str = dt.strftime("%Y%m%d_%H%M%S")
        except Exception:
            pass
    if not date_str:
        date_str = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

    return f"{PARSED_PREFIX}{to_clean}/{date_str}_{id_clean}.json"


def _upload_parsed(key, parsed):
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=key,
        Body=json.dumps(parsed, ensure_ascii=False, indent=2),
        ContentType="application/json",
    )
