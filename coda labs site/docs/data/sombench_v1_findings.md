# SomBench v1 — Somali ASR Benchmark Findings

**Dataset:** `skydheere/soomali-asr-dataset` (HuggingFace, test split)
**Date:** June 22, 2026
**Clips evaluated:** 50 stitched clips (~10s each, 16kHz mono)
**Systems evaluated:** faster-whisper large-v3 · ElevenLabs Scribe v1

---

## Overview

This report benchmarks two production ASR systems on Somali speech using ground-truth transcriptions from the `skydheere/soomali-asr-dataset` HuggingFace dataset. The test split was stitched into 50 clips of approximately 10 seconds each (200ms silence padding between sub-clips), yielding a total of ~550 seconds of evaluated audio across 21,456 test examples in the source dataset.

---

## Summary Results

| System | n | Mean WER | Median WER | Mean CER | Median CER | Script Mismatches |
|---|---|---|---|---|---|---|
| **ElevenLabs Scribe v1** | 50 | **0.592** | **0.580** | **0.185** | **0.167** | 0 |
| faster-whisper large-v3 | 50 | 0.871 | 0.862 | 0.266 | 0.253 | 0 |

**ElevenLabs Scribe v1 wins on every metric.** It outperforms faster-whisper large-v3 by 0.279 WER points (32% relative reduction) and 0.081 CER points (30% relative reduction). Neither system produced Arabic-script hallucinations — a known failure mode for Whisper on Somali that was present in the earlier SomBench v0 runs.

---

## Detailed Statistics

### ElevenLabs Scribe v1

| Metric | Mean | Median | Min | Max | Std Dev |
|---|---|---|---|---|---|
| WER | 0.592 | 0.580 | 0.125 | 1.000 | 0.188 |
| CER | 0.185 | 0.167 | 0.020 | 0.613 | 0.105 |

### faster-whisper large-v3

| Metric | Mean | Median | Min | Max | Std Dev |
|---|---|---|---|---|---|
| WER | 0.871 | 0.862 | 0.619 | 1.438 | 0.140 |
| CER | 0.266 | 0.253 | 0.136 | 0.433 | 0.063 |

**Key observation:** ElevenLabs has a wider standard deviation on WER (0.188 vs 0.140), meaning it has higher upside (WER as low as 0.125) but also more variance. Whisper is more consistently mediocre — its floor is higher (min WER 0.619) but its ceiling is lower.

---

## Head-to-Head: Clip-by-Clip

ElevenLabs wins **44 of 50 clips** by WER. Whisper wins 4. 2 ties.

| Clip | WER (Whisper) | WER (ElevenLabs) | CER (Whisper) | CER (ElevenLabs) | Winner |
|---|---|---|---|---|---|
| clip01 | 0.938 | 0.438 | 0.240 | 0.104 | ElevenLabs |
| clip02 | 0.684 | 0.526 | 0.189 | 0.117 | ElevenLabs |
| clip03 | 0.812 | 0.688 | 0.253 | 0.190 | ElevenLabs |
| clip04 | 0.722 | 0.556 | 0.182 | 0.111 | ElevenLabs |
| clip05 | 0.957 | 0.696 | 0.345 | 0.172 | ElevenLabs |
| clip06 | 0.850 | 0.650 | 0.315 | 0.222 | ElevenLabs |
| clip07 | 0.850 | 0.650 | 0.242 | 0.188 | ElevenLabs |
| clip08 | 0.727 | 0.818 | 0.177 | 0.165 | **Whisper** |
| clip09 | 0.882 | 0.588 | 0.288 | 0.154 | ElevenLabs |
| clip10 | 0.905 | 0.857 | 0.331 | 0.297 | ElevenLabs |
| clip11 | 0.867 | 1.000 | 0.269 | 0.613 | **Whisper** |
| clip12 | 0.923 | 0.846 | 0.315 | 0.191 | ElevenLabs |
| clip13 | 0.857 | 0.762 | 0.421 | 0.331 | ElevenLabs |
| clip14 | 0.667 | 0.917 | 0.235 | 0.185 | **Whisper** |
| clip15 | 0.900 | 0.500 | 0.267 | 0.171 | ElevenLabs |
| clip16 | 0.824 | 0.529 | 0.183 | 0.128 | ElevenLabs |
| clip17 | 0.824 | 0.647 | 0.290 | 0.370 | ElevenLabs |
| clip18 | 0.667 | 0.500 | 0.244 | 0.078 | ElevenLabs |
| clip19 | 1.231 | 0.462 | 0.253 | 0.165 | ElevenLabs |
| clip20 | 0.917 | 0.500 | 0.329 | 0.139 | ElevenLabs |
| clip21 | 0.809 | 0.714 | 0.344 | 0.264 | ElevenLabs |
| clip22 | 0.842 | 0.737 | 0.245 | 0.431 | ElevenLabs |
| clip23 | 0.765 | 0.882 | 0.289 | 0.333 | **Whisper** |
| clip24 | 0.944 | 0.667 | 0.336 | 0.195 | ElevenLabs |
| clip25 | 1.000 | 0.625 | 0.302 | 0.170 | ElevenLabs |
| clip26 | 0.765 | 0.412 | 0.247 | 0.129 | ElevenLabs |
| clip27 | 0.950 | 0.700 | 0.337 | 0.286 | ElevenLabs |
| clip28 | 1.438 | 0.875 | 0.367 | 0.225 | ElevenLabs |
| clip29 | 0.818 | 0.682 | 0.234 | 0.175 | ElevenLabs |
| clip30 | 0.867 | 0.400 | 0.250 | 0.115 | ElevenLabs |
| clip31 | 0.733 | 0.333 | 0.202 | 0.106 | ElevenLabs |
| clip32 | 0.889 | 0.556 | 0.246 | 0.119 | ElevenLabs |
| clip33 | 0.950 | 0.400 | 0.225 | 0.100 | ElevenLabs |
| clip34 | 0.938 | 0.562 | 0.281 | 0.123 | ElevenLabs |
| clip35 | 0.769 | 0.308 | 0.136 | 0.091 | ElevenLabs |
| clip36 | 0.842 | 0.263 | 0.189 | 0.076 | ElevenLabs |
| clip37 | 0.778 | 0.333 | 0.245 | 0.098 | ElevenLabs |
| clip38 | 1.000 | 0.818 | 0.337 | 0.157 | ElevenLabs |
| clip39 | 0.941 | 0.529 | 0.216 | 0.171 | ElevenLabs |
| clip40 | 0.682 | 0.682 | 0.309 | 0.245 | Tie |
| clip41 | 0.800 | 0.267 | 0.217 | 0.066 | ElevenLabs |
| clip42 | 0.833 | 0.417 | 0.253 | 0.203 | ElevenLabs |
| clip43 | 1.059 | 0.529 | 0.233 | 0.093 | ElevenLabs |
| clip44 | 1.000 | 0.571 | 0.433 | 0.156 | ElevenLabs |
| clip45 | 0.923 | 0.538 | 0.298 | 0.149 | ElevenLabs |
| clip46 | 1.000 | 0.667 | 0.318 | 0.209 | ElevenLabs |
| clip47 | 0.933 | 0.600 | 0.253 | 0.200 | ElevenLabs |
| clip48 | 0.789 | 0.789 | 0.216 | 0.351 | Tie |
| clip49 | 0.619 | 0.476 | 0.169 | 0.113 | ElevenLabs |
| clip50 | 0.875 | 0.125 | 0.214 | 0.020 | ElevenLabs |

---

## Notable Clips

### Best ElevenLabs performance — clip50 (WER 0.125)

```
REF:        maalaa Guriga dadka soo dhisay ma aragtay? Waxaa yimid arday badan. Waxaa aan jeclaa Emma. gurigaygan
ElevenLabs: Maalaa guriga dadka soo dhisay ma aragtay. Waxaay yimid arday badan waxa aan jeclaa emma gurigaygan.
Whisper:    maa laa guriga dadka saadisay maa raqday waha yimid ardaybadan waha ancha laa emma guriga igan
```
ElevenLabs near-perfectly transcribes a full sentence. Whisper mangles several words ("saadisay" for "soo dhisay", "raqday" for "aragtay").

---

### Best ElevenLabs performance — clip36 (WER 0.263)

```
REF:        Hargeysa waa magaalo weyn. Kani waa kaanaga. Warsame! farasey! Waan aqaannaa ardayda oo idil. maxkamadda gobolka qorayaasha iyo boqorrada
ElevenLabs: Hargeysa waa magaalo weyn. Kani waa kaannada. Warsame. Farasay. Waan aqaana ardayda oo idil. Maxkamadda gobolka. Qorshaha iyo boqorada.
Whisper:    Har geysa waa magaalaa weyn. Kani waa kaan naga. Huwar samay. Farasay. Waan aqaanaa radaayda oo eedil. Mahkamadda goblka. Urayaasha iyo baxar rada.
```
ElevenLabs preserves proper nouns ("Hargeysa", "Warsame", "Maxkamadda") and sentence structure. Whisper splits tokens incorrectly and garbles proper nouns.

---

### Worst ElevenLabs performance — clip11 (WER 1.000)

```
REF:        goror caanaha saca raggaa Saddexda wiil ayaad ammaantay. OSV Dhiso. maalmo afar ah oo horreysay
ElevenLabs: Wuxuu u geystay qorayn ayaa ah goorar. Canaan saac. Ragga. Saddex daweyl ayaa dambe. Dhiso. Maalmo afar ah oo horaysay.
Whisper:    qorar aanaha saad ragga sada dhawiyil aya dhammaante diso maalmo qafar ah oo horay say
```
A clip with annotation artifacts ("OSV", pipe characters in the ground truth) threw off ElevenLabs — it appears to have hallucinated structure around ambiguous audio. Whisper at least echoed more of the phonetic surface form.

---

### Biggest gap — clip28 (WER: Whisper 1.438 vs ElevenLabs 0.875)

```
REF:        qalimmada silsiladahayga dukaanle Ninkii libaaxii qabtay miyuu la hadlay? S/SOVAV baaldiyo labo ganacsato oo waawanaagsan
ElevenLabs: Xalammada silsiladaha iga dukaan leh ninkii libaaxi qabtay miyu la hadlay baal diyo laba ganacsi ugu wanaagsan.
Whisper:    Qalima dha. Silsila dhaha yiga. Du kaan la. Ninkin li baax hii qabtay. Miuu lahad la. Baal diyo. La baga naa sato'u buwan-buwan ahaksan.
```
Whisper fragments continuous speech into spurious sentence breaks, yielding extra tokens and inflating WER past 1.0. ElevenLabs handles the run-on sentence structure much better.

---

## Interpretation of WER Values

The overall WER figures (0.59–0.87) appear high but are partly an artifact of the evaluation setup:

1. **Short reference clips inflate WER** — many source clips are single words or short phrases (e.g. "beertaada", "waax"). A single substitution on a 1-word reference gives WER = 1.0 or higher. CER is a more stable metric here.

2. **Annotation noise in the dataset** — 17 of 50 references (34%) contain artifacts like `|`, `S/SOVAV`, and `OSV`. A cleaning pass was run and re-scored; the aggregate WER shift was ±0.002, effectively zero. See Methodological Notes for the full analysis.

3. **Stitching discontinuity** — adjacent source clips come from different speakers and contexts. Models that rely on contextual coherence (especially ElevenLabs' language model) may be partially confused by abrupt topic changes mid-clip.

4. **CER tells a cleaner story** — ElevenLabs' mean CER of 0.185 indicates it gets the character sequence roughly 81.5% correct, which is consistent with usable transcription quality for a low-resource language.

---

## Comparison to SomBench v0

SomBench v0 (June 2026) ran a reference-free pass on 11 clips from two YouTube videos with no ground truth. Key differences:

| | v0 | v1 |
|---|---|---|
| Ground truth | None | HF dataset transcriptions |
| Clips | 11 (60s each, 2 videos) | 50 (10s each, HF test split) |
| Speakers | ~2 (BBC news, religious lecture) | Many (crowdsourced) |
| Script mismatches | Present (Whisper emitted Arabic) | None for either system |
| WER/CER | Not measured | Measured |

The absence of Arabic-script hallucinations in v1 compared to v0 may reflect the shorter clip length — Whisper's script confusion in v0 tended to emerge on longer clips where the model drifted.

---

## Methodological Notes

### Somali Orthography and Text Normalization

The scoring pipeline uses the following normalization (from `score.py`):

```python
_PUNCT = re.compile(r"[^\w\s']", flags=re.UNICODE)

def normalize(text):
    text = unicodedata.normalize("NFKC", text).lower()
    text = _PUNCT.sub(" ", text)
    return re.sub(r"\s+", " ", text).strip()
```

**Capitalization of proper nouns** — handled correctly. `.lower()` is applied before any comparison, so mid-sentence "Muqdisho" and "muqdisho" are treated identically. This is a non-issue.

**Apostrophes for glottal stops** — the regex explicitly preserves ASCII apostrophe `U+0027` (e.g., `go'aan` → `go'aan`). However there is a latent inconsistency: `U+2019 RIGHT SINGLE QUOTATION MARK` (the "curly" apostrophe used by some editors and ASR outputs) is treated as punctuation and stripped, while `U+02BC MODIFIER LETTER APOSTROPHE` survives because `\w` matches it under Unicode. In practice this dataset uses **zero apostrophes** in its reference transcriptions — Somali pharyngeal sounds are encoded as standard Latin letters (`c`, `x`) rather than apostrophes — so this is a latent bug, not an active WER distortion in these results. It should be fixed before applying this scorer to other Somali datasets that do use apostrophes (e.g., some diaspora transcription conventions).

**Fix for future runs:**

```python
def normalize(text):
    text = unicodedata.normalize("NFKC", text)
    # Collapse all apostrophe variants to ASCII before lowercasing
    text = re.sub(r"['’ʼ`´]", "'", text)
    text = text.lower()
    text = re.sub(r"[^\w\s']", " ", text, flags=re.UNICODE)
    return re.sub(r"\s+", " ", text).strip()
```

---

### Annotation Artifacts: Measured Impact vs. Intuition

**17 of 50 clips** (34%) contain at least one annotation artifact in the ground-truth reference:

| Artifact type | Clips affected | What it is |
|---|---|---|
| `\|` (pipe) | 14 clips | Word-boundary or pause marker used by annotators |
| `OSV`, `SOV`, `SVO` | 5 clips | Syntactic word-order labels that leaked into transcriptions |
| `SOVAV` | 1 clip | Extended annotation label |

**Measured WER impact after removing all artifacts and re-scoring:**

| System | WER (original) | WER (cleaned refs) | Delta |
|---|---|---|---|
| ElevenLabs Scribe v1 | 0.592 | 0.591 | −0.001 |
| faster-whisper large-v3 | 0.871 | 0.873 | +0.002 |

The aggregate effect is **effectively zero** — under ±0.002 WER. This is counterintuitive but explainable:

1. **Pipe characters `|` were already handled.** The existing `_PUNCT` regex strips `|` as punctuation, then `_WS` collapses the resulting whitespace. So `Ma beer|f baa?` already normalizes to `ma beer f baa` under both the old and new pipeline — no change.

2. **`OSV`/`SOV` tokens are one word in a ~18-word reference.** Removing one spurious word from an 18-word reference changes the WER denominator by ~5%. That's small, and the direction isn't always favorable: on clip28 Whisper's WER actually *increases* from 1.438 → 1.533 after cleaning because the SOVAV token happened to absorb a deletion penalty.

3. **Cleaning can make WER worse on individual clips** (clip11 ElevenLabs: 1.000 → 1.071; clip28 Whisper: 1.438 → 1.533). Removing a reference word shrinks the denominator, inflating WER when the hypothesis already has spurious insertions at that position.

**Recommendation for the paper:** Include the cleaned re-score as a robustness check (the ±0.002 delta is the honest answer to reviewer concerns), but note that the headline numbers are effectively unchanged. The more important caveat is not artifact tokens but the stitching methodology itself — see Limitations below.

---

## Limitations

- **Stitching artifacts**: 200ms silence gaps between unrelated clips from different speakers create unnatural audio. No production ASR system is designed for abrupt mid-clip topic and speaker changes. Results on natural continuous speech would likely differ substantially.
- **Short reference inflation**: Many source clips are single words or short phrases. A single substitution on a 1-word reference yields WER ≥ 1.0 regardless of ASR quality. CER is the more interpretable metric for this evaluation.
- **Ground truth not re-verified**: The `skydheere/soomali-asr-dataset` transcriptions were taken as-is. Annotation artifacts affect 34% of clips at the token level, but the measured WER impact is < 0.002 aggregate (see above).
- **Single run per (clip, system)**: No variance estimate. ElevenLabs Scribe v1 is deterministic for a given input; faster-whisper large-v3 with `beam_size=5` is also deterministic. Re-running would produce identical results.
- **Dataset speaker profile**: The HF dataset has a specific speaker and recording profile (likely crowdsourced read speech). Generalization to broadcast Somali news, telephone speech, or dialectal variation (Benaadir vs. Northern) is not established.
- **Apostrophe normalization latent bug**: Curly apostrophes (`U+2019`) used for glottal stops in some Somali transcription conventions are incorrectly stripped. No impact on this dataset; must be fixed before applying to other corpora.

---

## Files

| File | Description |
|---|---|
| `results/sombench_v1.json` | Full results with per-clip rows, system metadata, and summary |
| `results/sombench_v1.csv` | Per-clip WER/CER with hypothesis and reference text |
| `transcripts/somali_public/clip*_whisper.json` | faster-whisper transcript outputs (50 files) |
| `transcripts/somali_public/clip*_elevenlabs.json` | ElevenLabs transcript outputs (50 files) |
| `audio/somali_public/clip01–50.wav` | Stitched WAV files used as input |
| `references/somali_public/clip01–50.txt` | Ground-truth reference transcriptions |
| `build_somali_public.py` | Script that built the stitched clips from the HF dataset |
| `run_sombench_v1.py` | Script that ran ASR and scoring for this benchmark |
