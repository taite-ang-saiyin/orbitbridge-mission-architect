extends RefCounted
## Session-only UI preferences. No file persistence or OS settings changes.
const DEFAULTS = {"language": "en", "theme": "midnight"}
const COPY = {
	"en": {"start": "Start Mission", "settings": "Settings", "quit": "Quit", "tagline": "Design  ·  Plan  ·  Execute", "language": "Language", "theme": "Theme", "close": "Done", "note": "Language applies to Home and Settings in this prototype.\nMission workflow screens currently use English.", "heading": "Make space your own.", "session": "Changes apply immediately for this session.", "footer": "MISSION DESIGN SANDBOX", "hint": "A new perspective starts with a mission."},
	"zh": {"start": "开始任务", "settings": "设置", "quit": "退出", "tagline": "设计  ·  规划  ·  执行", "language": "语言", "theme": "主题", "close": "完成", "note": "此原型的语言设置适用于主页和设置。\n任务流程页面目前使用英文。", "heading": "开启你的太空视角。", "session": "修改立即生效，仅保留于本次会话。", "footer": "任务设计沙盒", "hint": "全新视角，从一次任务开始。"}
}
static func word(settings: Dictionary, key: String) -> String:
	return COPY.get(settings.get("language", "en"), COPY.en).get(key, key)
