# JioSaavn Debugging Cheat Sheet

## Quick Log Filtering

### View Only JioSaavn Logs
```bash
flutter run | grep "\[JioSaavn\]"
```

### View Only Search Flow
```bash
flutter run | grep "\[Music"
```

### View With Timestamps
```bash
flutter run 2>&1 | grep -E "\[JioSaavn\]|\[MusicProvider\]|\[MusicSourceManager\]"
```

---

## One-Minute Diagnosis

### App shows NO RESULTS
**Check these logs in order:**

1. **Did JioSaavn get queried?**
   ```
   [JioSaavn] Starting song search: "your query"
   ```
   If missing → Search never reached service

2. **What was the API response?**
   ```
   [JioSaavn] Attempt 1: Response status 200, body length: 5000
   ```
   - 200 = ✓ Good
   - 404 = No results on JioSaavn
   - 429/503 = Rate limited
   - Others = Error

3. **Was response parsed correctly?**
   ```
   [JioSaavn] Format 1 detected: data.data.results (15 items)
   ```
   - If missing = Unknown format

4. **Do songs have audio URLs?**
   ```
   [JioSaavn] ✓ Item 0: "Song Title" by Artist
   [JioSaavn] ✗ Item 3: - No audio URL
   ```
   - Count ✓ vs ✗ marks

5. **Final result**
   ```
   [JioSaavn] ✓ SUCCESS: Found 14 songs with valid audio URLs
   ```

---

## Success Signature

When everything works:
```
[JioSaavn] Starting song search: "query"...
[JioSaavn] Attempt 1: Response status 200, body length: XXXX
[JioSaavn] Format 1 detected: data.data.results (N items)
[JioSaavn] Parsing N song items...
[JioSaavn]   Item 0: ✓ "Song" by Artist (url: https://...)
[JioSaavn] Parsed M/N songs successfully
[JioSaavn] ✓ SUCCESS: Found M songs with valid audio URLs
```

---

## Error Signatures

### Network Error (Will Retry)
```
[JioSaavn] ✗ Network/Exception Error (Attempt 1/2): SocketException: Network is unreachable
[JioSaavn] Retrying in 500ms...
[JioSaavn] ✗ Network/Exception Error (Attempt 2/2): ...
[MusicSourceManager] 2️⃣ JioSaavn error (network), falling back to YouTube...
```
**Solution:** Check internet connection

### Rate Limited (Will Auto-Retry)
```
[JioSaavn] ✗ Rate limited (429). Attempt 1/2, retrying...
[JioSaavn] Attempt 2: Response status 200, body length: ...
[JioSaavn] ✓ SUCCESS: Found X songs
```
**Solution:** Wait & retry (automatic after 500ms delay)

### Not Found (Expected)
```
[JioSaavn] ✗ 404: Query not found on JioSaavn
[MusicSourceManager] No songs found on JioSaavn but no error (valid empty result)
```
**Solution:** None needed (fallback doesn't happen, which is correct)

### Unknown Format (Needs Fix)
```
[JioSaavn] Response keys: ['different', 'keys', 'here']
[JioSaavn] ✗ Could not match any response format
```
**Solution:** Update `_extractResults()` in `jiosaavn_service.dart`

### No Audio URLs (Needs Investigation)
```
[JioSaavn] Parsing 10 song items...
[JioSaavn]   Item 0: ✗ "Song" - No audio URL
[JioSaavn]   Item 1: ✗ "Song 2" - No audio URL
[JioSaavn] Parsed 0/10 songs successfully
```
**Solution:** Check API response format for `downloadUrl` field

---

## Log Location Reference

| Component | File | Log Prefix |
|-----------|------|-----------|
| API Service | `jiosaavn_service.dart` | `[JioSaavn]` |
| Search Orchestrator | `music_source_manager.dart` | `[MusicSourceManager]` |
| UI State Manager | `music_provider.dart` | `[MusicProvider]` |
| Search Specifically | `music_provider.dart` | `[MusicProvider.Search]` |

---

## Critical Log Patterns

### Pattern 1: Successful Search
```
✓ SUCCESS: Found N songs with valid audio URLs
```
→ **ALL GOOD** - Results will be shown to user

### Pattern 2: Empty but Valid
```
No songs found on JioSaavn but no error (valid empty result)
⏭️ Skipping YouTube
```
→ **Expected** - No matching songs on JioSaavn (acceptable)

### Pattern 3: Error with Fallback
```
2️⃣ JioSaavn error (network), falling back to YouTube...
YouTube returned N songs
```
→ **OK** - YouTube will provide results

### Pattern 4: API Changed
```
Could not match any response format
[response keys shown above]
```
→ **ACTION NEEDED** - Update response parsing

---

## Response Format Quick Reference

### Format 1 (Most Common)
```json
{
  "data": {
    "results": [
      { "id": "...", "name": "Song", "downloadUrl": [...], ... },
      ...
    ]
  }
}
```
Log: `Format 1 detected: data.data.results (N items)`

### Format 2
```json
{
  "results": [
    { "id": "...", "name": "Song", ... },
    ...
  ]
}
```
Log: `Format 2 detected: results (N items)`

### Format 3
```json
{
  "id": "...",
  "name": "Song Title",
  "downloadUrl": [...]
}
```
Log: `Format 3 detected: Single song object`

---

## Test Commands

### Search Test
```
User searches for: "arijit singh"
↓
[MusicProvider.Search] Starting search for: "arijit singh"
[MusicSourceManager] Starting unified search: "arijit singh"
[JioSaavn] Starting song search: "arijit singh"
[JioSaavn] ✓ SUCCESS: Found 20 songs
[MusicProvider.Search] ✓ Got 20 songs from MusicSourceManager
[MusicProvider.Search] Search complete. Total results: 20
```

### Home Page Load
```
App opens
↓
[MusicProvider] Loading home data...
[MusicSourceManager] Loading home data (trending + new releases)...
[MusicSourceManager] Fetching trending songs...
[JioSaavn] Starting song search: "trending songs india"
[JioSaavn] ✓ SUCCESS: Found 20 songs
[MusicSourceManager] Trending: Got 20 songs from JioSaavn
[MusicSourceManager] Home data loaded: 20 trending, 18 new releases
[MusicProvider] ✓ Loaded: 20 trending, 18 new releases
```

---

## Key Success Indicators

✅ **Expected to see:**
- `[JioSaavn] Attempt 1: Response status 200`
- `[JioSaavn] Format X detected`
- `[JioSaavn] Parsing N song items...`
- `[JioSaavn] ✓ Item X: "Title" by Artist`
- `[JioSaavn] Parsed M/N songs successfully`
- `[JioSaavn] ✓ SUCCESS: Found X songs`

❌ **Red flags:**
- No `[JioSaavn]` logs at all → Service not called
- `Response status 500` → Server error
- `Could not match any response format` → Format changed
- All items marked `✗ - No audio URL` → Missing field
- `Parsed 0/N songs` → No valid results

---

## Common Fixes Quick Links

| Symptom | Log | Fix |
|---------|-----|-----|
| No results | `Parsed 0/N` | Check API response has `downloadUrl` |
| 404 errors | `✗ 404: Query` | Normal - try different query |
| Network error | `SocketException` | Check internet & API endpoint |
| Unknown format | `Could not match` | Add new format to `_extractResults()` |
| Null errors | `Parse error: null` | Fix nullable field handling |
| Rate limited | `Rate limited (429)` | Retry after delay (auto-handles) |

---

## Real-Time Monitoring Command

Watch logs in real-time with colors:
```bash
flutter run 2>&1 | grep --color=auto "\[JioSaavn\]\|\[Music"
```

Or save to file:
```bash
flutter run > debug_logs.txt 2>&1
```

Then search:
```bash
grep "\[JioSaavn\]" debug_logs.txt
```

---

## Debugging Flowchart

```
Search request received
        ↓
[MusicProvider.Search] Starting search
        ↓
[MusicSourceManager] Starting unified search
        ↓
[JioSaavn] Starting song search
        ↓
    HTTP Request
        ↓
Response Status?
  ├─ 200? → Check "Format X detected"
  ├─ 404? → Not found (OK)
  ├─ 429? → Rate limited (retrying...)
  ├─ 5xx? → Server error
  └─ Other? → Unknown error
        ↓
Songs have audioUrl?
  ├─ YES? → ✓ SUCCESS
  └─ NO? → Parsed 0/N (issue)
        ↓
Show results or fallback to YouTube
```

---

## Support Matrix

| Error | Retry? | Fallback? | Action |
|-------|--------|-----------|--------|
| Network | ✓ (1x) | ✓ YouTube | Check internet |
| 404 | ✗ | ✗ | Normal |
| 429/503 | ✓ (1x) | ✓ YouTube | Wait & retry |
| 500 | ✗ | ✗ | Server issue |
| Invalid data | ✗ | ✓ YouTube | Update parser |
| No audio URL | ✗ | ✗ | Check API response |

---

Last Updated: 2026-05-12
