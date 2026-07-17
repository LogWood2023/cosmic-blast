class_name BalanceManifestData
extends Resource

## Provenance and drift-detection metadata for generated balance Resources.
@export var schema_version: String = ""
@export var content_version: String = ""
@export var source_path: String = "res://data/balance/master_balance.tsv"
@export var source_sha256: String = ""
@export var total_records: int = 0
@export var domain_counts: Dictionary = {}
