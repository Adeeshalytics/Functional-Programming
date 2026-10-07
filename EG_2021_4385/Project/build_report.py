"""Build REPORT.md into an A4 PDF. Optional regeneration dependency: reportlab.
Run python3 Project/build_report.py from the submission folder.
"""
from pathlib import Path
import html
import re

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, PageBreak, Preformatted, Table, TableStyle,
)

ROOT = Path(__file__).resolve().parent
FONT_ROOT = Path('/usr/share/fonts/truetype/dejavu')
for name, filename in [('Body', 'DejaVuSans.ttf'), ('BodyBold', 'DejaVuSans-Bold.ttf'),
                       ('Code', 'DejaVuSansMono.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(FONT_ROOT / filename)))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='BodyBold', italic='Body', boldItalic='BodyBold')

styles = {
    'body': ParagraphStyle('body', fontName='Body', fontSize=10, leading=13.5, spaceAfter=7, alignment=TA_LEFT),
    'title': ParagraphStyle('title', fontName='BodyBold', fontSize=17, leading=21, spaceAfter=9),
    'h2': ParagraphStyle('h2', fontName='BodyBold', fontSize=12, leading=16, spaceBefore=4, spaceAfter=8),
    'h3': ParagraphStyle('h3', fontName='BodyBold', fontSize=10, leading=14, spaceBefore=5, spaceAfter=7),
    'table': ParagraphStyle('table', fontName='Body', fontSize=8.5, leading=11.5),
    'code': ParagraphStyle('code', fontName='Code', fontSize=7.5, leading=10, spaceBefore=4, spaceAfter=8),
}


def inline(text):
    text = html.escape(text)
    text = re.sub(r'`([^`]+)`', r'<font name="Code">\1</font>', text)
    return re.sub(r'\*\*([^*]+)\*\*', r'<b>\1</b>', text)


def table(lines):
    rows = []
    for line in lines:
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if all(re.fullmatch(r'[-: ]+', c) for c in cells):
            continue
        rows.append([Paragraph(inline(c), styles['table']) for c in cells])
    cols = len(rows[0])
    width = A4[0] - 84
    if cols == 2:
        widths = [width * .22, width * .78]
    else:
        widths = [width * .44, width * .28, width * .28]
    result = Table(rows, colWidths=widths, repeatRows=1, hAlign='LEFT')
    result.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#e7edf5')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f7f9fc')]),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), .3, colors.HexColor('#ccd4de')),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    return result


def story_from_markdown(text):
    lines = text.splitlines()
    story = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line == '<!-- pagebreak -->':
            story.append(PageBreak()); i += 1
        elif line.startswith('```'):
            code = []; i += 1
            while i < len(lines) and not lines[i].startswith('```'):
                code.append(lines[i]); i += 1
            story.append(Preformatted('\n'.join(code), styles['code'])); i += 1
        elif line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                rows.append(lines[i]); i += 1
            story.extend([table(rows), Spacer(1, 8)])
        elif line.startswith('#'):
            level = len(line) - len(line.lstrip('#'))
            style = 'title' if level == 1 else 'h2' if level == 2 else 'h3'
            story.append(Paragraph(inline(line.lstrip('#').strip()), styles[style])); i += 1
        elif line.startswith('- '):
            story.append(Paragraph(inline(line[2:]), styles['body'], bulletText='•')); i += 1
        else:
            paragraph = [line]; i += 1
            while i < len(lines) and lines[i].strip() and not lines[i].startswith(('#', '|', '```', '- ', '<!--')):
                paragraph.append(lines[i].strip()); i += 1
            story.append(Paragraph(inline(' '.join(paragraph)), styles['body']))
    return story


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor('#ccd4de'))
    canvas.line(42, 35, A4[0]-42, 35)
    canvas.setFont('Body', 8)
    canvas.drawString(42, 23, 'Adeesha M.G.P • EG/2021/4385 • EC8206')
    canvas.drawRightString(A4[0]-42, 23, str(doc.page))
    canvas.restoreState()


if __name__ == '__main__':
    output = ROOT / 'Project_Report.pdf'
    doc = SimpleDocTemplate(str(output), pagesize=A4, rightMargin=42, leftMargin=42,
                            topMargin=38, bottomMargin=47,
                            title='EC8206 Project Report — Adeesha M.G.P — EG/2021/4385',
                            author='Adeesha M.G.P')
    doc.build(story_from_markdown((ROOT/'REPORT.md').read_text()),
              onFirstPage=footer, onLaterPages=footer)
    print(output)
