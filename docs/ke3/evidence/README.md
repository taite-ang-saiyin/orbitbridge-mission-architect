# KE3 branch verification

The portable runner was executed against these branch sources before publication:

```text
python tools/ke3/verify.py --godot <installed Godot 4.7.2 Standard console> --output-dir <new external directory> --mode all
```

Actual result: **35 commands passed, 0 failed; runner exit 0**. No script/parser errors. All four viewport processes passed **91 checks each** (1280x720,1024x768,900x680 and an independent1024x768 repeat); semantic repeatability passed. The original A07 scroll/clipping assertions remain active.

Headless/windowed suite counts: A02 254/255; A03 256/259; A04 206/210; separate A04 restart9/10 each process; A05 139/156; A06 100/104; old recorded report49/52; validated report63/67; contract-error/empty-cause/abort display edges24/29. A01 empty views, project import and selected UI/preview scene starts also passed.

The runner builds an isolated project using the committed preview config template. It does not alter or test SE's mock main journey as a real integration. B02 and official B10 remain NOT TESTED.

Exact per-suite exit/status/summary is in verification-summary.json. Prior packet/provider context is in prior-results.json. Large local logs/screenshots/cache are excluded; the runner reproduces fresh inspectable output on another developer's machine. JSON report hashes must retain original bytes, protected by the fixture-local .gitattributes files.
