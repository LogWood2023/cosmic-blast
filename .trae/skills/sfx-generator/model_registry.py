DEFAULT_MODEL_CHAIN = [
    "facebook/audiogen-medium",
    "declare-lab/tango2",
    "declare-lab/tango-full-ft-audiocaps",
    "cvssp/audioldm2",
    "facebook/musicgen-small",
]

CATEGORY_MODEL_CHAINS = {
    "weapon": [
        "facebook/audiogen-medium",
        "declare-lab/tango-full-ft-audiocaps",
        "declare-lab/tango2",
        "cvssp/audioldm2",
        "facebook/musicgen-small",
    ],
    "impact": [
        "facebook/audiogen-medium",
        "declare-lab/tango-full-ft-audiocaps",
        "cvssp/audioldm2",
        "declare-lab/tango2",
        "facebook/musicgen-small",
    ],
    "explosion": [
        "facebook/audiogen-medium",
        "cvssp/audioldm2",
        "declare-lab/tango-full-ft-audiocaps",
        "declare-lab/tango2",
        "facebook/musicgen-small",
    ],
    "environment": [
        "cvssp/audioldm2",
        "facebook/audiogen-medium",
        "declare-lab/tango2",
        "declare-lab/tango-full-ft-audiocaps",
        "facebook/musicgen-small",
    ],
    "ambient": [
        "cvssp/audioldm2",
        "declare-lab/tango2",
        "facebook/musicgen-small",
        "facebook/audiogen-medium",
    ],
    "ui": [
        "facebook/audiogen-medium",
        "declare-lab/tango-full-ft-audiocaps",
        "facebook/musicgen-small",
    ],
    "vehicle": [
        "facebook/audiogen-medium",
        "cvssp/audioldm2",
        "declare-lab/tango2",
        "facebook/musicgen-small",
    ],
    "creature": [
        "facebook/audiogen-medium",
        "declare-lab/tango-full-ft-audiocaps",
        "cvssp/audioldm2",
        "facebook/musicgen-small",
    ],
    "voice": [
        "declare-lab/tango2",
        "cvssp/audioldm2",
        "facebook/audiogen-medium",
    ],
    "other": DEFAULT_MODEL_CHAIN,
}

MODEL_NOTES = {
    "facebook/audiogen-medium": "Meta AudioGen，偏真实音效/环境声，优先用于游戏 SFX。",
    "declare-lab/tango2": "Tango 2，通用 text-to-audio，适合复杂声音描述。",
    "declare-lab/tango-full-ft-audiocaps": "Tango AudioCaps 微调版，偏自然/人工声效描述。",
    "cvssp/audioldm2": "AudioLDM2，适合真实声效、人声和氛围音。",
    "facebook/musicgen-small": "MusicGen 轻量备用，在线可用性通常较好，但更偏音乐。",
}


def normalize_model_value(model: str | None) -> str:
    if not model:
        return "auto"
    return model.strip()


def get_model_chain(category: str, model: str | None = None) -> list[str]:
    normalized = normalize_model_value(model)
    if normalized and normalized != "auto":
        return [normalized]
    return list(CATEGORY_MODEL_CHAINS.get(category, DEFAULT_MODEL_CHAIN))


def describe_model_chain(category: str, model: str | None = None) -> str:
    chain = get_model_chain(category, model)
    return " -> ".join(chain)
