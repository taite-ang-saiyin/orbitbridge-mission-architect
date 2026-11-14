extends "res://preview/a04_preview.gd"
## Explicit A05 entry. Production history/ledger and Retry lifecycle stay pending.

var _readiness_notice: Label


func _ready() -> void:
	super._ready()
	var notice := MarginContainer.new()
	notice.name = "ReadinessNotice"
	_readiness_notice = Label.new()
	_readiness_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_child(_readiness_notice)
	_tabs.add_child(notice)
	select_fixture("debrief_partial")


func _make_provider() -> RefCounted:
	return preload("res://preview/a05_provider.gd").new(self)


func _entry_banner() -> String:
	return "SYNTHETIC A05 PREVIEW | KE2 REPORT EXAMPLES | REAL LEDGER / HISTORY PENDING"


func _case_prefix() -> String:
	return "SYNTHETIC A05 / "


func select_fixture(case_id: String) -> Dictionary:
	var reply: Dictionary = super.select_fixture(case_id)
	if case_id.begins_with("debrief_"):
		if case_id == "debrief_prelaunch" and is_instance_valid(_readiness_notice):
			_readiness_notice.text = "SYNTHETIC READINESS NOTICE\n" + str(operations.get_input_snapshot().context.get("readiness_message", "Unavailable")) + "\nProduction Readiness routing remains owned by SE."
			_tabs.current_tab = 2
		else:
			_tabs.current_tab = 1
	return reply
