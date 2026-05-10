.per_tool
| to_entries
| map(select(.key != "unknown"))
| sort_by(-(.value.saved // 0))
| .[0:3]
| map("- **\(.key)** -- \(.value.saved // 0) tokens saved (\(.value.count // 0) calls)")
| join("\n")
