#!/usr/bin/env python3
"""Simple Markdown to one-page PDF converter.
Usage: python scripts/mkpdf.py EMERGENCY-PROTOCOL.md EMERGENCY-PROTOCOL.pdf

This script strips basic Markdown headings and writes wrapped text into a PDF using reportlab.
"""
import sys
import textwrap
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch


def markdown_to_plain(lines):
    out = []
    for ln in lines:
        ln = ln.rstrip('\n')
        # Remove leading '#', '##', etc.
        if ln.startswith('#'):
            ln = ln.lstrip('#').strip()
            out.append(ln.upper())
            out.append('')
            continue
        # Remove leading list markers
        if ln.lstrip().startswith('- '):
            ln = '• ' + ln.lstrip()[2:]
        out.append(ln)
    return out


def write_pdf(text_lines, out_path):
    c = canvas.Canvas(out_path, pagesize=letter)
    width, height = letter
    left = inch * 0.75
    right_margin = inch * 0.75
    max_width = width - left - right_margin
    y = height - inch * 0.75
    line_height = 12
    wrapper = textwrap.TextWrapper(width=90)

    for ln in text_lines:
        if ln == '':
            y -= line_height
            continue
        wrapped = wrapper.wrap(ln)
        for w in wrapped:
            if y < inch:
                c.showPage()
                y = height - inch * 0.75
            c.setFont('Helvetica', 10)
            c.drawString(left, y, w)
            y -= line_height
    c.save()


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: mkpdf.py input.md output.pdf')
        sys.exit(1)
    in_path = sys.argv[1]
    out_path = sys.argv[2]
    with open(in_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    txt = markdown_to_plain(lines)
    write_pdf(txt, out_path)
    print('Wrote', out_path)
