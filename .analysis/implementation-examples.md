# QR Code Implementation Examples for Asset Tracking

This document provides ready-to-use code examples for three different QR code approaches, specifically tailored for asset tracking use cases.

## Use Case: Asset Label with QR Code

**Requirement:** Generate a QR code for each asset that links to the asset record, and print it as a PDF label.

---

## Approach 1: External API (Recommended - Simplest) ⭐

### Complete Implementation

**Location:** Already in your repo at `/Script Includes/Generate QR Code and attach to RITM/script.js`

### Script Include: GenerateAssetQRCode

```javascript
var GenerateAssetQRCode = Class.create();
GenerateAssetQRCode.prototype = {
    initialize: function() {
    },

    // Generate QR code and attach to asset
    generateAndAttach: function(assetSysId, assetTag) {
        try {
            // Get asset record
            var asset = new GlideRecord('alm_asset');
            if (!asset.get(assetSysId)) {
                gs.error('Asset not found: ' + assetSysId);
                return false;
            }

            // Build asset URL
            var instanceURL = gs.getProperty('glide.servlet.uri');
            var assetURL = instanceURL + '/nav_to.do?uri=alm_asset.do?sys_id=' + assetSysId;

            // Generate QR code via external API
            var baseURL = "https://api.qrserver.com/v1/create-qr-code/";
            var qrParams = "?data=" + encodeURIComponent(assetURL) + "&size=300x300&format=png";
            var requestUrl = encodeURI(baseURL + qrParams);

            // Make REST call
            var request = new sn_ws.RESTMessageV2();
            request.setHttpMethod('get');
            request.setEndpoint(requestUrl);
            request.setRequestHeader("Content-Type", "image/png");

            // Save as attachment
            var fileName = (assetTag || asset.asset_tag || 'Asset') + '_QRCode.png';
            request.saveResponseBodyAsAttachment("alm_asset", assetSysId, fileName);
            var response = request.execute();

            if (response.getStatusCode() == 200) {
                gs.info('QR code generated successfully for asset: ' + assetTag);
                return true;
            } else {
                gs.error('QR code generation failed. Status: ' + response.getStatusCode());
                return false;
            }

        } catch (e) {
            gs.error('Error generating QR code: ' + e.message);
            return false;
        }
    },

    // Generate QR code and create PDF label
    generatePDFLabel: function(assetSysId) {
        try {
            // Get asset record
            var asset = new GlideRecord('alm_asset');
            if (!asset.get(assetSysId)) {
                gs.error('Asset not found: ' + assetSysId);
                return false;
            }

            var assetTag = asset.getValue('asset_tag');
            var assetName = asset.getValue('display_name');
            var serialNumber = asset.getValue('serial_number');

            // Build asset URL
            var instanceURL = gs.getProperty('glide.servlet.uri');
            var assetURL = instanceURL + '/nav_to.do?uri=alm_asset.do?sys_id=' + assetSysId;

            // Generate QR code via external API (as base64 embedded image)
            var baseURL = "https://api.qrserver.com/v1/create-qr-code/";
            var qrParams = "?data=" + encodeURIComponent(assetURL) + "&size=300x300&format=png";
            var qrImageURL = encodeURI(baseURL + qrParams);

            // Create HTML for PDF
            var html = this._generateLabelHTML(assetTag, assetName, serialNumber, qrImageURL);

            // Generate PDF using ServiceNow's PDF API
            var pdfAPI = new sn_pdfgeneratorutils.PDFGenerationAPI();
            var headerFooterInfo = {
                "GeneratePageNumber": "false",
                "LeftOrRightMargin": "10",
                "PageOrientation": "PORTRAIT",
                "PageSize": "A4",
                "TopOrBottomMargin": "10"
            };

            var result = pdfAPI.convertToPDFWithHeaderFooter(
                html,
                'alm_asset',
                assetSysId,
                assetTag + '_Label',
                headerFooterInfo
            );

            if (result && result.attachment_id) {
                gs.info('PDF label generated successfully for asset: ' + assetTag);
                return result.attachment_id;
            } else {
                gs.error('PDF generation failed for asset: ' + assetTag);
                return false;
            }

        } catch (e) {
            gs.error('Error generating PDF label: ' + e.message);
            return false;
        }
    },

    _generateLabelHTML: function(assetTag, assetName, serialNumber, qrImageURL) {
        var html = '';
        html += '<!DOCTYPE html>';
        html += '<html>';
        html += '<head>';
        html += '<style>';
        html += 'body { font-family: Arial, sans-serif; padding: 20px; }';
        html += '.label { border: 2px solid #000; padding: 20px; max-width: 400px; }';
        html += '.header { text-align: center; margin-bottom: 20px; }';
        html += '.qr-code { text-align: center; margin: 20px 0; }';
        html += '.info { margin-top: 20px; }';
        html += '.info-row { margin: 10px 0; }';
        html += '.label-key { font-weight: bold; display: inline-block; width: 120px; }';
        html += '</style>';
        html += '</head>';
        html += '<body>';
        html += '<div class="label">';
        html += '<div class="header">';
        html += '<h1 style="margin: 0;">ASSET LABEL</h1>';
        html += '</div>';
        html += '<div class="qr-code">';
        html += '<img src="' + qrImageURL + '" alt="QR Code" width="300" height="300" />';
        html += '</div>';
        html += '<div class="info">';
        html += '<div class="info-row">';
        html += '<span class="label-key">Asset Tag:</span>';
        html += '<span>' + (assetTag || 'N/A') + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="label-key">Asset Name:</span>';
        html += '<span>' + (assetName || 'N/A') + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="label-key">Serial Number:</span>';
        html += '<span>' + (serialNumber || 'N/A') + '</span>';
        html += '</div>';
        html += '</div>';
        html += '</div>';
        html += '</body>';
        html += '</html>';
        return html;
    },

    type: 'GenerateAssetQRCode'
};
```

### Usage Examples

**Generate and attach QR code image:**
```javascript
var qrGen = new GenerateAssetQRCode();
qrGen.generateAndAttach('ASSET_SYS_ID_HERE', 'ASSET-001');
```

**Generate PDF label:**
```javascript
var qrGen = new GenerateAssetQRCode();
var attachmentId = qrGen.generatePDFLabel('ASSET_SYS_ID_HERE');
gs.info('PDF attachment ID: ' + attachmentId);
```

**Business Rule - Auto-generate on Asset Creation:**
```javascript
(function executeRule(current, previous) {
    // Only run on insert
    if (!current.isNewRecord()) {
        return;
    }

    // Generate QR code in background
    var qrGen = new GenerateAssetQRCode();
    qrGen.generateAndAttach(current.sys_id.toString(), current.asset_tag.toString());

})(current, previous);
```

### Pros
- ✅ Very simple (no dependencies)
- ✅ Works immediately
- ✅ Already in your repository
- ✅ Auto-generates proper PNG images
- ✅ Easy to embed in PDFs

### Cons
- ⚠️ Requires external network access
- ⚠️ Dependent on qrserver.com availability
- ⚠️ Data leaves your instance

---

## Approach 2: qrcodejs Library (Client-Side)

**Location:** Already in your repo at `/Service Portal Widgets/Generate QrCode/`

### Service Portal Widget Implementation

**Widget HTML Template:**
```html
<div class="asset-qr-widget">
  <div class="panel panel-default">
    <div class="panel-heading">
      <h3 class="panel-title">Asset QR Code</h3>
    </div>
    <div class="panel-body">
      <div class="asset-info">
        <p><strong>Asset Tag:</strong> {{c.data.assetTag}}</p>
        <p><strong>Name:</strong> {{c.data.assetName}}</p>
        <p><strong>Serial:</strong> {{c.data.serialNumber}}</p>
      </div>
      <div class="qr-container">
        <div id="qrcode-{{c.widget_id}}"></div>
      </div>
      <div class="actions">
        <button class="btn btn-primary" ng-click="c.downloadQR()">Download QR Code</button>
      </div>
    </div>
  </div>
</div>
```

**Widget CSS:**
```css
.asset-qr-widget .asset-info {
  margin-bottom: 20px;
}

.asset-qr-widget .qr-container {
  text-align: center;
  padding: 20px;
  background: #f5f5f5;
  border-radius: 4px;
}

.asset-qr-widget .actions {
  margin-top: 20px;
  text-align: center;
}
```

**Widget Server Script:**
```javascript
(function() {
    // Get asset sys_id from URL parameter or widget option
    var assetSysId = $sp.getParameter('asset_id') || options.asset_id;

    if (assetSysId) {
        var asset = new GlideRecord('alm_asset');
        if (asset.get(assetSysId)) {
            var instanceURL = gs.getProperty('glide.servlet.uri');
            var assetURL = instanceURL + '/nav_to.do?uri=alm_asset.do?sys_id=' + assetSysId;

            data.assetSysId = assetSysId;
            data.assetTag = asset.getValue('asset_tag');
            data.assetName = asset.getValue('display_name');
            data.serialNumber = asset.getValue('serial_number');
            data.assetURL = assetURL;
        }
    }
})();
```

**Widget Client Script:**
```javascript
api.controller = function($scope, $element) {
    var c = this;

    c.$onInit = function() {
        // Wait for DOM to be ready
        setTimeout(function() {
            c.generateQRCode();
        }, 100);
    };

    c.generateQRCode = function() {
        if (!c.data.assetURL) {
            console.error('No asset URL available');
            return;
        }

        var qrElement = document.getElementById('qrcode-' + c.widget_id);
        if (!qrElement) {
            console.error('QR code container not found');
            return;
        }

        // Clear existing QR code
        qrElement.innerHTML = '';

        // Generate QR code
        new QRCode(qrElement, {
            text: c.data.assetURL,
            width: 256,
            height: 256,
            colorDark: "#000000",
            colorLight: "#ffffff",
            correctLevel: QRCode.CorrectLevel.H
        });
    };

    c.downloadQR = function() {
        // Find the generated image
        var qrCanvas = $element.find('#qrcode-' + c.widget_id + ' canvas')[0];
        if (!qrCanvas) {
            console.error('QR code canvas not found');
            return;
        }

        // Convert canvas to blob and download
        qrCanvas.toBlob(function(blob) {
            var url = URL.createObjectURL(blob);
            var link = document.createElement('a');
            link.download = (c.data.assetTag || 'asset') + '_qrcode.png';
            link.href = url;
            link.click();
            URL.revokeObjectURL(url);
        });
    };
};
```

**Widget Dependencies:**
- qrcode.min.js (from davidshimjs/qrcodejs)

### UI Page Implementation

```html
<?xml version="1.0" encoding="utf-8" ?>
<j:jelly trim="false" xmlns:j="jelly:core" xmlns:g="glide" xmlns:j2="null" xmlns:g2="null">
    <g:ui_page>
        <div style="padding: 20px;">
            <h2>Asset QR Code Generator</h2>

            <div id="asset-info" style="margin: 20px 0;">
                <p><strong>Asset Tag:</strong> <span id="asset-tag"></span></p>
                <p><strong>Name:</strong> <span id="asset-name"></span></p>
            </div>

            <div id="qrcode" style="margin: 20px 0;"></div>

            <button onclick="downloadQRCode()" class="btn btn-primary">Download QR Code</button>
        </div>

        <script src="qrcode.min.js"></script>
        <script>
            (function() {
                // Get asset sys_id from URL parameter
                var assetSysId = getUrlParameter('asset_id');
                if (!assetSysId) {
                    alert('No asset ID provided');
                    return;
                }

                // Get asset details via GlideAjax
                var ga = new GlideAjax('AssetQRCodeAjax');
                ga.addParam('sysparm_name', 'getAssetDetails');
                ga.addParam('sysparm_asset_id', assetSysId);
                ga.getXML(function(response) {
                    var answer = response.responseXML.documentElement.getAttribute("answer");
                    var asset = JSON.parse(answer);

                    // Display asset info
                    document.getElementById('asset-tag').textContent = asset.assetTag;
                    document.getElementById('asset-name').textContent = asset.assetName;

                    // Generate QR code
                    new QRCode(document.getElementById("qrcode"), {
                        text: asset.assetURL,
                        width: 300,
                        height: 300,
                        colorDark: "#000000",
                        colorLight: "#ffffff",
                        correctLevel: QRCode.CorrectLevel.H
                    });
                });

                function getUrlParameter(name) {
                    name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
                    var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
                    var results = regex.exec(location.search);
                    return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
                }

                window.downloadQRCode = function() {
                    var canvas = document.querySelector('#qrcode canvas');
                    if (!canvas) return;

                    canvas.toBlob(function(blob) {
                        var url = URL.createObjectURL(blob);
                        var link = document.createElement('a');
                        link.download = asset.assetTag + '_qrcode.png';
                        link.href = url;
                        link.click();
                        URL.revokeObjectURL(url);
                    });
                };
            })();
        </script>
    </g:ui_page>
</j:jelly>
```

**Supporting Script Include (AssetQRCodeAjax):**
```javascript
var AssetQRCodeAjax = Class.create();
AssetQRCodeAjax.prototype = Object.extendsObject(AbstractAjaxProcessor, {

    getAssetDetails: function() {
        var assetSysId = this.getParameter('sysparm_asset_id');
        var asset = new GlideRecord('alm_asset');

        if (asset.get(assetSysId)) {
            var instanceURL = gs.getProperty('glide.servlet.uri');
            var assetURL = instanceURL + '/nav_to.do?uri=alm_asset.do?sys_id=' + assetSysId;

            var result = {
                assetTag: asset.getValue('asset_tag'),
                assetName: asset.getValue('display_name'),
                serialNumber: asset.getValue('serial_number'),
                assetURL: assetURL
            };

            return JSON.stringify(result);
        }

        return JSON.stringify({});
    },

    type: 'AssetQRCodeAjax'
});
```

### Pros
- ✅ Simple integration
- ✅ Already in your repository
- ✅ Generates actual image (canvas)
- ✅ Can download as PNG
- ✅ Works in portals and UI pages

### Cons
- ❌ Client-side only
- ❌ Cannot use in background jobs
- ❌ More complex to include in PDFs
- ⚠️ Requires browser rendering

---

## Approach 3: DevTools Implementation (Server-Side, Complex)

**Note:** Only use if you cannot use external APIs and need server-side generation.

### Prerequisites

1. Install DevTools app, OR
2. Follow extraction guide in `extraction-guide.md`

### Script Include: DevToolsAssetQRCode

```javascript
var DevToolsAssetQRCode = Class.create();
DevToolsAssetQRCode.prototype = {
    initialize: function() {
    },

    // Generate QR code HTML and create PDF label
    generatePDFLabel: function(assetSysId) {
        try {
            // Get asset record
            var asset = new GlideRecord('alm_asset');
            if (!asset.get(assetSysId)) {
                gs.error('Asset not found: ' + assetSysId);
                return false;
            }

            var assetTag = asset.getValue('asset_tag');
            var assetName = asset.getValue('display_name');
            var serialNumber = asset.getValue('serial_number');

            // Build asset URL
            var instanceURL = gs.getProperty('glide.servlet.uri');
            var assetURL = instanceURL + '/nav_to.do?uri=alm_asset.do?sys_id=' + assetSysId;

            // Generate QR code as HTML using DevTools
            // Note: Use x_snc_devtools.HtmlRenderQRCode if DevTools is installed
            var qrHTML = x_snc_devtools.HtmlRenderQRCode(assetURL, 10, 'cm');

            // Create label HTML
            var labelHTML = this._generateLabelHTML(assetTag, assetName, serialNumber, qrHTML);

            // Generate PDF using DevTools
            var attachmentId = x_snc_devtools.CreatePDFFromHtml(
                'alm_asset',
                assetSysId,
                assetTag + '_Label.pdf',
                labelHTML,
                'A4',
                'PORTRAIT',
                10,
                10,
                false
            );

            if (attachmentId) {
                gs.info('PDF label generated successfully for asset: ' + assetTag);
                return attachmentId;
            } else {
                gs.error('PDF generation failed for asset: ' + assetTag);
                return false;
            }

        } catch (e) {
            gs.error('Error generating PDF label: ' + e.message);
            return false;
        }
    },

    _generateLabelHTML: function(assetTag, assetName, serialNumber, qrHTML) {
        var html = '';
        html += '<!DOCTYPE html>';
        html += '<html>';
        html += '<head>';
        html += '<style>';
        html += 'body { font-family: Arial, sans-serif; padding: 20px; }';
        html += '.label { border: 2px solid #000; padding: 20px; max-width: 500px; }';
        html += '.header { text-align: center; margin-bottom: 20px; }';
        html += '.qr-code { text-align: center; margin: 20px 0; }';
        html += '.info { margin-top: 20px; }';
        html += '.info-row { margin: 10px 0; }';
        html += '.label-key { font-weight: bold; display: inline-block; width: 120px; }';
        html += '</style>';
        html += '</head>';
        html += '<body>';
        html += '<div class="label">';
        html += '<div class="header">';
        html += '<h1 style="margin: 0;">ASSET LABEL</h1>';
        html += '</div>';
        html += '<div class="qr-code">';
        html += qrHTML; // Insert QR code HTML
        html += '</div>';
        html += '<div class="info">';
        html += '<div class="info-row">';
        html += '<span class="label-key">Asset Tag:</span>';
        html += '<span>' + (assetTag || 'N/A') + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="label-key">Asset Name:</span>';
        html += '<span>' + (assetName || 'N/A') + '</span>';
        html += '</div>';
        html += '<div class="info-row">';
        html += '<span class="label-key">Serial Number:</span>';
        html += '<span>' + (serialNumber || 'N/A') + '</span>';
        html += '</div>';
        html += '</div>';
        html += '</div>';
        html += '</body>';
        html += '</html>';
        return html;
    },

    type: 'DevToolsAssetQRCode'
};
```

### Usage

```javascript
var qrGen = new DevToolsAssetQRCode();
var attachmentId = qrGen.generatePDFLabel('ASSET_SYS_ID_HERE');
```

### Pros
- ✅ Fully server-side
- ✅ No external dependencies
- ✅ Self-contained
- ✅ Can use in background jobs

### Cons
- ❌ Very complex (15+ Script Includes)
- ❌ Large code footprint (~50KB)
- ❌ High maintenance
- ❌ Renders as HTML table (not true image)
- ❌ Not in your repository (requires installation)

---

## Comparison Summary

| Feature | External API | qrcodejs | DevTools |
|---------|-------------|----------|----------|
| **Lines of Code** | ~100 | ~150 | ~50,000+ |
| **Dependencies** | 0 | 1 library | 15+ includes |
| **Setup Time** | 5 minutes | 10 minutes | 2+ hours |
| **Server-Side** | ✅ Yes | ❌ No | ✅ Yes |
| **Client-Side** | ❌ No | ✅ Yes | ❌ No |
| **PDF Generation** | ✅ Easy | ⚠️ Complex | ✅ Built-in |
| **Already in Repo** | ✅ Yes | ✅ Yes | ❌ No |
| **Network Required** | ✅ Yes | ❌ No | ❌ No |
| **Output Format** | PNG Image | Canvas/Image | HTML Table |
| **Best For** | PDF labels | Portals/UI | Full control |

---

## Recommended Implementation for Asset Tracking

### Complete Solution: Hybrid Approach

Use **External API** for server-side PDF generation + **qrcodejs** for portal display:

#### 1. Server-Side Script Include (for PDF labels)
Use the External API implementation from Approach 1

#### 2. Service Portal Widget (for asset viewing)
Use the qrcodejs implementation from Approach 2

#### 3. Business Rule (auto-generate on creation)

```javascript
(function executeRule(current, previous) {
    // Only run on insert
    if (!current.isNewRecord()) {
        return;
    }

    // Skip if no asset tag
    if (!current.asset_tag) {
        return;
    }

    // Generate QR code PDF label
    var qrGen = new GenerateAssetQRCode();
    var success = qrGen.generatePDFLabel(current.sys_id.toString());

    if (success) {
        gs.addInfoMessage('Asset QR code label generated successfully');
    } else {
        gs.addErrorMessage('Failed to generate asset QR code label');
    }

})(current, previous);
```

#### 4. UI Action (manual generation)

```javascript
// UI Action for manual QR code generation
generateQRCodeLabel();

function generateQRCodeLabel() {
    var assetSysId = current.sys_id.toString();
    var qrGen = new GenerateAssetQRCode();

    var attachmentId = qrGen.generatePDFLabel(assetSysId);

    if (attachmentId) {
        gsftSubmit(null, g_form.getFormElement(), 'sysverb_update');
        alert('QR code label generated successfully!');
    } else {
        alert('Failed to generate QR code label. Please check logs.');
    }
}
```

---

## Testing Checklist

### External API Approach
- [ ] Test with valid asset record
- [ ] Verify QR code image attached
- [ ] Test QR code scanning with mobile device
- [ ] Verify PDF label generation
- [ ] Test with special characters in asset data
- [ ] Check error handling for network failures

### qrcodejs Approach
- [ ] Test widget in Service Portal
- [ ] Verify QR code renders correctly
- [ ] Test download functionality
- [ ] Test with different screen sizes
- [ ] Verify QR code scans correctly
- [ ] Test with long URLs

### DevTools Approach
- [ ] Verify all dependencies installed
- [ ] Test QR code HTML generation
- [ ] Test PDF creation
- [ ] Verify attachment to record
- [ ] Test with various QR code sizes
- [ ] Check performance with large batches

---

## Conclusion

**For most asset tracking scenarios, use:**

1. **External API** for server-side PDF generation (Approach 1)
2. **qrcodejs** for client-side display (Approach 2)

Only use DevTools (Approach 3) if:
- External network access is completely prohibited
- You need absolute control over QR generation
- You're already using other DevTools features

Both recommended approaches are **already in your repository** and ready to use!
