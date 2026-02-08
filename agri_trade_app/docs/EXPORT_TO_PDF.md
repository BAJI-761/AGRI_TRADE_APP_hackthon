# Exporting the Report to PDF (Windows)

## Option A: VS Code Extension
1. Open `docs/AgriTradeApp_Report.md` in VS Code.
2. Install an extension like "Markdown PDF".
3. Right-click in the editor → "Markdown PDF: Export (pdf)".

## Option B: Pandoc (Recommended for Academic Formatting)
1. Install Pandoc: `https://pandoc.org/installing.html`.
2. Install a LaTeX engine (e.g., MiKTeX): `https://miktex.org/download`.
3. Open PowerShell in `agri_trade_app/docs`.
4. Basic export:
   ```powershell
   pandoc -s AgriTradeApp_Report.md -o AgriTradeApp_Report.pdf
   ```
5. With table of contents and nicer typography:
   ```powershell
   pandoc AgriTradeApp_Report.md -o AgriTradeApp_Report.pdf ^
     --toc --pdf-engine=xelatex ^
     -V mainfont="Calibri" -V monofont="Consolas" -V geometry:margin=1in
   ```

Tip: Replace author/title placeholders at the top of the report before exporting.

