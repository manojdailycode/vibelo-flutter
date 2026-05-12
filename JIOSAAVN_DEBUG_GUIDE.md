# JioSaavn Debugging Guide

## Overview
Comprehensive logging has been added to all JioSaavn-related services to help identify issues. All logs are prefixed with `[JioSaavn]`, `[MusicProvider]`, or `[MusicSourceManager]` for easy filtering.

---

## Debug Logs Location

### 1. **JioSaavnService** (`lib/services/jiosaavn_service.dart`)
Main service handling API calls and parsing.

#### Key Logs:
- **Search Initialization**: `[JioSaavn] Starting song search: "{query}" (limit: X, baseUrl: URL)`
  - Shows the query, result limit, and API base URL being used
  
- **Attempt Status**: `[JioSaavn] Attempt X: GET {URL}`
  - Shows which attempt (1 or 2) and the full API URL
  
- **Response Status**: `[JioSaavn] Attempt X: Response status YYY, body length: Z`
  - HTTP status code and response size
  
- **Parsing Status**: `[JioSaavn] Parsed N results from response`
  - Number of raw song items extracted
  
- **Response Format Detection**:
  - `[JioSaavn] Format 1 detected: data.data.results (N items)` → Nested structure
  - `[JioSaavn] Format 2 detected: results (N items)` → Simple array
  - `[JioSaavn] Format 3 detected: Single song object` → Direct object
  - `[JioSaavn] Could not match any response format` → **Issue: Unknown API response format**
  
- **Success**: `[JioSaavn] ✓ SUCCESS: Found N songs with valid audio URLs`
  
- **Failure Logs**:
  - `[JioSaavn] ✗ 404: Query not found on JioSaavn` → Query has no results
  - `[JioSaavn] ✗ Rate limited (429/503). Attempt X/2` → Service rate limited
  - `[JioSaavn] ✗ HTTP Error: XXX` → Other HTTP errors
  - `[JioSaavn] ✗ Network/Exception Error (Attempt X/2): ERROR_MSG` → Connection issues

#### Song Parsing Logs:
```
[JioSaavn] Parsing N song items...
[JioSaavn]   Item 0: ✓ "Song Title" by Artist Name (url: https://...)
[JioSaavn]   Item 1: ✗ "Bad Song" - No audio URL
[JioSaavn]   Item 2: ✗ Parse error: ErrorMsg (title: problematic song)
[JioSaavn] Parsed M/N songs successfully
```
- Shows which songs have audio URLs and which don't
- **Orange flag**: Songs without audio URLs are filtered out

#### Album/Artist Search Logs:
- `[JioSaavn] Album search: Found N albums`
- `[JioSaavn] Artist search: Found N artists`
- `[JioSaavn] Album search failed: HTTP XXX`

---

### 2. **MusicSourceManager** (`lib/providers/music_source_manager.dart`)
Orchestrates search across multiple sources with priority.

#### Key Logs:
- **Search Start**: `[MusicSourceManager] Starting unified search: "query"`
  
- **JioSaavn Query**: 
  ```
  [MusicSourceManager] 1️⃣ Querying JioSaavn...
  [MusicSourceManager] JioSaavn returned N songs
  ```
  
- **Fallback Decision**:
  - If JioSaavn succeeded: `[MusicSourceManager] ⏭️ Skipping YouTube (JioSaavn successful with N results)`
  - If JioSaavn failed: `[MusicSourceManager] 2️⃣ JioSaavn error (ERROR_TYPE), falling back to YouTube...`
  - If empty results: `[MusicSourceManager] No songs found on JioSaavn but no error (valid empty result)`
  
- **YouTube Fallback**: `[MusicSourceManager] YouTube returned N songs`

- **Error Type Decision**:
  ```
  [MusicSourceManager._canFallbackToYouTube] Error: ERROR_TYPE → fallback: true/false
  ```
  - `network` → fallback: **YES**
  - `rateLimited` → fallback: **YES**
  - `invalidData` → fallback: **YES**
  - `noResults` → fallback: **NO** (empty is valid)
  - `notFound` → fallback: **NO**
  - `null` (success) → fallback: **NO**

- **Search Complete**: `[MusicSourceManager] ✓ Search complete: N songs, M albums, P artists`

#### Home Data Logs:
```
[MusicSourceManager] Loading home data (trending + new releases)...
[MusicSourceManager] Fetching trending songs...
[MusicSourceManager] Trending: Got N songs from YouTube/JioSaavn
[MusicSourceManager] Fetching new releases...
[MusicSourceManager] New releases: Got N songs from JioSaavn/YouTube
[MusicSourceManager] Home data loaded: N trending, M new releases
```

---

### 3. **MusicProvider** (`lib/providers/music_provider.dart`)
UI provider managing state and user interactions.

#### Key Logs:
- **Home Load**: 
  ```
  [MusicProvider] Loading home data...
  [MusicProvider] Fetching trending and new releases from MusicSourceManager...
  [MusicProvider] ✓ Loaded: N trending, M new releases
  ```
  
- **Search Start**: `[MusicProvider.Search] Starting search for: "query"`

- **Search Progress**:
  ```
  [MusicProvider.Search] Calling MusicSourceManager.searchAll...
  [MusicProvider.Search] ✓ Got N songs from MusicSourceManager
  [MusicProvider.Search] Search complete. Total results: N
  ```

- **Fallback**: `[MusicProvider.Search] ✗ MusicSourceManager failed: ERROR`
  ```
  [MusicProvider.Search] Trying direct JioSaavn search...
  [MusicProvider.Search] JioSaavn direct: N songs
  ```

- **Error Reporting**:
  ```
  [MusicProvider.Search] JioSaavn had error (but fallback succeeded): ERROR_TYPE: ERROR_MSG
  [MusicProvider.Search] ✗ No results and error: JioSaavn error (ERROR_TYPE). Unable to search right now.
  ```

---

## Common Issues & Solutions

### Issue 1: No Results Found (Empty List)
**Logs to check:**
```
[JioSaavn] Starting song search: "query"...
[JioSaavn] Parsed N results from response
[JioSaavn] Parsing N song items...
[JioSaavn] ✗ Item X - No audio URL
[JioSaavn] Parsed 0/N songs successfully
```

**Solutions:**
- Songs exist but have no `downloadUrl` → API changed response format
- Check if response format changed: Look for `Format X detected` log
- **Action**: Update `_extractResults()` method to handle new format

---

### Issue 2: HTTP 404 Errors
**Logs to check:**
```
[JioSaavn] ✗ 404: Query not found on JioSaavn
[MusicSourceManager] No songs found on JioSaavn but no error (valid empty result)
```

**Explanation:** Query has no results on JioSaavn, will fall back to YouTube

**Not an issue** — Expected behavior for niche queries

---

### Issue 3: Network/Connection Errors
**Logs to check:**
```
[JioSaavn] ✗ Network/Exception Error (Attempt 1/2): {ERROR_MESSAGE}
[JioSaavn] Retrying in 500ms...
[JioSaavn] ✗ Network/Exception Error (Attempt 2/2): {ERROR_MESSAGE}
[MusicSourceManager] 2️⃣ JioSaavn error (network), falling back to YouTube...
```

**Solutions:**
- Check internet connection
- Check if `https://saavn.dev` is accessible
- Retry manually

---

### Issue 4: Rate Limiting (429/503)
**Logs to check:**
```
[JioSaavn] ✗ Rate limited (429). Attempt 1/2, retrying...
[JioSaavn] ✓ SUCCESS: Found N songs (after retry)
```

**Or if retry fails:**
```
[JioSaavn] ✗ Rate limited (429). Attempt 2/2, giving up
[MusicSourceManager] 2️⃣ JioSaavn error (rateLimited), falling back to YouTube...
```

**Solutions:**
- Rate limit will auto-retry once
- If persistent, wait a bit before retrying
- Consider adding delay between searches

---

### Issue 5: Invalid Response Format
**Logs to check:**
```
[JioSaavn] Could not match any response format
[JioSaavn] ✗ Parse error: {ERROR_DETAILS}
```

**Solutions:**
1. Check what keys are in response: Look for `Response keys: [...]`
2. Add new format to `_extractResults()` method
3. Test with `debugResponse.json` containing the actual API response

---

## How to Enable Debug Logging

Logs are automatically enabled. To view them:

### In VS Code Flutter Inspector:
1. Run app: `flutter run`
2. Open "Debug Console" in VS Code
3. Filter by `[JioSaavn]`, `[MusicProvider]`, or `[MusicSourceManager]`

### In Android Studio:
1. Run app: `flutter run`
2. Open "Logcat"
3. Filter by tag name

### In Terminal:
```bash
flutter run | grep "\[JioSaavn\]\|\[MusicProvider\]\|\[MusicSourceManager\]"
```

---

## Debugging Workflow

### Step 1: Check if API is accessible
```
[JioSaavn] Starting song search: "test"
[JioSaavn] Attempt 1: GET https://saavn.dev/api/search/songs?query=test&limit=20
[JioSaavn] Attempt 1: Response status 200, body length: 5234
```
✓ If you see `200`, API is working

### Step 2: Check if response is parseable
```
[JioSaavn] Response keys: ['data', 'status', 'error']
[JioSaavn] Format 1 detected: data.data.results (15 items)
```
✓ If format is detected, parsing should work

### Step 3: Check if songs have audio URLs
```
[JioSaavn] Parsing 15 song items...
[JioSaavn]   Item 0: ✓ "Song Title" by Artist
[JioSaavn]   Item 1: ✓ "Another Song" by Artist  
[JioSaavn]   Item 14: ✗ "Bad Song" - No audio URL
[JioSaavn] Parsed 14/15 songs successfully
```
✓ If audio URLs are present, songs will play

### Step 4: Check fallback logic
```
[MusicSourceManager] 1️⃣ Querying JioSaavn...
[MusicSourceManager] JioSaavn returned 0 songs
[MusicSourceManager] No songs found on JioSaavn but no error (valid empty result)
[MusicSourceManager] ⏭️ Skipping YouTube (empty result is valid, not an error)
```
✓ Shows that YouTube is NOT called if JioSaavn returns empty (correct)

---

## Error Types Reference

```dart
enum JioSaavnErrorType {
  network,      // No internet / timeout → FALLBACK to YouTube
  invalidData,  // Bad JSON / parsing error → FALLBACK to YouTube
  noResults,    // Empty results (404 not included) → NO fallback (valid)
  rateLimited,  // HTTP 429 or 503 → AUTO-RETRY, then fallback if fails
  notFound,     // HTTP 404 (API says doesn't exist) → NO fallback
  unknown,      // Other HTTP errors → NO fallback (unclear state)
}
```

---

## Testing

### Test Query: "Trending Songs India"
**Expected logs:**
```
[JioSaavn] Starting song search: "trending songs india"
[JioSaavn] ✓ SUCCESS: Found 15+ songs with valid audio URLs
```

### Test Query: "ZZZZZZZZZZ" (gibberish)
**Expected logs:**
```
[JioSaavn] ✗ 404: Query not found on JioSaavn
[MusicSourceManager] No songs found on JioSaavn but no error
[MusicSourceManager] ⏭️ Skipping YouTube
```

### Test with Network Disabled
**Expected logs:**
```
[JioSaavn] ✗ Network/Exception Error (Attempt 1/2): SocketException...
[JioSaavn] Retrying in 500ms...
[JioSaavn] ✗ Network/Exception Error (Attempt 2/2): SocketException...
[MusicSourceManager] 2️⃣ JioSaavn error (network), falling back to YouTube...
```

---

## Summary

✅ **What Works:**
- Multi-format response handling
- Automatic retry on transient errors
- Smart fallback (YouTube only on real errors)
- Audio URL validation
- Comprehensive error tracking

📊 **What to Monitor:**
- Empty results without errors → Valid, not an issue
- Network errors with retries → OK, fallback will help
- 404s → OK, expected for unsupported queries
- 429/503 → OK, auto-retries and falls back

🔍 **How to Debug:**
1. Scan logs for `[JioSaavn]` prefix
2. Look for `✓` (success) or `✗` (error) indicators
3. Check error type after `Error: `
4. Verify fallback decision in `MusicSourceManager` logs
5. Check final results in `MusicProvider.Search complete` log
