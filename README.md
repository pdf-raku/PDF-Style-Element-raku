p6-PDF-Compose
==============

Experimental CSS driven PDF rendering backend.

Initial version likely to have:
- support for core fonts only
- basic image rendering, hopefully
- support for a small subset of available css 2.1 properties
- some ability to import base template pdf pages

CSS Property todo list:
- background-attachment: does the brackground scroll?
- background
  - background-color
  - background-position
  - background-repeat
- border (or border-top, border-left, border-right, border-bottom)
  - border-color (or border-top-color etc)
  - border-spacing (or border-top-spacing, etc)
  - border-style (or border-top-style etc)
  - bottom, top, left, right
- clip
- font-family
- font-style
- font-weight
- height, max-height, min-height
- width, max-width, minw-width
- letter-spacing
- line-height
- margin, margin-left, margin-right, margin-top, margin-bottom
- padding, padding-top, padding-left, padding-right, padding-bottom
- text-align
- text-decoration
- text-indent
- text-transform
- word-spacing

CSS Property Shortlist
- content
- direction
- display
- font-variant
- empty-cells
- float
- list-style, list-style-image, list-style-position, list-style-type
- outline, outline-width, outline-style, outline-color
- page-break-before, page-break-after, page-break-inside
- overflow
- unicode-bidi
- table-layout
- visibility
- white-spacing
