# ServiceNow DevTools QR Code Implementation Analysis

## Executive Summary

The ServiceNow DevTools QR code implementation uses an **embedded QR code generation library** (Project Nayuki's QR Code Generator) with a complex dependency chain. For asset tracking use cases, **there are simpler alternatives** already available in your repository that may be more suitable.

## Three QR Code Generation Approaches Found

### 1. DevTools Approach (Server-Side, Complex)
**Source:** https://github.com/saschawildgrube/servicenow-devtools

**Pros:**
- Fully server-side (no client dependencies)
- Can generate QR codes in background jobs
- Can embed in PDFs and attach to records
- MIT Licensed (Project Nayuki)

**Cons:**
- Complex dependency chain (10+ utility functions)
- Large code footprint (~49KB just for QR generation)
- Requires entire DevTools app or manual extraction
- HTML table rendering (not actual image generation)

### 2. qrcodejs Library (Client-Side, Simple) ⭐ RECOMMENDED
**Already in your repo:** `/home/user/SN-Snippets-VS-Code/Service Portal Widgets/Generate QrCode/`

**Pros:**
- Simple, lightweight implementation
- Well-maintained library (davidshimjs/qrcodejs)
- Works in Service Portal, UI Pages, Client Scripts
- Already integrated in your repository
- Generates canvas/image elements directly

**Cons:**
- Client-side only
- Cannot be used in server-side scripts or background jobs
- Requires browser rendering

### 3. External API (Server-Side, Simplest)
**Already in your repo:** `/home/user/SN-Snippets-VS-Code/Script Includes/Generate QR Code and attach to RITM/`

**Pros:**
- Extremely simple (5 lines of code)
- Server-side compatible
- Can attach directly to records
- No maintenance required

**Cons:**
- Requires external network access
- Dependent on third-party service (qrserver.com)
- May have rate limits or availability issues
- Data leaves your instance

---

## DevTools Implementation Deep Dive

### Core Functions

#### 1. CreateQRCodeRawData()
**File:** `sys_script_include_23927b79dbdecd10bcced03cd3961919.xml`
**Size:** ~49KB
**API:** `x_snc_devtools.CreateQRCodeRawData(strPayload)`

**What it does:**
- Embeds the entire Project Nayuki QR Code Generator library (compiled from TypeScript)
- Generates a 2D array of boolean values representing QR code pixels
- Returns: `[[true, false, ...], [false, true, ...], ...]`

**License:** MIT (Project Nayuki)

**Key Code:**
```javascript
function CreateQRCodeRawData(strPayload)
{
    strPayload = GetStringValue(strPayload);

    // ... ~48KB of embedded QR code generation library ...

    var qr = qrcodegen.QrCode.encodeText(
        strPayload,
        qrcodegen.QrCode.Ecc.MEDIUM
    );

    var aResult = [];
    for (var nRow = 0; nRow < qr.size; nRow++) {
        var aRow = [];
        for (var nCol = 0; nCol < qr.size; nCol++) {
            aRow.push(qr.getModule(nCol, nRow));
        }
        aResult.push(aRow);
    }
    return aResult;
}
```

**Dependencies:**
- GetStringValue()

---

#### 2. HtmlRenderQRCode()
**File:** `sys_script_include_ee4a4c02db520150bcced03cd396196f.xml`
**API:** `x_snc_devtools.HtmlRenderQRCode(strPayload, nWidth, strUnit)`

**What it does:**
- Takes a payload string and renders it as an HTML table
- Each cell in the table represents one pixel (black or white)
- Returns HTML string for display or PDF generation

**Key Code:**
```javascript
function HtmlRenderQRCode(strPayload, nWidth, strUnit)
{
    strPayload = GetStringValue(strPayload);
    if (strPayload == '') {
        return '';
    }

    var aRawData = CreateQRCodeRawData(strPayload);

    var image = new ImageAPI(aRawData.length, aRawData.length);

    for (var nRow = 0; nRow < aRawData.length; nRow++) {
        for (var nCol = 0; nCol < aRawData[nRow].length; nCol++) {
            var bValue = aRawData[nRow][nCol];
            if (bValue == true) {
                image.SetPixel(nCol, nRow, image.ColorBlack());
            } else {
                image.SetPixel(nCol, nRow, image.ColorWhite());
            }
        }
    }

    return image.HtmlRenderImage(nWidth, strUnit);
}
```

**Dependencies:**
- GetStringValue()
- CreateQRCodeRawData()
- ImageAPI class

---

#### 3. ImageAPI Class
**File:** `sys_script_include_96e6f60adb5a0150bcced03cd39619e4.xml`
**API:** `new x_snc_devtools.ImageAPI(width, height)`

**What it does:**
- Creates a bitmap image representation
- Can render as HTML table or BMP file
- Supports basic color operations

**Key Methods:**
- `SetPixel(x, y, color)` - Set pixel color
- `GetPixel(x, y)` - Get pixel color
- `HtmlRenderImage(width, unit)` - Render as HTML table
- `CreateBitmapFile()` - Generate BMP file data

**HTML Rendering Logic:**
```javascript
HtmlRenderImage: function(nWidth, strUnit) {
    nWidth = GetIntegerValue(nWidth);
    if (nWidth <= 0) { nWidth = 10; }

    strUnit = GetStringValue(strUnit);
    if (strUnit == '') { strUnit = 'cm'; }

    var nPixelEdge = nWidth / this.bitmap.length;

    var strHtml = '';
    strHtml += '<div style="padding-top: 10px; padding-bottom: 10px;">';
    strHtml += '<table style="width: '+nWidth+strUnit+'; border: 0px; border-collapse: collapse;">';
    strHtml += '<tbody>';

    for (var nRow = 0; nRow < this.bitmap.length; nRow++) {
        strHtml += '<tr>';
        var aRow = this.bitmap[nRow];
        for (var nCol = 0; nCol < aRow.length; nCol++) {
            var strColor = this.GetPixelHex(nCol, nRow);
            strHtml += '<td style="border: 0px; width: ' + nPixelEdge + strUnit + ';';
            strHtml += ' height: ' + nPixelEdge + strUnit + ';';
            strHtml += ' background-color: #'+ strColor + ';"/>';
        }
        strHtml += '</tr>';
    }

    strHtml += '</tbody></table></div>';
    return strHtml;
}
```

**Dependencies:**
- GetIntegerValue()
- GetStringValue()
- BindAllFunctionsToThis()
- Clone()
- GetValue()
- RenderValueHex()

---

#### 4. CreatePDFFromHtml()
**File:** `sys_script_include_b326ce43db5a8950b652edb3059619f7.xml`
**API:** `x_snc_devtools.CreatePDFFromHtml(strTable, strRecordSysId, strFileName, strHtml, strPageSize, strOrientation, nMarginTopBottom, nMarginLeftRight, bPageNumbers)`

**What it does:**
- Converts HTML to PDF using ServiceNow's built-in PDF generator
- Attaches the PDF to a specified record
- Returns the attachment sys_id

**Key Code:**
```javascript
function CreatePDFFromHtml(strTable, strRecordSysId, strFileName, strHtml,
                          strPageSize, strOrientation, nMarginTopBottom,
                          nMarginLeftRight, bPageNumbers)
{
    strTable = GetStringValue(strTable);
    strRecordSysId = GetStringValue(strRecordSysId);
    strFileName = GetStringValue(strFileName);
    strHtml = GetStringValue(strHtml);

    if (!IsValidTable(strTable) || !IsValidSysId(strRecordSysId)) {
        return false;
    }

    if (strPageSize == '') { strPageSize = 'A4'; }
    if (strOrientation == '') { strOrientation = 'PORTRAIT'; }

    var pdfapi = new sn_pdfgeneratorutils.PDFGenerationAPI();

    var headerFooterInfo = {
        "GeneratePageNumber": "false",
        "LeftOrRightMargin": "0",
        "PageOrientation": strOrientation,
        "PageSize": strPageSize,
        "TopOrBottomMargin": "0"
    };

    var result = pdfapi.convertToPDFWithHeaderFooter(
        strHtml,
        strTable,
        strRecordSysId,
        strFileName.substring(0, strFileName.length-4),
        headerFooterInfo
    );

    var strAttachmentSysId = GetValue(result, 'attachment_id');

    if (IsValidSysId(strAttachmentSysId)) {
        return strAttachmentSysId;
    }

    return false;
}
```

**External Dependency:**
- **sn_pdfgeneratorutils.PDFGenerationAPI** (ServiceNow built-in)

**Dependencies:**
- GetStringValue()
- GetValue()
- IsValidTable()
- IsValidSysId()

---

### Complete Dependency Chain

```
HtmlRenderQRCode()
├── GetStringValue()
├── CreateQRCodeRawData()
│   └── GetStringValue()
│   └── [Embedded: Project Nayuki QR Library - ~48KB]
└── ImageAPI class
    ├── GetIntegerValue()
    ├── GetStringValue()
    ├── BindAllFunctionsToThis()
    │   ├── GetType()
    │   └── GetFunctions()
    ├── Clone()
    │   ├── GetType()
    │   ├── GetBoolValue()
    │   ├── IsObject()
    │   ├── IsArray()
    │   └── GetKeys()
    ├── GetValue()
    │   ├── IsArray()
    │   ├── GetType()
    │   └── GetStringValue() [recursive]
    └── RenderValueHex()
        └── GetStringValue()

CreatePDFFromHtml()
├── GetStringValue()
├── GetValue()
├── IsValidTable()
├── IsValidSysId()
└── sn_pdfgeneratorutils.PDFGenerationAPI (ServiceNow built-in)
```

**Total Functions Required:** 15+ utility functions
**Total Code Size:** ~50KB+ (mostly the QR library)

---

## Utility Functions Reference

### GetStringValue()
```javascript
function GetStringValue(vInput) {
    if (vInput == undefined) { return ''; }
    if (vInput == null) { return ''; }
    return ''+vInput;
}
```

### GetIntegerValue()
```javascript
function GetIntegerValue(vValue) {
    if (vValue === true) { return 1; }
    var vResult = parseInt(vValue);
    if (isNaN(vResult)) { return 0; }
    return vResult;
}
```

### GetValue()
```javascript
function GetValue(vObject, vKey1, vKey2, ...) {
    // Safe nested property access
    // Handles arrays, objects, GlideRecords
    // Returns null if property doesn't exist
}
```

### RenderValueHex()
```javascript
function RenderValueHex(vValue, strByteSeparator) {
    // Converts numbers/arrays to hexadecimal string
    // Used for color representation
}
```

### Clone()
```javascript
function Clone(vValue, bSortKeys) {
    // Deep clone of objects/arrays
    // Handles GlideRecords and GlideElements
}
```

### BindAllFunctionsToThis()
```javascript
function BindAllFunctionsToThis(vValue) {
    // Binds all object methods to the object context
    // Fixes JavaScript "this" context issues
}
```

---

## Recommended Approach for Asset Tracking

### For Server-Side QR Generation + PDF

**Option A: Use External API (Simplest)**
```javascript
// Already in your repo!
var assetTag = "ASSET-12345";
var assetURL = "https://yourinstance.service-now.com/nav_to.do?uri=alm_asset.do?sys_id=" + assetSysId;

var baseURL = "https://api.qrserver.com/v1/create-qr-code/";
var qrData = "?data=" + encodeURIComponent(assetURL) + "&size=300x300";

var requestUrl = encodeURI(baseURL + qrData);
var request = new sn_ws.RESTMessageV2();
request.setHttpMethod('get');
request.setEndpoint(requestUrl);
request.setRequestHeader("Content-Type", "image/png");
request.saveResponseBodyAsAttachment("alm_asset", assetSysId, assetTag + "_QR");
var response = request.execute();
```

**Pros:**
- Only 10 lines of code
- No dependencies
- Works immediately

**Cons:**
- Requires external network access
- Third-party dependency

---

**Option B: Use DevTools (Most Complex)**

If you need fully server-side without external dependencies:

1. **Install entire DevTools app** (easiest)
   - Download from: https://github.com/saschawildgrube/servicenow-devtools
   - Import the update set
   - Use: `x_snc_devtools.HtmlRenderQRCode(url, 10, 'cm')`

2. **Extract only QR code functions** (complex)
   - Copy 15+ Script Includes
   - Manage dependency chain
   - Keep code updated manually

**Usage Example:**
```javascript
// Generate QR code HTML
var assetURL = "https://yourinstance.service-now.com/nav_to.do?uri=alm_asset.do?sys_id=" + assetSysId;
var qrHtml = x_snc_devtools.HtmlRenderQRCode(assetURL, 10, 'cm');

// Create PDF with QR code
var fullHtml = '<html><body><h1>Asset: ' + assetTag + '</h1>' + qrHtml + '</body></html>';
var attachmentId = x_snc_devtools.CreatePDFFromHtml(
    'alm_asset',
    assetSysId,
    assetTag + '_QR.pdf',
    fullHtml,
    'A4',
    'PORTRAIT',
    0,
    0,
    false
);
```

---

### For Client-Side QR Generation (Service Portal, UI Pages)

**Option C: Use qrcodejs Library (Recommended)** ⭐
```javascript
// Already in your repo!
// Client Controller (Service Portal Widget)
var qrCodeInstance = new QRCode(document.getElementById("qrcode"), {
    text: "https://yourinstance.service-now.com/nav_to.do?uri=alm_asset.do?sys_id=12345",
    width: 256,
    height: 256,
    colorDark: "#000000",
    colorLight: "#ffffff",
    correctLevel: QRCode.CorrectLevel.H
});
```

**HTML Template:**
```html
<div id="qrcode"></div>
```

**Pros:**
- Simple and lightweight
- Already in your repository
- Well-maintained library
- Generates actual image (canvas/img)

---

## Comparison Matrix

| Feature | External API | DevTools | qrcodejs |
|---------|-------------|----------|----------|
| **Complexity** | Very Low | Very High | Low |
| **Code Size** | ~10 lines | ~50KB+ | ~30KB library |
| **Dependencies** | None | 15+ functions | 1 library file |
| **Server-Side** | ✅ Yes | ✅ Yes | ❌ No |
| **Client-Side** | ❌ No | ❌ No | ✅ Yes |
| **PDF Generation** | ✅ Easy | ✅ Built-in | ⚠️ Complex |
| **Network Required** | ✅ Yes | ❌ No | ❌ No |
| **Maintenance** | None | High | Low |
| **Already in Repo** | ✅ Yes | ❌ No | ✅ Yes |
| **Best For** | Quick server-side | Full control | UI/Portal |

---

## Recommendation for Asset Tracking

### Recommended Solution: Hybrid Approach

1. **For Label Printing (PDF generation):**
   - Use **External API** approach (simplest, already in your repo)
   - Generate QR code image via API
   - Attach to asset record
   - Include in PDF labels using HTML/CSS

2. **For Portal/UI Display:**
   - Use **qrcodejs** library (already in your repo)
   - Display QR codes in Service Portal widgets
   - Show on asset form views

3. **Only if external network access is prohibited:**
   - Consider installing full DevTools app
   - Or implement a simpler server-side solution using ServiceNow's GlideImage API

---

## Alternative: Simplified Server-Side Implementation

If you need server-side without DevTools or external API:

**Use ServiceNow's built-in GlideImage (if available):**
```javascript
// Note: GlideImage may have limitations
var img = new GlideImage();
// ... check ServiceNow documentation for QR code support
```

**Or create a minimal implementation:**
- Extract only CreateQRCodeRawData function (49KB file)
- Create simplified utility functions
- Skip ImageAPI complexity
- Use ServiceNow's PDF generator directly

---

## Files to Extract from DevTools (If Needed)

If you choose to extract DevTools functions, you need these files:

### Core QR Functions
1. `sys_script_include_23927b79dbdecd10bcced03cd3961919.xml` - CreateQRCodeRawData
2. `sys_script_include_ee4a4c02db520150bcced03cd396196f.xml` - HtmlRenderQRCode
3. `sys_script_include_96e6f60adb5a0150bcced03cd39619e4.xml` - ImageAPI

### Utility Functions
4. `sys_script_include_400f9d3e1b901010a89720a8ec4bcb83.xml` - GetStringValue
5. `sys_script_include_6583795e1b2c1c10a89720a8ec4bcb1f.xml` - GetIntegerValue
6. `sys_script_include_8efbd16fdb6b4010ba15a35305961998.xml` - GetValue
7. `sys_script_include_b5e8a386db1e0150bcced03cd396193a.xml` - RenderValueHex
8. `sys_script_include_9b8b6813dba26c10ba15a35305961983.xml` - Clone
9. `sys_script_include_a645a8ec97332510a6a07767f053afb2.xml` - BindAllFunctionsToThis

### Additional Dependencies
10. GetType()
11. IsArray()
12. IsObject()
13. GetKeys()
14. GetBoolValue()
15. GetFunctions()

### PDF Generation (Optional)
16. `sys_script_include_b326ce43db5a8950b652edb3059619f7.xml` - CreatePDFFromHtml
17. IsValidTable()
18. IsValidSysId()

**Total: ~18 Script Includes**

---

## Conclusion

**For your asset tracking use case, I recommend:**

1. **Start with the External API approach** - It's already in your repo, simple, and works immediately
2. **Use qrcodejs for portal/UI needs** - Also already in your repo
3. **Only use DevTools if:**
   - You cannot access external APIs
   - You need the full DevTools functionality
   - You're willing to install the entire app

**Trade-offs:**
- **External API:** Simplest but requires network access
- **qrcodejs:** Best for client-side, can't generate PDFs server-side
- **DevTools:** Most complex but fully self-contained

The DevTools implementation is powerful but **overkill for basic QR code generation**. The embedded Project Nayuki library is excellent but adds significant complexity through the ImageAPI and utility function dependencies.

---

## Sources

- [ServiceNow DevTools Repository](https://github.com/saschawildgrube/servicenow-devtools)
- [DevTools Script Include - HtmlRenderQRCode](https://github.com/saschawildgrube/servicenow-devtools/blob/master/update/sys_script_include_ee4a4c02db520150bcced03cd396196f.xml)
- [QR Code Generator Community Post](https://www.servicenow.com/community/servicenow-ai-platform-articles/qr-code-code-generator-servicenow/ta-p/2323234)
- [Project Nayuki QR Code Generator](https://www.nayuki.io/page/qr-code-generator-library)
- [qrcodejs Library](https://github.com/davidshimjs/qrcodejs)
