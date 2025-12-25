# DevTools QR Code Extraction Guide

If you decide to use the DevTools QR code implementation without installing the full DevTools app, follow this guide.

## ⚠️ Warning

This extraction is **complex** and requires significant effort. Consider these alternatives first:

1. **Install full DevTools app** (recommended if using DevTools)
2. **Use External API approach** (already in your repo - simplest)
3. **Use qrcodejs library** (already in your repo - best for UI)

## Prerequisites

- ServiceNow instance with admin access
- Understanding of Script Includes
- Patience for managing dependencies

## Files Needed

All source files are available in: `/home/user/SN-Snippets-VS-Code/.analysis/devtools-source-code/`

### Core Files (Minimum Required)

1. **CreateQRCodeRawData.xml** (49KB)
   - API Name: `CreateQRCodeRawData`
   - Contains: Project Nayuki QR generator library
   - Dependency: GetStringValue()

2. **HtmlRenderQRCode.xml** (2.1KB)
   - API Name: `HtmlRenderQRCode`
   - Dependencies: CreateQRCodeRawData, ImageAPI, GetStringValue

3. **ImageAPI.xml** (7.5KB)
   - API Name: `ImageAPI`
   - Dependencies: GetIntegerValue, GetStringValue, BindAllFunctionsToThis, Clone, GetValue, RenderValueHex

4. **UtilityFunctions.xml** (11KB)
   - Contains 5 utility functions:
     - GetIntegerValue
     - GetValue
     - Clone
     - BindAllFunctionsToThis
     - RenderValueHex

### Additional Functions Needed

You'll need to create these additional utility functions:

```javascript
// GetType - Returns the type of a value
function GetType(vValue) {
    if (vValue === undefined) return 'undefined';
    if (vValue === null) return 'null';
    if (typeof vValue === 'string') return 'string';
    if (typeof vValue === 'number') return 'number';
    if (typeof vValue === 'boolean') return 'boolean';
    if (Array.isArray(vValue)) return 'Array';
    if (vValue.getTableName) return 'ScopedGlideRecord';
    if (vValue.getValue) return 'ScopedGlideElement';
    if (typeof vValue === 'object') return 'Object';
    return 'unknown';
}

// IsArray - Check if value is an array
function IsArray(vValue) {
    return Array.isArray(vValue);
}

// IsObject - Check if value is an object
function IsObject(vValue) {
    return typeof vValue === 'object' && vValue !== null && !Array.isArray(vValue);
}

// GetKeys - Get object keys
function GetKeys(vValue) {
    if (!IsObject(vValue)) return [];
    return Object.keys(vValue);
}

// GetBoolValue - Convert value to boolean
function GetBoolValue(vValue) {
    if (vValue === true || vValue === 'true' || vValue === 1 || vValue === '1') {
        return true;
    }
    return false;
}

// GetFunctions - Get function names from an object
function GetFunctions(vValue) {
    if (!IsObject(vValue)) return [];
    var functions = [];
    for (var key in vValue) {
        if (typeof vValue[key] === 'function') {
            functions.push(key);
        }
    }
    return functions;
}
```

### For PDF Generation (Optional)

If you need PDF generation:

5. **CreatePDFFromHtml.xml** (2.9KB)
   - API Name: `CreatePDFFromHtml`
   - Dependencies: GetStringValue, GetValue, IsValidTable, IsValidSysId
   - External: `sn_pdfgeneratorutils.PDFGenerationAPI` (ServiceNow built-in)

Additional utilities needed:

```javascript
// IsValidTable - Check if table exists
function IsValidTable(strTable) {
    if (!strTable) return false;
    var gr = new GlideRecord(strTable);
    return gr.isValid();
}

// IsValidSysId - Check if valid sys_id
function IsValidSysId(strSysId) {
    if (!strSysId) return false;
    var pattern = /^[0-9a-f]{32}$/i;
    return pattern.test(strSysId);
}
```

## Installation Steps

### Step 1: Create Script Includes

For each utility function listed above:

1. Navigate to **System Definition > Script Includes**
2. Click **New**
3. Fill in:
   - **Name:** Function name (e.g., "GetStringValue")
   - **API Name:** `x_your_scope.FunctionName` or just `FunctionName` for global
   - **Client callable:** false
   - **Script:** Paste the function code
4. Click **Submit**

### Step 2: Import XML Files

1. Navigate to **System Update Sets > Retrieved Update Sets**
2. Click **Import Update Set from XML**
3. Choose each XML file from `.analysis/devtools-source-code/`
4. Preview and commit each update set

**Note:** You may need to manually edit the XML files to:
- Change the scope (remove `x_snc_devtools` prefix or change to your scope)
- Remove sys_id references
- Update dependencies

### Step 3: Test

```javascript
// Test QR Code generation
var testUrl = "https://example.com/test";
var qrHtml = HtmlRenderQRCode(testUrl, 10, 'cm');
gs.info("QR Code HTML: " + qrHtml);

// Test with PDF
var html = '<html><body><h1>Test QR Code</h1>' + qrHtml + '</body></html>';
var attachmentId = CreatePDFFromHtml(
    'incident',
    'YOUR_INCIDENT_SYS_ID',
    'test_qr.pdf',
    html,
    'A4',
    'PORTRAIT',
    0,
    0,
    false
);
gs.info("Attachment ID: " + attachmentId);
```

## Dependency Resolution Order

Create Script Includes in this order to avoid dependency errors:

1. GetType
2. IsArray
3. IsObject
4. GetKeys
5. GetBoolValue
6. GetFunctions
7. GetStringValue
8. GetIntegerValue
9. GetValue (depends on: IsArray, GetType, GetStringValue)
10. RenderValueHex (depends on: GetStringValue, GetType)
11. Clone (depends on: GetType, GetBoolValue, IsObject, IsArray, GetKeys)
12. BindAllFunctionsToThis (depends on: GetType, GetFunctions)
13. ImageAPI (depends on: all above)
14. CreateQRCodeRawData (depends on: GetStringValue)
15. HtmlRenderQRCode (depends on: GetStringValue, CreateQRCodeRawData, ImageAPI)
16. IsValidTable (for PDF)
17. IsValidSysId (for PDF)
18. CreatePDFFromHtml (depends on: GetStringValue, GetValue, IsValidTable, IsValidSysId)

## Alternative: Simplified Extraction

If you only need QR code generation without the HTML rendering:

### Minimal Setup (Just QR Data)

1. Create **GetStringValue** Script Include
2. Import **CreateQRCodeRawData.xml**
3. Use it directly:

```javascript
var qrData = CreateQRCodeRawData("https://example.com");
// qrData is a 2D array of booleans
// You'll need to render it yourself (e.g., using canvas, or create simple HTML)
```

### Simple HTML Renderer (Without ImageAPI)

```javascript
function SimpleRenderQRCode(strPayload) {
    var aRawData = CreateQRCodeRawData(strPayload);
    var size = aRawData.length;
    var pixelSize = 10; // pixels

    var html = '<div style="display: inline-block; padding: 20px; background: white;">';
    html += '<div style="font-size: 0; line-height: 0;">';

    for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
            var color = aRawData[y][x] ? '#000000' : '#ffffff';
            html += '<div style="display: inline-block; width: ' + pixelSize + 'px; ';
            html += 'height: ' + pixelSize + 'px; background: ' + color + ';"></div>';
        }
        html += '<br>';
    }

    html += '</div></div>';
    return html;
}
```

This approach:
- ✅ Only needs 2 Script Includes (GetStringValue + CreateQRCodeRawData)
- ✅ Much simpler
- ✅ Still generates valid QR codes
- ⚠️ Less configurable than full ImageAPI

## Maintenance Considerations

If you extract these functions:

1. **Updates:** You'll need to manually update from DevTools repo
2. **Testing:** Test thoroughly - dependency issues are common
3. **Documentation:** Document which version you extracted from
4. **Support:** No official support - you're on your own

## Still Too Complex?

### Recommendation: Use Simpler Alternatives

#### For Server-Side (PDF/Attachments)
Use the **External API** approach:

```javascript
var assetURL = "https://instance.service-now.com/nav_to.do?uri=alm_asset.do?sys_id=" + assetSysId;
var baseURL = "https://api.qrserver.com/v1/create-qr-code/";
var requestUrl = encodeURI(baseURL + "?data=" + encodeURIComponent(assetURL) + "&size=300x300");

var request = new sn_ws.RESTMessageV2();
request.setHttpMethod('get');
request.setEndpoint(requestUrl);
request.saveResponseBodyAsAttachment("alm_asset", assetSysId, "QR_Code");
request.execute();
```

**Benefits:**
- 7 lines of code
- No dependencies
- Works immediately
- Already in your repo at: `/Script Includes/Generate QR Code and attach to RITM/`

#### For Client-Side (Portal/UI)
Use the **qrcodejs** library:

```javascript
// Already in your repo at: /Service Portal Widgets/Generate QrCode/
new QRCode(document.getElementById("qrcode"), assetURL);
```

**Benefits:**
- Simple integration
- Lightweight
- Well-maintained

## Conclusion

**Before extracting DevTools functions, ask yourself:**

1. Can I use the External API approach? (Simplest)
2. Can I use qrcodejs for client-side? (Best for UI)
3. Can I install the full DevTools app? (Easiest if using DevTools)
4. Do I really need server-side without external dependencies? (Only then extract)

The extraction process is provided for completeness, but **simpler alternatives are strongly recommended** unless you have specific requirements that necessitate the DevTools approach.

## Support

- **DevTools Repository:** https://github.com/saschawildgrube/servicenow-devtools
- **DevTools Documentation:** https://www.wildgrube.com/servicenow-devtools/
- **Community Forums:** ServiceNow Community

## License

All DevTools code is provided under its original license. The QR code generator library (Project Nayuki) is MIT licensed.
