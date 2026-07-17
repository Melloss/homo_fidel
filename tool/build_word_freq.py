#!/usr/bin/env python3
"""Regenerates assets/word_freq.json — the Mode B word-frequency list.

    python3 tool/build_word_freq.py

Source corpus: "An Amharic News Text classification Dataset" (Azime & Mohammed,
2021, arXiv:2103.05639), ~41k news articles, CC BY 4.0 — a licence that permits
commercial redistribution with attribution, which matters because this list
ships inside a client deliverable.

Why news text specifically: it is professionally edited, so its spelling is far
closer to canonical than raw web text. A frequency list is only useful for
"which spelling did the writer probably mean" if the corpus itself is mostly
spelled the way editors spell.

IMPORTANT — this list is descriptive, not prescriptive. It records what Ethiopian
newsrooms actually write, which in several cases departs from traditional
etymological orthography (ፀሎት outnumbers ጸሎት 269:2 here; አይን outnumbers ዐይን
458:7). The engine therefore reports frequency evidence and never claims an
authority it does not have. See NOTES.md.
"""
import collections
import csv
import json
import os
import re
import sys
import urllib.request

CSV_URL = ("https://huggingface.co/datasets/israel/"
           "Amharic-News-Text-classification-Dataset/resolve/main/train.csv")
CACHE = os.path.join(os.path.dirname(__file__), ".cache_amnews_train.csv")
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "word_freq.json")

# A word is a run of Ethiopic *syllables*. The range ends at ፚ = U+135A, the
# last syllable in the block; ETHIOPIC WORDSPACE/FULL STOP/COMMA (U+1361-1363)
# and the digits (U+1369+) sit just above it, so punctuation and numerals fall
# out of tokenisation for free — as does Latin, which this corpus also contains.
WORD = re.compile(r"[ሀ-ፚ]+")

# The four homophone families (spec §4), as flat code points.
BASES = [0x1200, 0x1210, 0x1280, 0x1230, 0x1220, 0x1338, 0x1340, 0x12A0, 0x12D0]
FAMILY_CPS = {b + order for b in BASES for order in range(7)}

# Words with no family letter can never be looked up: the engine only consults
# the list for words containing a choice point, and every homophone variant of
# such a word still contains one. Dropping them costs nothing and removes 43%
# of the types.
#
# Keep counts >= 3. Rarer types are mostly corpus noise, and the engine's
# dominance rule treats "absent" and "attested once or twice" almost
# identically anyway — so the tail buys size, not accuracy.
MIN_COUNT = 3


def fetch():
    if not os.path.exists(CACHE):
        print(f"downloading {CSV_URL} ...")
        urllib.request.urlretrieve(CSV_URL, CACHE)
    return CACHE


def main():
    csv.field_size_limit(sys.maxsize)
    counter = collections.Counter()
    articles = 0
    with open(fetch(), newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            articles += 1
            for column in ("headline", "article"):
                counter.update(WORD.findall(row.get(column) or ""))

    tokens = sum(counter.values())
    words = {
        w: n for w, n in counter.items()
        if n >= MIN_COUNT and any(ord(c) in FAMILY_CPS for c in w)
    }

    payload = {
        "meta": {
            "source": "An Amharic News Text classification Dataset "
                      "(Azime & Mohammed, 2021)",
            "url": "https://arxiv.org/abs/2103.05639",
            "dataset": "https://huggingface.co/datasets/israel/"
                       "Amharic-News-Text-classification-Dataset",
            "license": "CC BY 4.0",
            "attribution": "Israel Abebe Azime and Nebil Mohammed, "
                           "'An Amharic News Text classification Dataset', "
                           "arXiv:2103.05639, 2021. Licensed CC BY 4.0.",
            "note": "Descriptive frequencies of edited news prose, not a "
                    "prescriptive dictionary. Words without a homophone-family "
                    "letter are omitted: the engine never looks them up.",
            "articles": articles,
            "tokens": tokens,
            "minCount": MIN_COUNT,
            "generatedBy": "tool/build_word_freq.py",
        },
        # Sorted so regenerating the asset produces a stable diff.
        "words": dict(sorted(words.items())),
    }

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))

    print(f"articles      : {articles:,}")
    print(f"tokens        : {tokens:,}")
    print(f"unique types  : {len(counter):,}")
    print(f"kept          : {len(words):,} (family letter, count >= {MIN_COUNT})")
    print(f"wrote         : {OUT} "
          f"({os.path.getsize(OUT)/1048576:.2f} MB)")


if __name__ == "__main__":
    main()
