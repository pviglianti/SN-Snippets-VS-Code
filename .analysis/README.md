# DevTools QR Code Analysis

This directory contains the analysis and source code extracted from the ServiceNow DevTools repository for QR code generation functionality.

## Contents

### Analysis Document
- **devtools-qr-analysis.md** - Comprehensive analysis of the QR code implementation, including:
  - Detailed explanation of each function
  - Complete dependency chain
  - Comparison with existing solutions in this repo
  - Recommendations for asset tracking use case
  - Source code examples

### Source Code (devtools-source-code/)
- **CreateQRCodeRawData.xml** (49KB) - Core QR code generation using Project Nayuki's library
- **HtmlRenderQRCode.xml** (2.1KB) - Renders QR code as HTML table
- **ImageAPI.xml** (7.5KB) - Image rendering and manipulation class
- **CreatePDFFromHtml.xml** (2.9KB) - PDF generation and attachment
- **UtilityFunctions.xml** (11KB) - Collection of utility functions:
  - GetIntegerValue()
  - GetValue()
  - Clone()
  - BindAllFunctionsToThis()
  - RenderValueHex()

## Quick Summary

### Three Approaches Available

1. **External API (Recommended for Server-Side)** ⭐
   - Location: `/Script Includes/Generate QR Code and attach to RITM/`
   - Pros: Simplest (10 lines), no dependencies
   - Cons: Requires network access

2. **qrcodejs Library (Recommended for Client-Side)** ⭐
   - Location: `/Service Portal Widgets/Generate QrCode/`
   - Pros: Lightweight, client-side rendering
   - Cons: Cannot be used server-side

3. **DevTools Implementation (Complex)**
   - Requires: 15+ Script Includes
   - Size: ~50KB total
   - Pros: Fully self-contained, server-side
   - Cons: Complex dependency chain

## Recommendation

For asset tracking with label printing:
- Use **External API** for server-side QR generation and PDF attachment
- Use **qrcodejs** for portal/UI display
- Only use **DevTools** if external network access is prohibited

See `devtools-qr-analysis.md` for detailed analysis and code examples.

## License

- **DevTools Code:** Part of ServiceNow DevTools (public repository)
- **QR Generator:** MIT License (Project Nayuki)
- **Analysis:** Created for this repository

## Source

All source code extracted from: https://github.com/saschawildgrube/servicenow-devtools
Analysis performed: 2025-12-25
